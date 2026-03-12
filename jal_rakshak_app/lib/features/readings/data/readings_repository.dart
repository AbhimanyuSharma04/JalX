import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/reading_model.dart';

final readingsRepositoryProvider = Provider((ref) => ReadingsRepository());

class ReadingsRepository {
  final _supabase = Supabase.instance.client;
  
  // Mutable mock list for demo purposes
  List<Reading> _mockReadings = [
    Reading(
      id: 1,
      deviceName: 'Device 01',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      status: 'Safe',
      source: 'River',
      ph: 7.2,
      turbidity: 2.5,
      contaminants: 15,
      temperature: 24.5,
      conductivity: 450,
      dissolvedOxygen: 6.5,
      predictionModel: 'Safe',
      confidence: 95.0,
    ),
    Reading(
      id: 2,
      deviceName: 'Device 02',
      timestamp: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      status: 'Unsafe',
      source: 'Lake',
      ph: 8.5,
      turbidity: 6.2,
      contaminants: 120,
      temperature: 28.0,
      conductivity: 890,
      dissolvedOxygen: 4.2,
      predictionModel: 'Unsafe',
      confidence: 88.5,
    ),
     Reading(
      id: 3,
      deviceName: 'Manual Entry',
      timestamp: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      status: 'Safe',
      source: 'Tap',
      ph: 6.9,
      turbidity: 0.8,
      contaminants: 5,
      temperature: 22.0,
      conductivity: 200,
      dissolvedOxygen: 7.8,
      predictionModel: 'Safe',
      confidence: 98.0,
    ),
  ];
  
  Future<List<Reading>> getReadings() async {
    try {
      final response = await _supabase
          .from('user_readings')
          .select()
          .order('id', ascending: false);
          
      return (response as List).map((e) => Reading.fromJson(e)).toList();
    } catch (e) {
      // Return mock data if table doesn't exist or connection fails
      print('Error fetching readings: $e');
      return _mockReadings;
    }
  }

  Future<void> saveReading(Reading reading) async {
    try {
      final data = reading.toJson();
      // Remove id for auto-increment if it's 0
      if (reading.id == 0) {
        data.remove('id');
      }
      
      await _supabase.from('user_readings').insert(data);
    } catch (e) {
      print('Supabase save failed (likely using mock data): $e');
      // Add to mock list for UI feedback
      _mockReadings.insert(0, reading); 
    }
  }

  Future<void> deleteReading(int id) async {
    try {
       await _supabase.from('user_readings').delete().eq('id', id);
    } catch (e) {
      print('Supabase delete failed (likely using mock data): $e');
      _mockReadings.removeWhere((r) => r.id == id);
    }
  }
}

