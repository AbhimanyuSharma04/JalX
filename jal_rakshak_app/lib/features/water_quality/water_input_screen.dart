

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../core/services/prediction_service.dart';
import '../../core/widgets/glass_card.dart';
import 'widgets/sensor_card.dart';
import 'widgets/parameter_modal.dart';
import '../../features/readings/data/readings_repository.dart';
import '../../features/readings/domain/reading_model.dart';
import 'services/tflite_service.dart';
import '../dashboard/sensor_repository.dart';
import 'services/auto_fetch_service.dart';

class WaterQualityInputScreen extends ConsumerStatefulWidget {
  const WaterQualityInputScreen({super.key});

  @override
  ConsumerState<WaterQualityInputScreen> createState() => _WaterQualityInputScreenState();
}

class _WaterQualityInputScreenState extends ConsumerState<WaterQualityInputScreen> {
  // Form State
  double _ph = 7.3;
  double _contaminantLevel = 60.64;
  double _turbidity = 0.62;
  double _temperature = 7.49;
  double _uvIndex = 1.47;
  double _conductivity = 110.75;
  double _dissolvedOxygen = 3.62;
  
  String _waterSource = 'River';
  String _rgbSensor = 'Red';

  bool _isAnalyzing = false;
  bool _isFetching = false;
  String _predictionLabel = ''; // Empty initially
  double _confidence = 0.0;
  double _riskScore = 0.0; // 0-100 for gauge

  Future<void> _fetchBatchData() async {
    setState(() => _isFetching = true);
    final tfliteService = ref.read(tfliteServiceProvider);
    final sensorRepo = ref.read(sensorRepositoryProvider);
    
    tfliteService.clearBuffer();

    // Fetch 5 times from Firebase to fill buffer
    for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(seconds: 1)); // Wait 1s between fetches
        if (!mounted) return;

        final data = await sensorRepo.fetchCurrentData();
        
        if (data.containsKey('error')) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error fetching data: ${data['error']}'))
           );
           break; // Stop fetching on error
        }

        setState(() {
          _ph = (data['ph'] as num).toDouble();
          _turbidity = (data['turbidity'] as num).toDouble();
          _temperature = (data['temperature'] as num).toDouble();
          _contaminantLevel = (data['tds'] as num).toDouble(); // TDS mapped to Contamination
          _conductivity = (data['conductivity'] as num).toDouble();
          _dissolvedOxygen = (data['do'] as num).toDouble();
          _uvIndex = (data['uv'] as num).toDouble();
        });

        tfliteService.addReading(
          doVal: _dissolvedOxygen,
          cond: _conductivity,
          temp: _temperature,
          turb: _turbidity,
          ph: _ph,
        );
    }
    
    setState(() => _isFetching = false);
    
    if (tfliteService.readingCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fetched 5 readings from device. Ready to analyze.', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.success,
        )
      );
    }
  }

  String _getSensorKey(String title) {
    switch (title) {
      case 'pH Level': return 'PH';
      case 'Turbidity': return 'TURB';
      case 'Temperature': return 'TEMP';
      case 'Conductivity': return 'COND';
      case 'Dissolved Oxygen': return 'DO';
      default: return '';
    }
  }

  void _submitData() async {
    setState(() => _isAnalyzing = true);
    
    final tfliteService = ref.read(tfliteServiceProvider);

    // 1. Add current reading to buffer
    tfliteService.addReading(
      doVal: _dissolvedOxygen,
      cond: _conductivity,
      temp: _temperature,
      turb: _turbidity,
      ph: _ph,
    );

    try {
      // 2. Run offline prediction
      final result = await tfliteService.predict();
      
      if (mounted) {
        setState(() {
          final status = result['status'] as String;
          
          if (status == 'Calibrating...') {
            final count = result['buffer_count'] ?? 0;
            final remaining = 5 - (count as int);
            _predictionLabel = 'Calibrating...';
            _confidence = 0.0;
            _riskScore = 50.0; // Neutral
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Calibrating... Need $remaining more reading(s).', style: GoogleFonts.inter()),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (status == 'Error') {
             _predictionLabel = 'Error';
             _riskScore = 0.0;
              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Prediction Error. Check logs.', style: GoogleFonts.inter()),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
             _predictionLabel = result['risk_level'];
             _confidence = (result['confidence'] as num).toDouble();
             // Update gauge score based on prediction probability
             // Probability 0.0 -> Score 0 (Safe)
             // Probability 1.0 -> Score 100 (Unsafe)
             final prob = result['probability'] as double;
             _riskScore = prob * 100;
             
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Analysis Complete: $_predictionLabel', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                backgroundColor: _predictionLabel == 'Low' ? AppTheme.success : (_predictionLabel == 'Moderate' ? AppTheme.warning : AppTheme.error),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _saveData() async {
    if (_predictionLabel.isEmpty || _predictionLabel == 'Unknown') {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please analyze water quality before saving.', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.warning,
        )
      );
      return;
    }

    final reading = Reading(
      id: 0, // 0 for auto-increment/mock
      deviceName: 'Manual Entry', // Or derive from logged in user if available
      timestamp: DateTime.now().toIso8601String(),
      status: _predictionLabel,
      source: _waterSource,
      ph: _ph,
      turbidity: _turbidity,
      contaminants: _contaminantLevel,
      temperature: _temperature,
      conductivity: _conductivity,
      dissolvedOxygen: _dissolvedOxygen,
      predictionModel: _predictionLabel, // Using label as model result for now
      confidence: _confidence,
      uvIndex: _uvIndex,
      rgbSensor: _rgbSensor,
    );

    try {
      await ref.read(readingsRepositoryProvider).saveReading(reading);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reading saved successfully!', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  void _showParameterDialog(String title, double value, double min, double max, String unit, Function(double) onChanged) {
    final sensorKey = _getSensorKey(title);
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: ParameterInputModal(
          title: title,
          sensorKey: sensorKey, // New
          value: value,
          // history: history, // Removed
          onAdd: () {
             _addManualPoint();
             // Navigator.pop(context); // Removed: Keep modal open for multiple entries
          },
          min: min,
          max: max,
          unit: unit,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'JAL-X', 
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.2,
            color: Colors.white,
          )
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1E293B),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                radius: 18,
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'about':
                  context.push('/about-us');
                  break;
                case 'logout':
                  await Supabase.instance.client.auth.signOut();
                  // Router will handle redirect
                  break;
                case 'switch_account':
                  await Supabase.instance.client.auth.signOut();
                  // Router will handle redirect
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  'Welcome, ${Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? Supabase.instance.client.auth.currentUser?.email ?? 'User'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 12),
                    Text('About Us', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem<String>(
                value: 'switch_account',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Switch Account', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: null,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputGrid(),
                const SizedBox(height: 32),
                _buildPredictionSection(),
                const SizedBox(height: 32),
                _buildAutoFetchScheduleSection(),
                const SizedBox(height: 100), // Bottom padding for nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputGrid() {
    return Column(
      children: [
        // Row 1: Water Source (Full Width)
        _buildDropdownCard('Water Source Type', _waterSource, ['River', 'Lake', 'Well', 'Tap', 'Rainwater'], (v) {
           setState(() => _waterSource = v!);
           // Clear buffer when source changes
           ref.read(tfliteServiceProvider).clearBuffer();
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Buffer cleared for new source', style: GoogleFonts.inter()))
           );
        }),
        const SizedBox(height: 16),
        
        // Grid for Sensors
        /*
          Layout:
          Row 1: pH, TDS
          Row 2: Turbidity, Temp
          Row 3: RGB (Dropdown - Full Width or with another?) -> Let's keep RGB full or split. 
          The previous layout had RGB full width. Let's keep it consistent but styling improved.
          Row 4: UV, Conductivity
          Row 5: DO
        */
        
        Row(
          children: [
            Expanded(child: SensorCard(
              title: 'pH Level',
              value: _ph.toStringAsFixed(1),
              unit: 'pH',
              numericValue: _ph,
              min: 0, max: 14,
              onTap: () => _showParameterDialog('pH Level', _ph, 0, 14, 'pH', (v) => setState(() => _ph = v)),
              onClear: () {
                setState(() => _ph = 7.0);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('pH reset to 7.0', style: GoogleFonts.inter()), duration: const Duration(seconds: 1)));
              },
            )),
            const SizedBox(width: 16),
            Expanded(child: SensorCard(
              title: 'Contamination',
              value: _contaminantLevel.toStringAsFixed(0),
              unit: 'ppm',
              numericValue: _contaminantLevel,
              min: 0, max: 1000,
              onTap: () => _showParameterDialog('Contamination', _contaminantLevel, 0, 1000, 'ppm', (v) => setState(() => _contaminantLevel = v)),
              onClear: () {
                setState(() => _contaminantLevel = 0.0);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contamination reset to 0', style: GoogleFonts.inter()), duration: const Duration(seconds: 1)));
              },
            )),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
             Expanded(child: SensorCard(
              title: 'Turbidity',
              value: _turbidity.toStringAsFixed(2),
              unit: 'NTU',
              numericValue: _turbidity,
              min: 0, max: 1000,
              onTap: () => _showParameterDialog('Turbidity', _turbidity, 0, 1000, 'NTU', (v) => setState(() => _turbidity = v)),
              onClear: () {
                setState(() => _turbidity = 0.0);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Turbidity reset to 0.0', style: GoogleFonts.inter()), duration: const Duration(seconds: 1)));
              },
            )),
             const SizedBox(width: 16),
             Expanded(child: SensorCard(
              title: 'Temperature',
              value: _temperature.toStringAsFixed(1),
              unit: '°C',
              numericValue: _temperature,
              min: 0, max: 100,
              onTap: () => _showParameterDialog('Temperature', _temperature, 0, 100, '°C', (v) => setState(() => _temperature = v)),
              onClear: () {
                setState(() => _temperature = 0.0);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Temperature reset to 0.0', style: GoogleFonts.inter()), duration: const Duration(seconds: 1)));
              },
            )),
          ],
        ),
        const SizedBox(height: 16),

        // RGB Sensor
        _buildDropdownCard('RGB Sensor', _rgbSensor, ['Red', 'Green', 'Blue'], (v) => setState(() => _rgbSensor = v!)),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: SensorCard(
              title: 'UV Sensor',
              value: _uvIndex.toStringAsFixed(2),
              unit: 'Index',
              numericValue: _uvIndex,
              min: 0, max: 15,
              onTap: () => _showParameterDialog('UV Sensor', _uvIndex, 0, 15, 'Index', (v) => setState(() => _uvIndex = v)),
              onClear: () {
                setState(() => _uvIndex = 0.0);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('UV Sensor reset to 0.0', style: GoogleFonts.inter()), duration: const Duration(seconds: 1)));
              },
            )),
            const SizedBox(width: 16),
            Expanded(child: SensorCard(
              title: 'Conductivity',
              value: _conductivity.toStringAsFixed(0),
              unit: 'µS/cm',
              numericValue: _conductivity,
              min: 0, max: 2000,
              onTap: () => _showParameterDialog('Conductivity', _conductivity, 0, 2000, 'µS/cm', (v) => setState(() => _conductivity = v)),
              onClear: () {
                setState(() => _conductivity = 0.0);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conductivity reset to 0', style: GoogleFonts.inter()), duration: const Duration(seconds: 1)));
              },
            )),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
             Expanded(child: SensorCard(
              title: 'Dissolved Oxygen',
              value: _dissolvedOxygen.toStringAsFixed(2),
              unit: 'mg/L',
              numericValue: _dissolvedOxygen,
              min: 0, max: 20,
              onTap: () => _showParameterDialog('Dissolved Oxygen', _dissolvedOxygen, 0, 20, 'mg/L', (v) => setState(() => _dissolvedOxygen = v)),
              onClear: () {
                setState(() => _dissolvedOxygen = 0.0);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dissolved Oxygen reset to 0.0', style: GoogleFonts.inter()), duration: const Duration(seconds: 1)));
              },
            )),
             const SizedBox(width: 16),
             // Placeholder for symmetry or future sensor
             const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildPredictionSection() {
    // Determine state here to avoid logic inside children list
    final readingCount = ref.watch(tfliteServiceProvider).readingCount;
    final isReadyToAnalyze = readingCount >= 5;

    return GlassCard(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Model Prediction', 
            style: GoogleFonts.inter(
              color: Colors.white, 
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            )
          ),
          // Enhanced Gauge - Show only if prediction available
          AnimatedSize(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutBack,
            child: _predictionLabel.isEmpty ? const SizedBox.shrink() : Column(
              children: [
                const SizedBox(height: 30),
                SizedBox(
                  height: 220,
                  width: 280,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _riskScore),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: GaugePainter(value, showGauge: _predictionLabel.isNotEmpty),
                        child: child,
                      );
                    },
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 130), // Offset
                           if (_predictionLabel.isNotEmpty) ...[
                            Text(
                              _predictionLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 32, 
                                fontWeight: FontWeight.w800, 
                                color: _getRiskColor(_riskScore),
                                shadows: [
                                  BoxShadow(
                                    color: _getRiskColor(_riskScore).withOpacity(0.5),
                                    blurRadius: 20,
                                  )
                                ]
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Risk Score: ${_riskScore.toStringAsFixed(1)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12, 
                                  color: _getRiskColor(_riskScore), 
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

           // Primary Button (Submit)
           // Disable if analyzing, fetching, or insufficient data

           Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isReadyToAnalyze 
                  ? [const Color(0xFF2DD4BF), const Color(0xFF0F766E)]
                  : [Colors.grey.shade700, Colors.grey.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (isReadyToAnalyze)
                  BoxShadow(
                    color: const Color(0xFF2DD4BF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ElevatedButton(
              onPressed: (_isAnalyzing || _isFetching || !isReadyToAnalyze) ? null : _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isAnalyzing 
                ? const CircularProgressIndicator(color: Colors.white) 
                : Text(
                    isReadyToAnalyze ? 'Analyze Water Quality' : 'Need ${5 - readingCount} more reading(s)', 
                    style: GoogleFonts.inter(
                      color: isReadyToAnalyze ? Colors.white : Colors.white54, 
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    )
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // Secondary Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isFetching ? null : _fetchBatchData,
                  icon: _isFetching 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                    : const Icon(Icons.download, size: 20, color: Colors.white70),
                  label: Text(_isFetching ? 'Fetching...' : 'Fetch Data', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _resetData,
                  icon: const Icon(Icons.refresh, size: 20, color: Color(0xFFEF4444)),
                  label: Text('Reset', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.5)),
                    backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _saveData,
                  icon: const Icon(Icons.bookmark_border, size: 20, color: Color(0xFF2DD4BF)),
                  label: Text('Save', style: GoogleFonts.inter(color: const Color(0xFF2DD4BF), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF2DD4BF).withOpacity(0.5)),
                    backgroundColor: const Color(0xFF2DD4BF).withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoFetchScheduleSection() {
    final autoFetchState = ref.watch(autoFetchServiceProvider);
    final autoFetchService = ref.read(autoFetchServiceProvider.notifier);

    return GlassCard(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Weekly Auto-Fetch Schedule', 
                  style: GoogleFonts.inter(
                    color: Colors.white, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  )
                ),
              ),
              Switch(
                value: autoFetchState.isEnabled,
                onChanged: (val) => autoFetchService.toggleEnabled(val),
                activeColor: AppTheme.success,
              ),
            ],
          ),
          if (autoFetchState.isEnabled) ...[
            const SizedBox(height: 16),
            Text('Select Days', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _buildDayToggle('Mon', 1, autoFetchState, autoFetchService),
                   _buildDayToggle('Tue', 2, autoFetchState, autoFetchService),
                   _buildDayToggle('Wed', 3, autoFetchState, autoFetchService),
                   _buildDayToggle('Thu', 4, autoFetchState, autoFetchService),
                   _buildDayToggle('Fri', 5, autoFetchState, autoFetchService),
                   _buildDayToggle('Sat', 6, autoFetchState, autoFetchService),
                   _buildDayToggle('Sun', 7, autoFetchState, autoFetchService),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time Slots', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            timePickerTheme: TimePickerThemeData(
                              backgroundColor: const Color(0xFF1E293B),
                              hourMinuteTextColor: Colors.white,
                              dayPeriodTextColor: Colors.white,
                              dialBackgroundColor: Colors.black26,
                              dialHandColor: Colors.blueAccent,
                              dialTextColor: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      autoFetchService.addTimeSlot(time);
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            if (autoFetchState.timeSlots.isEmpty)
               Text('No time slots added. Tap + to create an alarm.', style: GoogleFonts.inter(color: Colors.white30, fontSize: 12)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: autoFetchState.timeSlots.map((slot) {
                return Chip(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  labelStyle: GoogleFonts.inter(color: Colors.white),
                  label: Text(slot.format(context)),
                  deleteIconColor: Colors.redAccent,
                  onDeleted: () => autoFetchService.removeTimeSlot(slot),
                  side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                );
              }).toList(),
            ),
          ] else ...[
             const SizedBox(height: 8),
             Text('Enable to automatically schedule sensor reads & analysis.', style: GoogleFonts.inter(color: Colors.white30, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildDayToggle(String label, int dayId, AutoFetchState state, AutoFetchService service) {
    final isSelected = state.selectedDays.contains(dayId);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => service.toggleDay(dayId),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white24, width: 1.5),
            boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 8)] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label, 
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : Colors.white70, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            )
          ),
        ),
      ),
    );
  }

  // Add manually to buffer
  void _addManualPoint() {
     final tfliteService = ref.read(tfliteServiceProvider);
      tfliteService.addReading(
        doVal: _dissolvedOxygen,
        cond: _conductivity,
        temp: _temperature,
        turb: _turbidity,
        ph: _ph,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Point added to buffer (${tfliteService.readingCount}/5)', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 1),
        )
      );
  }

  Widget _buildDropdownCard(String title, String value, List<String> items, Function(String?) onChanged) {
    return GlassCard(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(title, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 12)),
               Container(
                 decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.2), 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
                  ),
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 child: const Text('SAFE', style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold)),
               ),
             ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF0F172A),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(double score) {
    if (score < 33) return const Color(0xFF22C55E); // Green
    if (score < 66) return const Color(0xFFEAB308); // Yellow
    return const Color(0xFFEF4444); // Red
  }

  void _resetData() {
    setState(() {
      _ph = 7.3;
      _contaminantLevel = 60.64;
      _turbidity = 0.62;
      _temperature = 7.49;
      _uvIndex = 1.47;
      _conductivity = 110.75;
      _dissolvedOxygen = 3.62;
      _predictionLabel = '';
      _confidence = 0.0;
      _riskScore = 0.0;
      _isAnalyzing = false;
      _isFetching = false;
    });
    ref.read(tfliteServiceProvider).clearBuffer();
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All data reset.', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.primary,
        )
      );
  }

  // Removed duplicate _showParameterDialog logic here since it's already defined above.
  // The correct definition is at line 236 or similar.
  // If it was missing from the class body, it should be kept, but the error log says "already declared".
  // Looking at the view_file output, it is defined at line 214 and again at 627.
  // I will remove the one at 627.
}

class GaugePainter extends CustomPainter {
  final double score; // 0-100
  final bool showGauge;
  
  GaugePainter(this.score, {this.showGauge = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGauge) return;

    final center = Offset(size.width / 2, size.height / 2 + 20);
    final radius = size.width / 2 - 10;
    
    // Track paint
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.1);

    // Draw Track
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);
    
    // Gradient Paint
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round;

    // Gradient
    final gradient = const SweepGradient(
      startAngle: math.pi,
      endAngle: math.pi * 2,
      colors: [Color(0xFF22C55E), Color(0xFFEAB308), Color(0xFFEF4444)],
      tileMode: TileMode.mirror,
    ).createShader(rect);
    
    paint.shader = gradient;
    
    // Draw Arcs
    // Need to clip or draw partial arc based on score?
    // Usually a gauge shows the whole gradient. 
    canvas.drawArc(rect, math.pi, math.pi, false, paint);

    // Glow Effect
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    glowPaint.shader = gradient;
    canvas.drawArc(rect, math.pi, math.pi, false, glowPaint);

    // Needle
    final angle = math.pi + (score / 100) * math.pi;
    final needleLen = radius - 5;
    final needleEnd = Offset(center.dx + needleLen * math.cos(angle), center.dy + needleLen * math.sin(angle));
    
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Draw shadow for needle
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
    // Pivot
    canvas.drawCircle(center, 12, needlePaint..color = Colors.white);
    canvas.drawCircle(center, 8, Paint()..color = const Color(0xFF0F172A));
    
    // Draw Needle
    canvas.drawLine(center + const Offset(2, 2), needleEnd + const Offset(2, 2), shadowPaint);
    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
