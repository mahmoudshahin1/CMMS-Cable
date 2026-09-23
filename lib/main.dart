import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/database/hive_service.dart';
import 'core/di/service_locator.dart';
import 'core/sync/outbox/outbox_sync_engine.dart';
import 'core/sync/realtime/supabase_realtime_sync_service.dart';
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

  // Eagerly trigger background sync & realtime subscriptions
  try {
    getIt<SupabaseRealtimeSyncService>().subscribe();
    unawaited(getIt<OutboxSyncEngine>().syncNow());
  } catch (e) {
    debugPrint('⚠️ Startup sync trigger failed: $e');
  }

  runApp(const CableCmmsApp());
}
