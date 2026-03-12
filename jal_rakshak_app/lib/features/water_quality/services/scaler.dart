
class Scaler {
  // Provided Mean Values
  static const Map<String, double> _mean = {
    'DO_roll_std': 0.04115088234457871,
    'DO_diff': 5.088106212521287e-06,
    'Conductivity_roll_std': 1.1795581072397034,
    'Conductivity_diff': 0.00021765787686896034,
    'Temperature_roll_std': 0.059577883119242184,
    'Temperature_diff': -3.838693464779728e-05,
    'Turbidity_roll_std': 0.8901171699672661,
    'Turbidity_diff': -3.7425847918764094e-05,
    'pH_roll_std': 0.014523312978680649,
    'pH_diff': 9.610867290317697e-07,
    'stress_index': 2.1849273556494713,
    'stress_cum': 90592.43841667181,
    'turb_cond_interaction': 11.612113936506493,
    'do_turb_interaction': 0.06568309073013134,
  };

  // Provided Std Values
  static const Map<String, double> _std = {
    'DO_roll_std': 0.05511972513872733,
    'DO_diff': 0.0606319706176252,
    'Conductivity_roll_std': 10.374734080600382,
    'Conductivity_diff': 8.989487429688326,
    'Temperature_roll_std': 0.07284623164919812,
    'Temperature_diff': 0.07961147356485451,
    'Turbidity_roll_std': 6.4188808385715,
    'Turbidity_diff': 6.53784971234371,
    'pH_roll_std': 0.024449362527231563,
    'pH_diff': 0.034691838841895105,
    'stress_index': 13.058098906958115,
    'stress_cum': 67833.7120736674,
    'turb_cond_interaction': 363.90397423594345,
    'do_turb_interaction': 1.5754394202820377,
  };

  List<double> scale(Map<String, double> features) {
    // CRITICAL: Order must match exactly
    final List<String> order = [
      'DO_roll_std',
      'DO_diff',
      'Conductivity_roll_std',
      'Conductivity_diff',
      'Temperature_roll_std',
      'Temperature_diff',
      'Turbidity_roll_std',
      'Turbidity_diff',
      'pH_roll_std',
      'pH_diff',
      'stress_index',
      'stress_cum',
      'turb_cond_interaction',
      'do_turb_interaction',
    ];

    return order.map((key) {
      double value = features[key] ?? 0.0;
      double mean = _mean[key] ?? 0.0;
      double std = _std[key] ?? 1.0;
      return (value - mean) / std;
    }).toList();
  }
}
