import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/sensor_repository.dart';
import 'tflite_service.dart';
import '../../readings/data/readings_repository.dart';
import '../../readings/domain/reading_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

final autoFetchServiceProvider = StateNotifierProvider<AutoFetchService, AutoFetchState>((ref) {
  return AutoFetchService(ref);
});

class AutoFetchState {
  final bool isEnabled;
  final List<int> selectedDays; // 1 = Monday, 7 = Sunday
  final List<TimeOfDay> timeSlots;

  AutoFetchState({
    this.isEnabled = false,
    this.selectedDays = const [],
    this.timeSlots = const [],
  });

  AutoFetchState copyWith({
    bool? isEnabled,
    List<int>? selectedDays,
    List<TimeOfDay>? timeSlots,
  }) {
    return AutoFetchState(
      isEnabled: isEnabled ?? this.isEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      timeSlots: timeSlots ?? this.timeSlots,
    );
  }
}

class AutoFetchService extends StateNotifier<AutoFetchState> {
  final Ref _ref;
  Timer? _scheduleTimer;

  AutoFetchService(this._ref) : super(AutoFetchState());

  void toggleEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
    if (enabled) {
      _startScheduleTimer();
    } else {
      _scheduleTimer?.cancel();
    }
  }

  void toggleDay(int day) {
    final days = List<int>.from(state.selectedDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    state = state.copyWith(selectedDays: days);
  }

  void addTimeSlot(TimeOfDay time) {
    if (!state.timeSlots.contains(time)) {
      final slots = List<TimeOfDay>.from(state.timeSlots)..add(time);
      // Sort by hour, then minute
      slots.sort((a, b) {
        if (a.hour != b.hour) return a.hour.compareTo(b.hour);
        return a.minute.compareTo(b.minute);
      });
      state = state.copyWith(timeSlots: slots);
    }
  }

  void removeTimeSlot(TimeOfDay time) {
    final slots = List<TimeOfDay>.from(state.timeSlots)..remove(time);
    state = state.copyWith(timeSlots: slots);
  }

  void _startScheduleTimer() {
    _scheduleTimer?.cancel();
    // Check every minute if the current time matches a scheduled slot
    _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndRunSchedule();
    });
    // Also do an initial check just in case we enabled it exactly on the minute
    _checkAndRunSchedule();
  }

  Future<void> _checkAndRunSchedule() async {
    if (!state.isEnabled || state.selectedDays.isEmpty || state.timeSlots.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final currentDay = now.weekday; // 1 = Monday
    
    // Check if today is a selected day
    if (!state.selectedDays.contains(currentDay)) {
      return;
    }

    // Check if the current hour and minute match any time slot exactly
    for (final slot in state.timeSlots) {
      if (now.hour == slot.hour && now.minute == slot.minute) {
        // Only run once per minute per slot match (handled by precision of loop and minute timer)
        _performAutoFetchAndAnalyze();
        break; 
      }
    }
  }

  Future<void> _performAutoFetchAndAnalyze() async {
    try {
      debugPrint('AutoFetchService: Triggering scheduled auto-fetch.');
      final sensorRepo = _ref.read(sensorRepositoryProvider);
      final data = await sensorRepo.fetchCurrentData();

      if (data.containsKey('error')) return;

      final double ph = (data['ph'] as num).toDouble();
      final double turbidity = (data['turbidity'] as num).toDouble();
      final double temp = (data['temperature'] as num).toDouble();
      final double tds = (data['tds'] as num).toDouble();
      final double conductivity = (data['conductivity'] as num).toDouble();
      final double doVal = (data['do'] as num).toDouble();
      final double uv = (data['uv'] as num).toDouble();

      final tfliteService = _ref.read(tfliteServiceProvider);
      // We aren't displaying the calibration in UI to the user if they're not on the screen, 
      // so we will just feed 5 mock rapid readings or 1 reading depending on logic.
      // Assuming 1 reading is enough for this prototype Auto-Fetch cycle.
      tfliteService.clearBuffer();
      tfliteService.addReading(
        doVal: doVal,
        cond: conductivity,
        temp: temp,
        turb: turbidity,
        ph: ph,
      );
      
      // Need 5 readings for predict? For auto fetch, let's just push the same reading 5 times 
      // to quickly bypass the buffer for the background job if necessary. 
      // Since the model needs 5, this is a prototype compromise.
      for (int i=0; i<4; i++) {
        tfliteService.addReading(doVal: doVal, cond: conductivity, temp: temp, turb: turbidity, ph: ph);
      }

      final result = await tfliteService.predict();
      final status = result['status'] as String;

      if (status != 'Calibrating...' && status != 'Error') {
        final predictionLabel = result['risk_level'] as String;
        final confidence = (result['confidence'] as num).toDouble();

        final newReading = Reading(
          id: 0,
          deviceName: 'Scheduled Auto Fetch',
          timestamp: DateTime.now().toIso8601String(),
          status: predictionLabel,
          source: 'Live Stream',
          ph: ph,
          turbidity: turbidity,
          contaminants: tds,
          temperature: temp,
          conductivity: conductivity,
          dissolvedOxygen: doVal,
          predictionModel: predictionLabel,
          confidence: confidence,
          uvIndex: uv,
          rgbSensor: 'Auto',
        );

        await _ref.read(readingsRepositoryProvider).saveReading(newReading);
      }
    } catch (e) {
      debugPrint('Auto fetch error: $e');
    }
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    super.dispose();
  }
}
