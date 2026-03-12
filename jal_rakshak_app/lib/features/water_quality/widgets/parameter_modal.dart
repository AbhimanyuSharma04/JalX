
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tflite_service.dart';

class ParameterInputModal extends ConsumerStatefulWidget {
  final String title;
  final String sensorKey; // New: To fetch history/count
  final double value;
  final double min;
  final double max;
  final String unit;
  final Function(double) onChanged;
  final VoidCallback? onAdd; 

  const ParameterInputModal({
    super.key,
    required this.title,
    required this.sensorKey,
    required this.value,
    this.onAdd,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  ConsumerState<ParameterInputModal> createState() => _ParameterInputModalState();
}

class _ParameterInputModalState extends ConsumerState<ParameterInputModal> with SingleTickerProviderStateMixin {
  late double _currentValue;
  late TextEditingController _textController;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _textController = TextEditingController(text: widget.value.toStringAsFixed(2));
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _updateValue(double newValue) {
    setState(() {
      _currentValue = newValue.clamp(widget.min, widget.max);
      _textController.text = _currentValue.toStringAsFixed(2);
    });
    widget.onChanged(_currentValue);
  }

  void _handleTextChange(String value) {
    final double? parsed = double.tryParse(value);
    if (parsed != null) {
       setState(() {
         _currentValue = parsed.clamp(widget.min, widget.max);
       });
       widget.onChanged(parsed.clamp(widget.min, widget.max));
    }
  }

  void _dismissWithAnimation() {
    _animController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tfliteService = ref.watch(tfliteServiceProvider);
    final history = widget.sensorKey.isNotEmpty 
        ? tfliteService.getHistory(widget.sensorKey)
        : <double>[];
    final count = tfliteService.readingCount;
    final isFull = count >= 5;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Material(
            color: Colors.transparent,
            child: GlassCard(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Buffer Status: $count/5',
                              style: GoogleFonts.inter(
                                color: isFull ? const Color(0xFF22C55E) : Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        _AnimatedIconButton(
                          icon: Icons.close,
                          onTap: _dismissWithAnimation,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Text Input
                    TextField(
                      controller: _textController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 18, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Value (${widget.unit})',
                        labelStyle: GoogleFonts.inter(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.25),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                      onChanged: _handleTextChange,
                      onSubmitted: (val) {
                         final double? parsed = double.tryParse(val);
                         if (parsed != null) {
                           _updateValue(parsed);
                         }
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Slider Label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.min.toStringAsFixed(0),
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                        ),
                        Text(
                          'Adjust Value',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          widget.max.toStringAsFixed(0),
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Gradient Slider
                    SizedBox(
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(
                                colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red],
                              ),
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 6,
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, pressedElevation: 8),
                              overlayColor: Colors.white.withOpacity(0.1),
                            ),
                            child: Slider(
                              value: _currentValue.clamp(widget.min, widget.max),
                              min: widget.min,
                              max: widget.max,
                              onChanged: _updateValue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // History List
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Recent Readings',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            // Show latest first
                            // history list is [0..N], where N is latest added.
                            // BufferManager handles push/pop. 
                            // getLastN returns a copy. index 0 of getLastN result is oldest in that snippet.
                            // So last element is the most recent.
                            final reversedIndex = history.length - 1 - index;
                            final val = history[reversedIndex];
                            
                            // The actual index in the buffer corresponds to the index in the history list 
                            // returned by getLastN if we assume getLastN returns the full buffer in insertion order.
                            // So to delete 'val' which is at reversedIndex, we pass reversedIndex.
                            
                            return Center(
                              child: Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 12, top: 6), 
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '#${history.length - index}', // Visual Index (1-based, newest is highest)
                                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          val.toStringAsFixed(2),
                                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: () {
                                        // Remove this specific reading
                                        ref.read(tfliteServiceProvider).removeReading(reversedIndex);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 10, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Add Point Button (New)
                    if (widget.onAdd != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: widget.onAdd,
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2DD4BF)),
                          label: Text(
                            isFull ? 'Add Another Point ($count)' : 'Add Point to Buffer ($count/5)', 
                            style: GoogleFonts.inter(color: const Color(0xFF2DD4BF), fontWeight: FontWeight.bold)
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xFF2DD4BF).withOpacity(0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: const Color(0xFF2DD4BF).withOpacity(0.1),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    
                    // Done Button with gradient
                    _AnimatedGradientButton(
                      label: 'Done',
                      onTap: _dismissWithAnimation,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Icon Button ───────────────────────────────────────
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedIconButton({required this.icon, required this.onTap});

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(widget.icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}

// ─── Animated Gradient Button ───────────────────────────────────
class _AnimatedGradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AnimatedGradientButton({required this.label, required this.onTap});

  @override
  State<_AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2DD4BF), Color(0xFF0F766E)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2DD4BF).withOpacity(_isPressed ? 0.4 : 0.2),
                blurRadius: _isPressed ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
