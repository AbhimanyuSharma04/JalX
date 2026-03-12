import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'buffer_manager.dart';
import 'feature_engineer.dart';
import 'scaler.dart';

final tfliteServiceProvider = ChangeNotifierProvider((ref) => TFLiteService());

class TFLiteService extends ChangeNotifier {
  late Interpreter _interpreter;
  final BufferManager _bufferManager = BufferManager();
  final FeatureEngineer _featureEngineer = FeatureEngineer();
  final Scaler _scaler = Scaler();
  
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/water_model.tflite');
      _isModelLoaded = true;
      print('TFLite Model Loaded Successfully');
    } catch (e) {
      print('Error loading TFLite model: $e');
      _isModelLoaded = false;
    }
  }

  void addReading({
    required double doVal,
    required double cond,
    required double temp,
    required double turb,
    required double ph,
  }) {
    _bufferManager.addReading(
      doVal: doVal,
      cond: cond,
      temp: temp,
      turb: turb,
      ph: ph,
    );
    notifyListeners();
  }

  void clearBuffer() {
    _bufferManager.clear();
    notifyListeners();
  }

  void removeReading(int index) {
    _bufferManager.removeReading(index);
    notifyListeners();
  }

  Future<Map<String, dynamic>> predict() async {
    if (!_isModelLoaded) {
      await loadModel();
      if (!_isModelLoaded) {
        print('WARNING: Model failed to load. Using heuristic simulation.');
        return _simulatePrediction();
      }
    }
    
    // Check if buffer has enough data for window size 5
    if (!_bufferManager.isReady) {
      return {
        'status': 'Calibrating...', 
        'confidence': 0.0, 
        'risk_level': 'Unknown',
        'buffer_count': _bufferManager.count
      };
    }

    try {
      // 1. Feature Engineering
      final features = _featureEngineer.computeFeatures(_bufferManager);

      // 2. Scaling
      final scaledInput = _scaler.scale(features);

      // 3. Reshape for Input [1, 14]
      // Use Float32List to ensure correct data type for TFLite
      final input = Float32List.fromList(scaledInput).reshape([1, 14]);

      print('Input shape: ${input.shape}');
      print('Input values: $input');

      // Debug Model Info
      try {
        var inputTensor = _interpreter.getInputTensor(0);
        print('Model Input Tensor: shape=${inputTensor.shape}, type=${inputTensor.type}');
        var outputTensor = _interpreter.getOutputTensor(0);
         print('Model Output Tensor: shape=${outputTensor.shape}, type=${outputTensor.type}');
      } catch(e) {
        print('Error getting tensor info: $e');
      }

      // 4. Output Buffer [1, 1]
      final output = Float32List(1).reshape([1, 1]);

      // 5. Run Inference
      _interpreter.run(input, output);
      print('Inference Output: $output');

      // 6. Get Result
      final probability = output[0][0] as double;

      // 7. Interpret Result
      return _interpretResult(probability);

    } catch (e, stackTrace) {
      print('Inference Error: $e');
      print('Stack Trace: $stackTrace');
      // Graceful error handling
      return {'status': 'Error', 'confidence': 0.0, 'risk_level': 'Error'};
    }
  }

  Map<String, dynamic> _interpretResult(double probability) {
    String riskLevel;
    if (probability < 0.3) {
      riskLevel = 'Low';
    } else if (probability < 0.6) {
      riskLevel = 'Moderate';
    } else {
      riskLevel = 'High';
    }

    return {
      'status': riskLevel,
      'confidence': (probability * 100).clamp(0.0, 100.0),
      'risk_level': riskLevel,
      'probability': probability
    };
  }
  
  Map<String, dynamic> _simulatePrediction() {
     // Fallback logic if model fails
     // Simple heuristics based on water quality standards
     try {
       final ph = _bufferManager.getLastN('PH', 1).first;
       final turb = _bufferManager.getLastN('TURB', 1).first;
       final doVal = _bufferManager.getLastN('DO', 1).first;
       
       bool isSafe = true;
       if (ph < 6.5 || ph > 8.5) isSafe = false;
       if (turb > 5.0) isSafe = false;
       if (doVal < 4.0) isSafe = false;
       
       return {
         'status': isSafe ? 'Safe' : 'Unsafe', // For internal logic
         'risk_level': isSafe ? 'Safe' : 'High',
         'confidence': 85.0,
         'probability': isSafe ? 0.15 : 0.85, 
       };
     } catch (e) {
       return {
         'status': 'Error', 
         'risk_level': 'Error',
         'confidence': 0.0,
         'probability': 0.0
       };
     }
  }

  int get readingCount => _bufferManager.count;

  List<double> getHistory(String sensor) {
    // Return all available history (up to 20)
    return _bufferManager.getLastN(sensor, 20);
  }

  void dispose() {
    if(_isModelLoaded) _interpreter.close();
    super.dispose();
  }
}
