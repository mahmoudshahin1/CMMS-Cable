import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/supabase_config.dart';

/// Web implementation of network connectivity check using HTTP requests.
///
/// Uses endpoints that explicitly return `Access-Control-Allow-Origin: *` so the
/// browser's fetch does not throw `ClientException: Failed to fetch`.
Future<bool> checkPlatformNetwork() async {
  final projectUrl = SupabaseConfig.projectUrl.trim();
  final apiKey = SupabaseConfig.publishableKey.trim();

  // 1. Primary check: Supabase Auth health endpoint (CORS-enabled, returns 200 OK)
  if (projectUrl.isNotEmpty) {
    try {
      final base = projectUrl.endsWith('/') ? projectUrl : '$projectUrl/';
      final uri = Uri.parse('${base}auth/v1/health');
      final response = await http.get(
        uri,
        headers: apiKey.isNotEmpty ? {'apikey': apiKey} : null,
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode > 0) {
        return true;
      }
    } catch (_) {
      // Fall through to secondary check
    }

    // 2. Secondary check: Supabase REST API endpoint (CORS-enabled)
    try {
      final base = projectUrl.endsWith('/') ? projectUrl : '$projectUrl/';
      final uri = Uri.parse('${base}rest/v1/');
      final response = await http.get(
        uri,
        headers: apiKey.isNotEmpty ? {'apikey': apiKey} : null,
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode > 0) {
        return true;
      }
    } catch (_) {
      // Fall through to public endpoint check
    }
  }

  // 3. Fallback check: Public CORS-friendly ping
  try {
    final response = await http
        .get(Uri.parse('https://api.github.com/zen'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode > 0) {
      return true;
    }
  } catch (e) {
    debugPrint('⚠️ Web connectivity check offline: $e');
  }

  return false;
}
