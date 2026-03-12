
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../home/domain/home_models.dart';
import '../home/presentation/home_controller.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/widgets/add_device_dialog.dart';
import '../home/widgets/expanded_graph_screen.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  void _showAddDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddDeviceDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeStateAsync = ref.watch(homeControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('JAL-X', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                case 'add_device':
                  _showAddDeviceDialog(context);
                  break;
                case 'community':
                  context.go('/community');
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
              PopupMenuItem<String>(
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
                        Navigator.pop(context); // Close menu
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
          child: homeStateAsync.when(
            data: (homeState) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // REORDERED: Graphs First — with staggered entrance
                   _staggeredEntry(
                     delay: 0,
                     child: _buildStateComparisonChart(context, homeState.stateData),
                   ),
                  const SizedBox(height: 24),
                  _staggeredEntry(
                    delay: 1,
                    child: _buildDiseaseTrendsChart(context, homeState.trends),
                  ),
                  const SizedBox(height: 24),
                  
                  // REORDERED: News Last
                  _staggeredEntry(
                    delay: 2,
                    child: _buildAlertsSection(homeState.alerts),
                  ),
                  const SizedBox(height: 24),
                  
                  Center(
                    child: Text(
                      'Data sourced from mock simulations & IDSP public records (Verified via WHO/MoHFW norms).',
                      style: GoogleFonts.inter(color: Colors.white30, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 80), // Extra padding for bottom nav
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            error: (err, stack) => Center(child: Text('Error loading data: $err', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ),
    );
  }

  Widget _staggeredEntry({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (delay * 150)),
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
      child: child,
    );
  }

  Widget _buildAlertsSection(List<PublicHealthAlert> alerts) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.newspaper, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Public Health Alerts & Disease News',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Verified updates from WHO & MoHFW', 
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380, // Fixed height for scrollable list
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: alerts.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _buildAlertItem(alert);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('Refreshes every 12 hours • Data aggregated from public sources', style: GoogleFonts.inter(color: Colors.white30, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildAlertItem(PublicHealthAlert alert) {
    return _NewsCard(alert: alert);
  }

  Widget _buildStateComparisonChart(BuildContext context, List<StateDiseaseData> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    // Find max cases for y-axis normalization
    double maxCases = 0;
    for (var item in data) {
      if (item.cases > maxCases) maxCases = item.cases.toDouble();
    }
    final maxY = (maxCases * 1.1).roundToDouble(); // 10% buffering

    // Helper to build Chart Widget (reusable for card and expanded)
    Widget buildChart({bool isExpanded = false}) {
      return BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: const Color(0xFF1E293B),
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final state = data[group.x.toInt()];
                return BarTooltipItem(
                  '${state.stateName}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: 'Cases: ${state.cases}\nRate: ${state.ratePer1000}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < data.length) {
                     // Show all titles in expanded, or abbreviate in small?
                     // For now showing all as per original logic.
                     return SideTitleWidget(
                      axisSide: meta.axisSide,
                      angle: -0.5, // Rotate labels ~28 degrees
                      child: Text(
                        data[value.toInt()].stateName, 
                        style: TextStyle(
                          color: Colors.white54, 
                          fontSize: isExpanded ? 10 : 8, // Smaller font
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                   if (value == 0) return const SizedBox.shrink();
                   return Text('${(value ~/ 1000)}k', style: const TextStyle(color: Colors.white30, fontSize: 10));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.cases.toDouble(),
                  color: const Color(0xFF3B82F6),
                  width: isExpanded ? 24 : 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          maxY: maxY,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return FadeTransition(
                opacity: animation,
                child: ExpandedGraphScreen(
                  title: 'All-India State Comparison',
                  legend: [
                    _buildLegendIndicator(const Color(0xFF3B82F6), 'Cases'),
                    _buildLegendIndicator(const Color(0xFF10B981), 'Rate per 1000'),
                  ],
                  child: Expanded(child: buildChart(isExpanded: true)),
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
            reverseTransitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Hero(
        tag: 'state_chart',
        child: GlassCard(
          height: 350,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('All-India State Comparison', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  const Icon(Icons.fullscreen, color: Colors.white54, size: 20),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28.0),
                child: Text('Highest reported cases in UP & Bihar (Tap to expand)', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendIndicator(const Color(0xFF3B82F6), 'Cases'),
                  const SizedBox(width: 16),
                  _buildLegendIndicator(const Color(0xFF10B981), 'Rate per 1000'),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: buildChart(isExpanded: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _buildDiseaseTrendsChart(BuildContext context, List<DiseaseTrend> trends) {
    if (trends.isEmpty) return const SizedBox.shrink();

    // Calculate max Y for scaling
    double maxY = 0;
    for (var t in trends) {
      if (t.choleraCases > maxY) maxY = t.choleraCases.toDouble();
      if (t.diarrheaCases > maxY) maxY = t.diarrheaCases.toDouble();
      if (t.typhoidCases > maxY) maxY = t.typhoidCases.toDouble();
    }
    maxY = (maxY * 1.1).roundToDouble();
    
    // Helper
    Widget buildChart({bool isExpanded = false}) {
      return LineChart(
        LineChartData(
          minX: 0,
          maxX: (trends.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            // Diarrhea (Red)
            _makeLineChartBarData(
              trends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.diarrheaCases.toDouble())).toList(),
              Colors.redAccent,
            ),
            // Cholera (Orange)
            _makeLineChartBarData(
               trends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.choleraCases.toDouble())).toList(),
              Colors.orange,
            ),
             // Typhoid (Blue)
            _makeLineChartBarData(
               trends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.typhoidCases.toDouble())).toList(),
              Colors.blue,
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < trends.length) {
                     return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(trends[value.toInt()].month, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 5000,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}', style: const TextStyle(color: Colors.white30, fontSize: 10));
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
        ),
      );
    }

    return GestureDetector(
      onTap: () {
         Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return FadeTransition(
                opacity: animation,
                child: ExpandedGraphScreen(
                  title: 'Disease Trends (Monthly)',
                  legend: [
                    _buildLegendIndicator(Colors.orange, 'Cholera'),
                    _buildLegendIndicator(Colors.redAccent, 'Diarrhea'),
                    _buildLegendIndicator(Colors.blue, 'Typhoid'),
                  ],
                  child: Expanded(child: buildChart(isExpanded: true)),
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
            reverseTransitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Hero(
        tag: 'trend_chart',
        child: GlassCard(
          height: 350,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Disease Trends (Monthly)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  const Icon(Icons.fullscreen, color: Colors.white54, size: 20),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28.0),
                child: Text('Peak transmission observed in July-Aug', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendIndicator(Colors.orange, 'Cholera'),
                  const SizedBox(width: 12),
                  _buildLegendIndicator(Colors.redAccent, 'Diarrhea'),
                  const SizedBox(width: 12),
                  _buildLegendIndicator(Colors.blue, 'Typhoid'),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: buildChart(isExpanded: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _makeLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

// News Card Widget (Summary View)
class _NewsCard extends StatelessWidget {
  final PublicHealthAlert alert;
  
  const _NewsCard({required this.alert});

  Color _getTagColor(String tag) {
    if (tag.contains('Cholera')) return Colors.orange;
    if (tag.contains('Dysentery')) return Colors.redAccent;
    if (tag.contains('Gastroenteritis')) return Colors.purpleAccent;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'News Detail',
            barrierColor: Colors.black.withOpacity(0.5),
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) {
              return Center(
                child: FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                    child: _NewsDetailDialog(alert: alert, tagColor: _getTagColor(alert.tag)),
                  ),
                ),
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.shade900, borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            const Icon(Icons.flag, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text(alert.country, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: _getTagColor(alert.tag).withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(4),
                          color: _getTagColor(alert.tag).withOpacity(0.1),
                        ),
                        child: Text(
                          alert.tag, 
                          style: GoogleFonts.inter(
                            color: _getTagColor(alert.tag), 
                            fontSize: 10, 
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(alert.date, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                alert.title, 
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, 
                  color: Colors.white, 
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// News Detail Dialog (Full Card Popup)
class _NewsDetailDialog extends StatelessWidget {
  final PublicHealthAlert alert;
  final Color tagColor;

  const _NewsDetailDialog({required this.alert, required this.tagColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        // Removed max constraints to let content determine size, but kept padding
        padding: const EdgeInsets.all(1), // Border width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.transparent,
        ),
        child: GlassCard( // Using existing GlassCard
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade900, borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            const Icon(Icons.flag, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(alert.country, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: tagColor.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(6),
                            color: tagColor.withOpacity(0.1),
                          ),
                          child: Text(
                            alert.tag, 
                            style: GoogleFonts.inter(
                              color: tagColor, 
                              fontSize: 12, 
                              fontWeight: FontWeight.w600
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(), 
                  icon: const Icon(Icons.close, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              alert.title, 
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, 
                color: Colors.white, 
                fontSize: 18,
                height: 1.3,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(alert.date, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: tagColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Full Description',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    alert.description, 
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5, decoration: TextDecoration.none),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF64B5F6), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Source: ${alert.source}', 
                      style: GoogleFonts.inter(color: const Color(0xFF64B5F6), fontSize: 12, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
                    ),
                  ],
                ),

              ],
            ),
          ],
        ),
      ),
    ),
   );
  }
}
