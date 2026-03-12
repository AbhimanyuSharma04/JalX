
class PublicHealthAlert {
  final String id;
  final String title;
  final String description;
  final String date;
  final String tag;
  final String source;
  final String country;

  PublicHealthAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.tag,
    required this.source,
    required this.country,
  });

  factory PublicHealthAlert.fromJson(Map<String, dynamic> json) {
    // Support both public_health_alerts and public_health_news schemas
    String dateStr = json['date'] ?? '';
    if (dateStr.isEmpty && json['published_at'] != null) {
      try {
        final dt = DateTime.parse(json['published_at']);
        dateStr = '${dt.month}/${dt.day}/${dt.year}';
      } catch (_) {
        dateStr = json['published_at'].toString();
      }
    }

    return PublicHealthAlert(
      id: (json['id'] ?? '0').toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? json['summary'] ?? '',
      date: dateStr,
      tag: json['tag'] ?? json['detected_disease'] ?? '',
      source: json['source'] ?? '',
      country: json['country'] ?? json['country_scope'] ?? 'INDIA',
    );
  }
}

class StateDiseaseData {
  final String stateName;
  final int cases;
  final double ratePer1000;

  StateDiseaseData({
    required this.stateName,
    required this.cases,
    required this.ratePer1000,
  });

  factory StateDiseaseData.fromJson(Map<String, dynamic> json) {
    return StateDiseaseData(
      stateName: json['state_name'] ?? '',
      cases: json['cases'] ?? 0,
      ratePer1000: (json['rate_per_1000'] ?? 0).toDouble(),
    );
  }
}

class DiseaseTrend {
  final String month;
  final int choleraCases;
  final int diarrheaCases;
  final int typhoidCases;

  DiseaseTrend({
    required this.month,
    required this.choleraCases,
    required this.diarrheaCases,
    required this.typhoidCases,
  });

  factory DiseaseTrend.fromJson(Map<String, dynamic> json) {
    return DiseaseTrend(
      month: json['month'] ?? '',
      choleraCases: json['cholera_cases'] ?? 0,
      diarrheaCases: json['diarrhea_cases'] ?? 0,
      typhoidCases: json['typhoid_cases'] ?? 0,
    );
  }
}
