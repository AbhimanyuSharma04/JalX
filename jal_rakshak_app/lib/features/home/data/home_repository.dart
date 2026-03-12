
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../domain/home_models.dart';

class HomeRepository {
  final SupabaseClient _supabase;

  HomeRepository(this._supabase);

  Future<List<PublicHealthAlert>> fetchPublicHealthAlerts() async {
    try {
      // Use the same table as the website: public_health_news
      // Filter to only recent news (fetched within last 12 hours), same as website API
      final twelveHoursAgo = DateTime.now().subtract(const Duration(hours: 12)).toUtc().toIso8601String();
      final response = await _supabase
          .from('public_health_news')
          .select()
          .gt('fetched_at', twelveHoursAgo)
          .order('published_at', ascending: false);
      final items = (response as List).map((e) => PublicHealthAlert.fromJson(e)).toList();
      debugPrint('Fetched ${items.length} recent news items from public_health_news');
      
      // If no recent news, fetch the latest 10 regardless of age
      if (items.isEmpty) {
        debugPrint('No recent news, fetching latest 10...');
        final fallbackResponse = await _supabase
            .from('public_health_news')
            .select()
            .order('published_at', ascending: false)
            .limit(10);
        return (fallbackResponse as List).map((e) => PublicHealthAlert.fromJson(e)).toList();
      }
      return items;
    } catch (e) {
      // Return mock data if table doesn't exist
      debugPrint('Error fetching public_health_news: $e');
      return [
        PublicHealthAlert(id: '1', title: 'Rise in Waterborne Diseases in Flood-Hit Areas of Kerala', description: 'Health officials report a spike in Cholera cases following recent heavy rains.', date: '2/11/2026', tag: 'Cholera', source: 'MoHFW', country: 'INDIA'),
        PublicHealthAlert(id: '2', title: 'Contaminated water supply leads to Dysentery fears in Mumbai', description: 'Residents are advised to boil water as municipal supply compromise suspected in suburban areas.', date: '2/10/2026', tag: 'Dysentery', source: 'Times of India', country: 'INDIA'),
        PublicHealthAlert(id: '3', title: 'Clean water initiative launched to combat Gastroenteritis in Bihar', description: 'New government program specifically targets rural areas affected by recent outbreaks.', date: '2/9/2026', tag: 'Gastroenteritis', source: 'Local News', country: 'INDIA'),
      ];
    }
  }

  Future<List<StateDiseaseData>> fetchStateDiseaseData() async {
    try {
      // Use the same table as the website: disease_reports
      final response = await _supabase.from('disease_reports').select('state, total_cases, disease_name');
      final rawData = response as List;
      debugPrint('Fetched ${rawData.length} rows from disease_reports for state comparison');

      // Aggregate per state (same logic as the website's state-comparison API)
      final Map<String, int> stateStats = {};
      for (var report in rawData) {
        final state = report['state'] ?? '';
        final cases = (report['total_cases'] ?? 0) as int;
        stateStats[state] = (stateStats[state] ?? 0) + cases;
      }

      if (stateStats.isEmpty) {
        debugPrint('No state disease data found, using mock data');
        throw Exception('Empty state data');
      }

      // Sort by cases desc and convert to model
      final entries = stateStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return entries.map((e) => StateDiseaseData(
        stateName: e.key,
        cases: e.value,
        ratePer1000: 0, // Rate not available from this table
      )).toList();
    } catch (e) {
      // Return mock data if table doesn't exist
      debugPrint('Error fetching disease_reports for state data: $e');
      return [
        StateDiseaseData(stateName: 'UP', cases: 92000, ratePer1000: 0.5),
        StateDiseaseData(stateName: 'WB', cases: 85000, ratePer1000: 0.4),
        StateDiseaseData(stateName: 'MH', cases: 75000, ratePer1000: 0.3),
        StateDiseaseData(stateName: 'Bihar', cases: 62000, ratePer1000: 0.6),
        StateDiseaseData(stateName: 'Gujarat', cases: 55000, ratePer1000: 0.2),
        StateDiseaseData(stateName: 'Punjab', cases: 48000, ratePer1000: 0.1),
      ];
    }
  }

  Future<List<DiseaseTrend>> fetchDiseaseTrends() async {
    try {
      final response = await _supabase.from('monthly_trends').select().order('created_at', ascending: true);
      final rawData = response as List;
      debugPrint('Fetched ${rawData.length} raw trend rows from monthly_trends');

      // The DB stores one row per disease per month:
      //   { month, year, disease_name, cases }
      // We need to pivot into: { month, choleraCases, diarrheaCases, typhoidCases }
      final Map<String, Map<String, dynamic>> grouped = {};
      for (var item in rawData) {
        final key = '${item['month']}-${item['year'] ?? ''}';
        if (!grouped.containsKey(key)) {
          grouped[key] = {
            'month': item['month'] ?? '',
            'cholera': 0,
            'diarrhea': 0,
            'typhoid': 0,
          };
        }
        final diseaseName = (item['disease_name'] ?? '').toString().toLowerCase().replaceAll(' ', '');
        final cases = item['cases'] ?? 0;
        if (diseaseName.contains('cholera')) {
          grouped[key]!['cholera'] = cases;
        } else if (diseaseName.contains('diarrhea') || diseaseName.contains('diarrhoea')) {
          grouped[key]!['diarrhea'] = cases;
        } else if (diseaseName.contains('typhoid')) {
          grouped[key]!['typhoid'] = cases;
        }
      }

      if (grouped.isEmpty) {
        debugPrint('No grouped trend data found, using mock data');
        throw Exception('Empty trends');
      }

      return grouped.values.map((e) => DiseaseTrend(
        month: e['month'] as String,
        choleraCases: (e['cholera'] as num).toInt(),
        diarrheaCases: (e['diarrhea'] as num).toInt(),
        typhoidCases: (e['typhoid'] as num).toInt(),
      )).toList();
    } catch (e) {
       // Return mock data if table doesn't exist
      debugPrint('Error fetching monthly_trends: $e');
      return [
        DiseaseTrend(month: 'Jan', choleraCases: 8500, diarrheaCases: 12000, typhoidCases: 6500),
        DiseaseTrend(month: 'Feb', choleraCases: 9500, diarrheaCases: 15000, typhoidCases: 7500),
        DiseaseTrend(month: 'Mar', choleraCases: 12000, diarrheaCases: 20000, typhoidCases: 10000),
      ];
    }
  }
}
