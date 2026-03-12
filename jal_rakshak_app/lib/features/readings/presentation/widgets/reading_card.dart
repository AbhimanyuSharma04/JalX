import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/reading_model.dart';
import 'package:intl/intl.dart';

class ReadingCard extends StatelessWidget {
  final Reading reading;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const ReadingCard({
    super.key,
    required this.reading,
    required this.onDelete,
    required this.onViewDetails,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('M/d/yyyy').format(date);
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
    final statusColor = _getStatusColor(reading.status);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), // Add margin for shadow/glow space
      child: GestureDetector(
        onTap: onViewDetails,
        child: GlassCard(
          padding: const EdgeInsets.all(20), // Increased padding
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                             BoxShadow(
                               color: const Color(0xFF3B82F6).withOpacity(0.2), 
                               blurRadius: 8,
                               offset: const Offset(0, 2),
                             )
                          ]
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: Color(0xFF60A5FA), size: 24), // Bigger icon
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reading.deviceName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 18, // Bigger text
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(reading.timestamp),
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                      boxShadow: [
                         BoxShadow(
                           color: statusColor.withOpacity(0.1), 
                           blurRadius: 8,
                         )
                      ]
                    ),
                    child: Text(
                      reading.status.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Divider line
              Container(height: 1, color: Colors.white.withOpacity(0.06)),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Row(
                     children: [
                       Text(
                        'Source',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                       Text(
                        reading.source,
                        style: GoogleFonts.inter(
                          color: Colors.white, 
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                     ],
                   ),
                  
                  // Delete Action
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.white.withOpacity(0.6), size: 22),
                    onPressed: onDelete,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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
