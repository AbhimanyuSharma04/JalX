
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:glass_kit/glass_kit.dart';
import '../../core/theme/app_theme.dart';

class PredictionScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const PredictionScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final riskLevel = result['risk_level'] ?? 'Unknown';
    final confidence = (result['confidence'] ?? 0.0) * 100;
    
    Color riskColor = AppTheme.success;
    if (riskLevel == 'High') riskColor = AppTheme.error;
    if (riskLevel == 'Moderate') riskColor = AppTheme.warning;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContainer.frostedGlass(
              height: 300,
              width: 300,
              borderRadius: BorderRadius.circular(150),
              borderWidth: 0,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(
                      riskLevel == 'Safe' ? Icons.check_circle : Icons.warning,
                      size: 64,
                      color: riskColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      riskLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                        shadows: [
                          Shadow(color: riskColor.withOpacity(0.5), blurRadius: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${confidence.toStringAsFixed(1)}% Confidence',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'Water Quality Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
