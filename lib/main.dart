import 'package:flutter/material.dart';
import 'core/database/hive_service.dart';
import 'core/di/service_locator.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Storage & Register Adapters
  await HiveService.init();

  // Initialize Dependency Injection
  await setupServiceLocator();

  runApp(const CableCmmsApp());
}
