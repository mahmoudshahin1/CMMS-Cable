import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/database/hive_service.dart';
import 'core/di/service_locator.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } catch (e) {
    debugPrint('⚠️ Supabase initialization failed: $e');
    // App can still run — auth operations will fail gracefully
  }

  // Initialize Hive Storage & Register Adapters
  await HiveService.init();

  // Initialize Dependency Injection
  await setupServiceLocator();

  runApp(const CableCmmsApp());
}
