import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/reading_model.dart';
import 'package:intl/intl.dart';

class ReadingDetailsModal extends StatelessWidget {
  final Reading reading;

  const ReadingDetailsModal({super.key, required this.reading});

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('M/d/yyyy, h:mm:ss a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'safe' || status.toLowerCase() == 'low') return AppTheme.success;
    if (status.toLowerCase() == 'unsafe' || status.toLowerCase() == 'high') return AppTheme.error;
    return AppTheme.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassCard(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_outlined, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Reading Details',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 1. General Info (Full Width)
              _buildSection(
                'GENERAL INFO',
                Column(
                  children: [
                    _buildInfoRow('Device Name', reading.deviceName),
                    _buildInfoRow('Timestamp', _formatDate(reading.timestamp)),
                    _buildInfoRow('Source', reading.source, icon: Icons.water_drop, iconColor: Colors.blue),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 2. Analysis Results (Full Width)
              _buildSection(
                'ANALYSIS RESULTS',
                Column(
                  children: [
                    _buildStatusRow('Overall Status', reading.status),
                    const SizedBox(height: 12),
                    _buildPredictionRow('Prediction Model', reading.predictionModel, reading.confidence),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 3. Water Parameters (Grid 2 per row)
              Text(
                'WATER PARAMETERS',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 2; // 12 is spacing
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildParameterCard('pH Level', reading.ph.toStringAsFixed(1), '', const Color(0xFF22C55E), width: itemWidth),
                      _buildParameterCard('Turbidity', reading.turbidity.toStringAsFixed(1), 'NTU', const Color(0xFFEAB308), width: itemWidth),
                      _buildParameterCard('Contaminants', reading.contaminants.toStringAsFixed(0), 'ppm', const Color(0xFFEF4444), width: itemWidth),
                      _buildParameterCard('Temperature', reading.temperature.toStringAsFixed(1), '°C', const Color(0xFF3B82F6), width: itemWidth),
                      _buildParameterCard('Conductivity', reading.conductivity.toStringAsFixed(0), 'µS/cm', const Color(0xFF22C55E), width: itemWidth),
                      _buildParameterCard('Dissolved Oxygen', reading.dissolvedOxygen.toStringAsFixed(1), 'mg/L', const Color(0xFF3B82F6), width: itemWidth),
                      _buildParameterCard('UV Index', reading.uvIndex.toStringAsFixed(1), '', const Color(0xFFA855F7), width: itemWidth),
                      _buildParameterCard('RGB Sensor', reading.rgbSensor, '', const Color(0xFFFFCC00), width: itemWidth),
                    ],
                  );
                }
              ),
              
               const SizedBox(height: 32),
               
               // Close Button
               SizedBox(
                 width: double.infinity,
                 child: OutlinedButton(
                   onPressed: () => Navigator.of(context).pop(),
                   style: OutlinedButton.styleFrom(
                     side: BorderSide(color: Colors.white.withOpacity(0.15)),
                     backgroundColor: Colors.white.withOpacity(0.05),
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   ),
                   child: Text('Close', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          Row(
            children: [
              Text(
                value, 
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: iconColor, size: 14),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    final color = _getStatusColor(status);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionRow(String label, String model, double confidence) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 4),
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(model, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
                ),
            ]
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
             Text('Confidence', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
             Text('${confidence.toStringAsFixed(1)}%', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildParameterCard(String label, String value, String unit, Color color, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 22, // Bigger
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: GoogleFonts.inter(color: Colors.white30, fontSize: 11)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
