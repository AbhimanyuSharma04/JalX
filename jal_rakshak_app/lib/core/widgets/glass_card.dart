
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
          height: height,
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.08), // More transparent for liquid look
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: border ?? Border.all(color: Colors.white.withOpacity(0.15), width: 1.5), // Slightly more visible border
            // No boxShadow for "pure liquid glass"
          ),
          child: child,
        ),
      ),
    );
  }
}
