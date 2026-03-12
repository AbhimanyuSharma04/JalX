
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.session != null) {
      await _storage.write(key: 'session', value: jsonEncode(response.session!.toJson()));
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _storage.delete(key: 'session');
  }

  Future<void> recoverSession() async {
    final jsonStr = await _storage.read(key: 'session');
    if (jsonStr != null) {
      try {
        await _supabase.auth.recoverSession(jsonStr);
      } catch (e) {
        // Session invalid/expired
        await _storage.delete(key: 'session');
      }
    }
  }
}
