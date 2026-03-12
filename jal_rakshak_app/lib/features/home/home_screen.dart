import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../features/dashboard/sensor_repository.dart';
import '../../features/water_quality/services/tflite_service.dart';
import '../../features/readings/data/readings_repository.dart';
import '../../features/readings/domain/reading_model.dart';
import 'widgets/add_device_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Reading> _recentReadings = [];
  
  @override
  void initState() {
    super.initState();
    _loadRecentReadings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadRecentReadings() async {
    try {
      final repo = ref.read(readingsRepositoryProvider);
      final readings = await repo.getReadings();
      setState(() {
        _recentReadings = readings.take(20).toList().reversed.toList();
      });
    } catch (e) {
      debugPrint('Error loading readings: $e');
    }
  }

  void _showAddDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddDeviceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('JAL-X Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
              child: const CircleAvatar(
                backgroundColor: Colors.grey,
                radius: 18,
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'about':
                  context.push('/about-us');
                  break;
                case 'add_device':
                  _showAddDeviceDialog(context);
                  break;
                case 'community':
                  context.go('/community');
                  break;
                case 'logout':
                  await Supabase.instance.client.auth.signOut();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  'Welcome, ${Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? Supabase.instance.client.auth.currentUser?.email ?? 'User'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
              PopupMenuItem<String>(
                enabled: false,
                child: ExpansionTile(
                  title: const Text('Devices', style: TextStyle(color: Colors.white, fontSize: 14)),
                  leading: const Icon(Icons.devices, color: Colors.greenAccent, size: 20),
                  childrenPadding: EdgeInsets.zero,
                  tilePadding: EdgeInsets.zero,
                  collapsedIconColor: Colors.white54,
                  iconColor: Colors.white,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 16),
                      dense: true,
                      leading: const Icon(Icons.circle, size: 8, color: Colors.green),
                      title: const Text('Device 01', style: TextStyle(color: Colors.white70)),
                      onTap: () {},
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 16),
                      dense: true,
                      leading: const Icon(Icons.add, size: 16, color: Colors.blue),
                      title: const Text('Add Device', style: TextStyle(color: Colors.blue)),
                      onTap: () {
                        Navigator.pop(context);
                        _showAddDeviceDialog(context);
                      },
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'community',
                child: Row(
                  children: [
                    Icon(Icons.groups_rounded, color: Colors.tealAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Community Outreach', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Parameters',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _buildLiveStatsGrid(),
              const SizedBox(height: 24),
              Text(
                'Recent Quality Graph',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _buildHistoryGraph(),
              const SizedBox(height: 24),
              Text(
                'Weekly Contamination Report',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _buildWeeklyReportChart(),
              const SizedBox(height: 24),
              Text(
                'Monthly Contamination Report',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _buildMonthlyReportChart(),
              const SizedBox(height: 24),
              Text(
                'Understanding Parameters',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _buildParameterDefinitions(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // Settings card removed from here

  Widget _buildLiveStatsGrid() {
    final stream = ref.watch(sensorStreamProvider);

    return stream.when(
      data: (data) {
        if (data.containsKey('error')) {
          return Center(child: Text('Error: ${data['error']}', style: const TextStyle(color: Colors.red)));
        }

        final ph = (data['ph'] as num?)?.toDouble() ?? 0.0;
        final turbidity = (data['turbidity'] as num?)?.toDouble() ?? 0.0;
        final temp = (data['temperature'] as num?)?.toDouble() ?? 0.0;
        final tds = (data['tds'] as num?)?.toDouble() ?? 0.0;
        final doVal = (data['do'] as num?)?.toDouble() ?? 0.0;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('pH Level', ph.toStringAsFixed(1), 'pH', _getPhColor(ph)),
            _buildStatCard('Turbidity', turbidity.toStringAsFixed(2), 'NTU', Colors.brown.shade300),
            _buildStatCard('Temperature', temp.toStringAsFixed(1), '°C', Colors.orangeAccent),
            _buildStatCard('Contamination', tds.toStringAsFixed(0), 'ppm', Colors.purpleAccent),
            _buildStatCard('Dissolved O2', doVal.toStringAsFixed(2), 'mg/L', Colors.lightBlueAccent),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.inter(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit, style: GoogleFonts.inter(color: Colors.white30, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPhColor(double ph) {
    if (ph < 6.5) return Colors.redAccent;
    if (ph > 8.5) return Colors.redAccent;
    return Colors.greenAccent;
  }

  Widget _buildHistoryGraph() {
    if (_recentReadings.isEmpty) {
      return GlassCard(
        height: 200,
        child: Center(
          child: Text('No recent readings to display.', style: GoogleFonts.inter(color: Colors.white54)),
        ),
      );
    }

    List<FlSpot> spots = [];
    double maxContaminants = 100.0;

    for (int i = 0; i < _recentReadings.length; i++) {
      final reading = _recentReadings[i];
      spots.add(FlSpot(i.toDouble(), reading.contaminants));
      if (reading.contaminants > maxContaminants) {
        maxContaminants = reading.contaminants;
      }
    }

    return GlassCard(
      height: 250,
      padding: const EdgeInsets.only(right: 24, top: 24, bottom: 12, left: 12),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (_recentReadings.length - 1).toDouble() > 0 ? (_recentReadings.length - 1).toDouble() : 1,
          minY: 0,
          maxY: maxContaminants * 1.2,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 10));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Hide X axis labels for simplicity
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.purpleAccent,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.purpleAccent.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyReportChart() {
    // Static mock data for the week
    final List<FlSpot> weeklySpots = [
      const FlSpot(0, 40), // Mon
      const FlSpot(1, 45), // Tue
      const FlSpot(2, 60), // Wed
      const FlSpot(3, 50), // Thu
      const FlSpot(4, 70), // Fri
      const FlSpot(5, 55), // Sat
      const FlSpot(6, 42), // Sun
    ];

    return GlassCard(
      height: 200,
      padding: const EdgeInsets.only(right: 24, top: 24, bottom: 12, left: 12),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(days[value.toInt()], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value % 20 == 0) {
                    return Text(value.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: weeklySpots.map((spot) {
            return BarChartGroupData(
              x: spot.x.toInt(),
              barRods: [
                BarChartRodData(
                  toY: spot.y,
                  color: Colors.blueAccent,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthlyReportChart() {
    // Static mock data for the month (weeks 1-4)
    final List<FlSpot> monthlySpots = [
      const FlSpot(0, 50),
      const FlSpot(1, 80),
      const FlSpot(2, 45),
      const FlSpot(3, 60),
    ];

    return GlassCard(
      height: 200,
      padding: const EdgeInsets.only(right: 24, top: 24, bottom: 12, left: 12),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 3,
          minY: 0,
          maxY: 100,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value % 20 == 0) {
                    return Text(value.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('W${value.toInt() + 1}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: monthlySpots,
              isCurved: true,
              color: Colors.tealAccent,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.tealAccent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterDefinitions() {
    return Column(
      children: [
        _buildDefinitionCard(
          'pH Level',
          'Measures how acidic or basic the water is.',
          'Safe Range: 6.5 - 8.5',
          Icons.science_outlined,
          Colors.greenAccent,
        ),
        const SizedBox(height: 12),
        _buildDefinitionCard(
          'Contamination (TDS)',
          'Total Dissolved Solids. Represents the total concentration of dissolved substances in water.',
          'Safe Range: < 300 ppm (Excellent), up to 500 ppm (Acceptable)',
          Icons.opacity,
          Colors.purpleAccent,
        ),
        const SizedBox(height: 12),
        _buildDefinitionCard(
          'Turbidity',
          'Measures the cloudiness or haziness of a fluid caused by large numbers of individual particles.',
          'Safe Range: < 1 NTU (Ideal), up to 5 NTU (Acceptable)',
          Icons.waves,
          Colors.brown.shade300,
        ),
        const SizedBox(height: 12),
        _buildDefinitionCard(
          'Dissolved Oxygen',
          'The amount of oxygen that is present in water. Crucial for aquatic life and indicates water freshness.',
          'Safe Range: > 6.5 mg/L',
          Icons.air,
          Colors.lightBlueAccent,
        ),
        const SizedBox(height: 12),
        _buildDefinitionCard(
          'Temperature',
          'Affects the rate of chemical reactions and the amount of dissolved gases (like oxygen) the water can hold.',
          'Safe Range: Varies by source, generally 15°C - 25°C for drinking',
          Icons.thermostat,
          Colors.orangeAccent,
        ),
      ],
    );
  }

  Widget _buildDefinitionCard(String title, String summary, String safeRange, IconData icon, Color headerColor) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: headerColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(summary, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.4)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(safeRange, style: GoogleFonts.inter(color: headerColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
