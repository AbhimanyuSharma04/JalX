
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class SensorCard extends StatefulWidget {
  final String title;
  final String value;
  final String unit;
  final double? numericValue;
  final double? min;
  final double? max;
  final VoidCallback? onTap;
  final VoidCallback? onClear; // New
  final bool isSafe;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    this.unit = '',
    this.numericValue,
    this.min,
    this.max,
    this.onTap,
    this.onClear,
    this.isSafe = true,
  });

  @override
  State<SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<SensorCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: (widget.isSafe ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withOpacity(0.1),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: GlassCard(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header: Title + Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.isSafe 
                                ? const Color(0xFF22C55E).withOpacity(0.2) 
                                : const Color(0xFFEF4444).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.isSafe 
                                  ? const Color(0xFF22C55E).withOpacity(0.5) 
                                  : const Color(0xFFEF4444).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.isSafe ? 'SAFE' : 'UNSAFE',
                            style: GoogleFonts.inter(
                              color: widget.isSafe ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.onClear != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: widget.onClear,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Value
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.value,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        widget.unit,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Gradient Indicator Bar
                if (widget.numericValue != null && widget.min != null && widget.max != null)
                  Column(
                    children: [
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red],
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final clamped = widget.numericValue!.clamp(widget.min!, widget.max!);
                            final range = widget.max! - widget.min!;
                            final percentage = (clamped - widget.min!) / range;
                            
                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                  left: (constraints.maxWidth - 8) * percentage,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
