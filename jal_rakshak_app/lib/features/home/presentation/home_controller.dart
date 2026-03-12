
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/home_repository.dart';
import '../domain/home_models.dart';

// Repository Provider
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(Supabase.instance.client);
});

// State Class
class HomeState {
  final List<PublicHealthAlert> alerts;
  final List<StateDiseaseData> stateData;
  final List<DiseaseTrend> trends;

  HomeState({
    required this.alerts,
    required this.stateData,
    required this.trends,
  });
}

// Controller Provider
final homeControllerProvider = FutureProvider<HomeState>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  
  // Fetch all data in parallel
  final results = await Future.wait([
    repository.fetchPublicHealthAlerts(),
    repository.fetchStateDiseaseData(),
    repository.fetchDiseaseTrends(),
  ]);

  return HomeState(
    alerts: results[0] as List<PublicHealthAlert>,
    stateData: results[1] as List<StateDiseaseData>,
    trends: results[2] as List<DiseaseTrend>,
  );
});
