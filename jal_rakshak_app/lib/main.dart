import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  // Initialize Firebase with user-provided config
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBnRZL1iZxoQnvypRFCfeeK0dj0gL5ADS0",
        appId: "1:726428939707:web:a106c4900d10726a31409e",
        messagingSenderId: "726428939707",
        projectId: "waterb-quality-detection",
        databaseURL: "https://waterb-quality-detection-default-rtdb.asia-southeast1.firebasedatabase.app",
        storageBucket: "waterb-quality-detection.firebasestorage.app",
      ),
    );
  } catch(e) {
     print("Firebase Init Error: $e");
  }

  runApp(
    const ProviderScope(
      child: JalXApp(),
    ),
  );
}
