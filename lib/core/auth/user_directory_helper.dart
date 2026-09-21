import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../database/hive_boxes.dart';
import '../di/service_locator.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Central directory helper resolving user UUIDs and system IDs to friendly display names.
class UserDirectoryHelper {
  const UserDirectoryHelper._();

  static final Map<String, String> _memoryDirectory = {
    // Known seed and provisioning users
    'a777edcb-e42e-4c94-aac9-1b89dd364ce5': 'أحمد فني كهرباء وتحكم',
    'c79d06f1-09b2-4d01-99e9-0c8fced1e56b': 'م. هشام راضي - مشرف الصيانة',
    'usr-tech-elec-02': 'طارق المنصور - فني كهرباء',
    'usr-tech-mech-03': 'سمير فوزي - فني ميكانيكا',
    'usr-maint-sup-04': 'م. هشام راضي - مشرف الصيانة',
    'usr-prod-sup-05': 'م. كريم عزت - مشرف الإنتاج',
    'usr-manager-06': 'م. محمود علي - مدير المصنع',
    'usr-dept-drawing': 'م. أحمد سعيد - خط السحب',
    'usr-dept-stranding': 'م. عمر خالد - خط الجدل',
    'usr-dept-ccv': 'م. محمد يوسف - خط CCV',
    'usr-dept-extrusion': 'م. علي حسن - خط العزل',
    'usr-dept-assembly': 'م. مصطفى إبراهيم - خط التجميع',
    'usr-dept-screening': 'م. ياسر حمدي - خط الحماية',
    'usr-dept-tape': 'م. تامر نبيل - خط التسليح',
  };

  /// Registers a user in the in-memory and persistent cache.
  static void registerUser(UserModel user) {
    if (user.id.trim().isNotEmpty && user.name.trim().isNotEmpty) {
      _memoryDirectory[user.id] = user.name;
    }
  }

  /// Batch-registers multiple users.
  static void registerUsers(Iterable<UserModel> users) {
    for (final u in users) {
      registerUser(u);
    }
  }

  /// Resolves the currently authenticated user from AuthRepository.
  static UserModel? get currentUser {
    try {
      if (getIt.isRegistered<AuthRepository>()) {
        return getIt<AuthRepository>().cachedUser;
      }
    } catch (e) {
      debugPrint('UserDirectoryHelper: could not fetch cachedUser: $e');
    }
    return null;
  }

  /// Resolves a user ID or UUID to a human-friendly name.
  static String? resolveName(String? idOrUuid) {
    if (idOrUuid == null || idOrUuid.trim().isEmpty) return null;
    final cleanId = idOrUuid.trim();

    // 1. In-memory lookup
    if (_memoryDirectory.containsKey(cleanId)) {
      return _memoryDirectory[cleanId];
    }

    // 2. Hive usersBox lookup if open
    try {
      if (Hive.isBoxOpen(HiveBoxes.usersBox)) {
        final box = Hive.box<UserModel>(HiveBoxes.usersBox);
        final user = box.get(cleanId);
        if (user != null && user.name.trim().isNotEmpty) {
          _memoryDirectory[cleanId] = user.name;
          return user.name;
        }
      }
    } catch (e) {
      debugPrint('UserDirectoryHelper: usersBox lookup error: $e');
    }

    return null;
  }

  /// Replaces raw technician UUID in action summaries with the technician's display name.
  static String formatActionSummary(String summary) {
    final assignRegex = RegExp(r'Assigned to technician\s+([a-f0-9\-]+)', caseSensitive: false);
    final match = assignRegex.firstMatch(summary);
    if (match != null) {
      final rawId = match.group(1)!;
      final resolved = resolveName(rawId);
      if (resolved != null) {
        return summary.replaceAll(rawId, resolved);
      }
    }
    return summary;
  }
}
