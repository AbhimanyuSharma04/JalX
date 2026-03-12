import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class DiseasePredictionScreen extends StatefulWidget {
  const DiseasePredictionScreen({super.key});

  @override
  State<DiseasePredictionScreen> createState() => _DiseasePredictionScreenState();
}

class _DiseasePredictionScreenState extends State<DiseasePredictionScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedGender = 'Male';
  final List<String> _selectedSymptoms = [];
  bool _isAnalyzing = false;
  List<Map<String, dynamic>>? _analysisResults;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<String> _symptomsList = [
    "Fever", "Vomiting", "Dehydration", "Fatigue", "Jaundice",
    "Rose spots", "Weight loss", "Diarrhea", "Abdominal Pain",
    "Headache", "Nausea", "Dark colored urine", "Bloating"
  ];

  final Map<String, Map<String, dynamic>> _diseaseDatabase = {
    'hepatitisA': {
      'name': 'Hepatitis A',
      'preventions': ['Vaccination', 'Good hygiene', 'Safe drinking water'],
      'keywords': ["Fever", "Fatigue", "Nausea", "Jaundice", "Dark colored urine", "Abdominal Pain", "Vomiting"],
    },
    'cholera': {
      'name': 'Cholera',
      'preventions': ['Drink boiled water', 'Wash hands often', 'Cook food well'],
      'keywords': ["Diarrhea", "Vomiting", "Dehydration", "Nausea"],
    },
    'gastroenteritis': {
      'name': 'Gastroenteritis',
      'preventions': ['Hydration', 'Rest', 'Eat light foods'],
      'keywords': ["Diarrhea", "Vomiting", "Nausea", "Abdominal Pain", "Fever", "Dehydration", "Headache"],
    },
    'typhoid': {
      'name': 'Typhoid',
      'preventions': ['Vaccination', 'Avoid street food', 'Safe water'],
      'keywords': ["Fever", "Headache", "Fatigue", "Abdominal Pain", "Rose spots", "Diarrhea"],
    },
    'giardiasis': {
      'name': 'Giardiasis',
      'preventions': ['Wash fruits/veg', 'Avoid swallowing pool water'],
      'keywords': ["Diarrhea", "Fatigue", "Abdominal Pain", "Nausea", "Dehydration", "Bloating", "Weight loss"],
    },
    'crypto': {
      'name': 'Cryptosporidiosis',
      'preventions': ['Wash hands', 'Avoid untreated water'],
      'keywords': ["Diarrhea", "Dehydration", "Weight loss", "Abdominal Pain", "Fever", "Nausea", "Vomiting"],
    }
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  void _runAIAnalysis() {
    setState(() {
      _isAnalyzing = true;
      _analysisResults = null;
    });

    // Simulate API delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      List<Map<String, dynamic>> scores = [];
      
      _diseaseDatabase.forEach((key, disease) {
        final List<String> keywords = disease['keywords'] as List<String>;
        final matching = keywords.where((k) => _selectedSymptoms.contains(k)).toList();
        
        if (matching.isNotEmpty) {
          final double probability = (matching.length / keywords.length) * 100;
          if (probability > 20) {
            scores.add({
              'name': disease['name'],
              'probability': probability.round(),
              'preventions': disease['preventions'],
            });
          }
        }
      });

      // Sort by probability desc
      scores.sort((a, b) => (b['probability'] as int).compareTo(a['probability'] as int));

      setState(() {
        _isAnalyzing = false;
        _analysisResults = scores.take(3).toList(); // Top 3
      });
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSymptoms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select at least one symptom', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
      _runAIAnalysis();
    }
  }

  IconData _getSymptomIcon(String symptom) {
    switch (symptom) {
      case 'Fever': return Icons.thermostat;
      case 'Vomiting': return Icons.sick;
      case 'Dehydration': return Icons.water_drop_outlined;
      case 'Fatigue': return Icons.battery_1_bar;
      case 'Jaundice': return Icons.visibility;
      case 'Rose spots': return Icons.circle_outlined;
      case 'Weight loss': return Icons.trending_down;
      case 'Diarrhea': return Icons.warning_amber;
      case 'Abdominal Pain': return Icons.healing;
      case 'Headache': return Icons.psychology;
      case 'Nausea': return Icons.sentiment_very_dissatisfied;
      case 'Dark colored urine': return Icons.opacity;
      case 'Bloating': return Icons.expand;
      default: return Icons.medical_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Disease Prediction',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: null,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 28),
                      // Patient Info Card
                      _buildPatientInfoCard(),
                      const SizedBox(height: 24),
                      // Symptoms Card
                      _buildSymptomsCard(),
                      const SizedBox(height: 28),
                      // Submit Button
                      _buildSubmitButton(),
                      const SizedBox(height: 24),
                      // Loading
                      if (_isAnalyzing) _buildLoadingIndicator(),
                      // Results
                      if (_analysisResults != null) ...[
                        const SizedBox(height: 8),
                        _buildResults(),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submit Health Data for',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white60,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFF93C5FD)],
          ).createShader(bounds),
          child: Text(
            'AI Disease Prediction',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Select symptoms and patient data for preliminary analysis.',
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoCard() {
    return GlassCard(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Patient Information',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Full Name
          _buildPremiumTextField('Full Name', _nameController, Icons.badge_outlined),
          const SizedBox(height: 16),
          // Age + Gender Row
          Row(
            children: [
              Expanded(
                child: _buildPremiumTextField('Age', _ageController, Icons.cake_outlined, isNumber: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Location
          _buildPremiumTextField('Location', _locationController, Icons.location_on_outlined),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20),
        filled: false,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.error, width: 1),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedGender,
          dropdownColor: const Color(0xFF0F172A),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white30),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Gender',
            labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            filled: false,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          validator: (value) => value == null ? 'Required' : null,
          items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(
            value: g,
            child: Text(g, style: GoogleFonts.inter(color: Colors.white)),
          )).toList(),
          onChanged: (v) => setState(() => _selectedGender = v!),
        ),
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return GlassCard(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medical_services_outlined, color: AppTheme.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Symptoms Observed',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              if (_selectedSymptoms.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${_selectedSymptoms.length} selected',
                    style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to select symptoms you are experiencing',
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _symptomsList.map((symptom) {
              final isSelected = _selectedSymptoms.contains(symptom);
              return _SymptomChip(
                symptom: symptom,
                icon: _getSymptomIcon(symptom),
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSymptoms.remove(symptom);
                    } else {
                      _selectedSymptoms.add(symptom);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2DD4BF), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2DD4BF).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        child: _isAnalyzing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Submit Data & Get Analysis',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Analyzing Symptoms...',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Our AI is evaluating possible conditions',
              style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_analysisResults!.isEmpty) {
      return GlassCard(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.success.withOpacity(0.6), size: 48),
              const SizedBox(height: 12),
              Text(
                'No significant disease match found',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Based on the selected symptoms',
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics, color: AppTheme.success, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Analysis Results',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ..._analysisResults!.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          final probability = result['probability'] as int;
          final isHigh = probability > 50;
          final color = isHigh ? AppTheme.error : AppTheme.warning;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 150)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(20),
                border: Border.all(color: color.withOpacity(0.25)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            result['name'],
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            '$probability%',
                            style: GoogleFonts.inter(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: probability / 100.0,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recommended Preventions',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (result['preventions'] as List<String>).map((p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          p,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

// Animated Symptom Chip Widget
class _SymptomChip extends StatefulWidget {
  final String symptom;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SymptomChip({
    required this.symptom,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SymptomChip> createState() => _SymptomChipState();
}

class _SymptomChipState extends State<_SymptomChip> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - _scaleController.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primary.withOpacity(0.2)
                : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primary.withOpacity(0.6)
                  : Colors.white.withOpacity(0.08),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isSelected ? AppTheme.primary : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                widget.symptom,
                style: GoogleFonts.inter(
                  color: widget.isSelected ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, size: 14, color: AppTheme.primary.withOpacity(0.8)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
}
