class Reading {
  final int id;
  final String deviceName;
  final String timestamp;
  final String status;
  final String source;
  final double ph;
  final double turbidity;
  final double contaminants;
  final double temperature;
  final double conductivity;
  final double dissolvedOxygen;
  final String predictionModel;
  final double confidence;
  final double uvIndex;
  final String rgbSensor;

  Reading({
    required this.id,
    required this.deviceName,
    required this.timestamp,
    required this.status,
    required this.source,
    required this.ph,
    required this.turbidity,
    required this.contaminants,
    required this.temperature,
    required this.conductivity,
    required this.dissolvedOxygen,
    required this.predictionModel,
    required this.confidence,
    this.uvIndex = 0.0,
    this.rgbSensor = 'Unknown',
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      id: json['id'] ?? 0,
      deviceName: json['device_name'] ?? 'Unknown Device',
      timestamp: json['created_at'] ?? '',
      status: json['status'] ?? 'Unknown',
      source: json['source'] ?? 'Unknown',
      ph: (json['ph'] ?? 0.0).toDouble(),
      turbidity: (json['turbidity'] ?? 0.0).toDouble(),
      contaminants: (json['contaminants'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      conductivity: (json['conductivity'] ?? 0.0).toDouble(),
      dissolvedOxygen: (json['dissolved_oxygen'] ?? 0.0).toDouble(),
      predictionModel: json['prediction_model'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      uvIndex: (json['uv_index'] ?? 0.0).toDouble(),
      rgbSensor: json['rgb_sensor'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_name': deviceName,
      'status': status,
      'source': source,
      'ph': ph,
      'turbidity': turbidity,
      'contaminants': contaminants,
      'temperature': temperature,
      'conductivity': conductivity,
      'dissolved_oxygen': dissolvedOxygen,
      'prediction_model': predictionModel,
      'confidence': confidence,
      'uv_index': uvIndex,
      'rgb_sensor': rgbSensor,
    };
  }
}
