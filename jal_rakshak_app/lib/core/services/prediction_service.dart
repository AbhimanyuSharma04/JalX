
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';

final predictionServiceProvider = Provider((ref) => PredictionService());

class PredictionService {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> predictWaterQuality({
    required double ph,
    required double turbidity,
    required double temperature,
    required double conductivity,
    required double doVal,
  }) async {
    try {
      // Logic matching src/Dashboard_copy.js handleWaterFormSubmit
      final payload = {
        "DO_roll_std": doVal,
        "DO_diff": 0,
        "Conductivity_roll_std": conductivity,
        "Conductivity_diff": 0,
        "Temperature_roll_std": temperature,
        "Temperature_diff": 0,
        "Turbidity_roll_std": turbidity,
        "Turbidity_diff": 0,
        "pH_roll_std": ph,
        "pH_diff": 0,
        "stress_index": 0,
        "stress_cum": 0,
        "turb_cond_interaction": turbidity * conductivity,
        "do_turb_interaction": doVal * turbidity
      };

      final response = await _dio.post(
        AppConstants.predictApiUrl,
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      );

      final result = response.data;
      
      // Normalize result
      return {
        ...result,
        'risk_level': result['risk_level'],
        'confidence': (result['risk_probability'] as num).toDouble(),
      };
    } catch (e) {
      throw Exception('Prediction Failed: $e');
    }
  }
}
