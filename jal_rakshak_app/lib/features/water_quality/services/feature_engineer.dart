import 'dart:math';
import 'buffer_manager.dart';

class FeatureEngineer {
  static const int _windowSize = 5;

  // Calculates standard deviation for a list of values
  double _calculateStd(List<double> values) {
    if (values.isEmpty) return 0.0;
    double mean = values.reduce((a, b) => a + b) / values.length;
    double sumSquaredDiff = values.map((v) => pow(v - mean, 2)).fold(0.0, (a, b) => a + b);
    return sqrt(sumSquaredDiff / values.length);
  }

  // Calculates difference between last two values
  double _calculateDiff(List<double> values) {
    if (values.length < 2) return 0.0;
    return values.last - values[values.length - 2];
  }

  Map<String, double> computeFeatures(BufferManager buffer) {
    // Get last 5 values for rolling calculations
    final doVals = buffer.getLastN('DO', _windowSize);
    final condVals = buffer.getLastN('COND', _windowSize);
    final tempVals = buffer.getLastN('TEMP', _windowSize);
    final turbVals = buffer.getLastN('TURB', _windowSize);
    final phVals = buffer.getLastN('PH', _windowSize);

    // 1. Rolling Standard Deviation
    double doStd = _calculateStd(doVals);
    double condStd = _calculateStd(condVals);
    double tempStd = _calculateStd(tempVals);
    double turbStd = _calculateStd(turbVals);
    double phStd = _calculateStd(phVals);

    // 2. Differences (using raw values)
    double doDiff = _calculateDiff(doVals);
    double condDiff = _calculateDiff(condVals);
    double tempDiff = _calculateDiff(tempVals);
    double turbDiff = _calculateDiff(turbVals);
    double phDiff = _calculateDiff(phVals);

    // 3. Stress Index
    double stressIndex = doStd.abs() + condStd.abs() + tempStd.abs() + turbStd.abs() + phStd.abs();

    // 4. Cumulative Stress (Count of readings so far)
    double stressCum = buffer.count.toDouble();

    // 5. Interaction Features
    double turbCondInteraction = turbStd * condStd;
    double doTurbInteraction = doStd * turbStd;

    return {
      'DO_roll_std': doStd,
      'DO_diff': doDiff,
      'Conductivity_roll_std': condStd,
      'Conductivity_diff': condDiff,
      'Temperature_roll_std': tempStd,
      'Temperature_diff': tempDiff,
      'Turbidity_roll_std': turbStd,
      'Turbidity_diff': turbDiff,
      'pH_roll_std': phStd,
      'pH_diff': phDiff,
      'stress_index': stressIndex,
      'stress_cum': stressCum,
      'turb_cond_interaction': turbCondInteraction,
      'do_turb_interaction': doTurbInteraction,
    };
  }
}
