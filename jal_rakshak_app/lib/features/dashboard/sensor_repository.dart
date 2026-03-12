
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sensorRepositoryProvider = Provider((ref) => SensorRepository());

final sensorStreamProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(sensorRepositoryProvider).sensorDataStream;
});

class SensorRepository {
  late final DatabaseReference _sensorRef;
  bool _isFirebaseInitialized = false;

  SensorRepository() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _sensorRef = FirebaseDatabase.instance.ref('waterData');
        _isFirebaseInitialized = true;
      }
    } catch (e) {
      print("Firebase not initialized or error: $e");
      _isFirebaseInitialized = false;
    }
  }


  Stream<Map<String, dynamic>> get sensorDataStream {
    if (!_isFirebaseInitialized) {
      return Stream.value({'error': 'Firebase not initialized'});
    }

    return _sensorRef.onValue.map((event) {
      if (event.snapshot.value == null) return <String, dynamic>{};
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return _normalizeData(data);
    }).handleError((error) {
       print("Error in stream: $error");
       return <String, dynamic>{'error': error.toString()};
    });
  }

  Future<Map<String, dynamic>> fetchCurrentData() async {
    if (!_isFirebaseInitialized) {
       // Try to re-init if possible or just return error
       try {
         _sensorRef = FirebaseDatabase.instance.ref('waterData');
         _isFirebaseInitialized = true;
       } catch (e) {
         return {'error': 'Firebase not initialized'};
       }
    }

    try {
      final snapshot = await _sensorRef.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return _normalizeData(data);
      } else {
        return {'error': 'No data available'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    // Map Firebase keys to App keys if necessary, or just pass through
    // Expected Firebase keys: ph, turbidity, temperature, tds, conductivity, do, uv
    
    double safeParse(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return {
      'ph': safeParse(data['ph']),
      'turbidity': safeParse(data['turbidity']),
      'temperature': safeParse(data['temperature']),
      'tds': safeParse(data['tds']), // Mapped to Contamination
      'conductivity': safeParse(data['conductivity']),
      'do': safeParse(data['do']),
      'uv': safeParse(data['uv']),
    };
  }
}
