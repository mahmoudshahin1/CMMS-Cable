import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../database/hive_boxes.dart';
import '../di/service_locator.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/domain/enums/user_role.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Central directory helper resolving user UUIDs and system IDs to friendly display names.
class UserDirectoryHelper {
  const UserDirectoryHelper._();

  static final Map<String, String> _memoryDirectory = {
    // Known seed and provisioning users
    'a777edcb-e42e-4c94-aac9-1b89dd364ce5': 'طارق المنصور - فني كهرباء وتحكم',
    'c79d06f1-09b2-4d01-99e9-0c8fced1e56b': 'م. هشام راضي - مشرف الصيانة',
    '859c128e-5ad6-42c5-b5b5-ec6a99b0defe': 'م. كريم عزت - مشرف الإنتاج',
    '97d56aef-5089-4741-8942-cca54dde3750': 'مدير علي - مدير عام المصنع',
    'a1111111-1111-4111-8111-111111111111': 'أحمد سعيد - مشغل سحب الأسلاك',
    '0a03468c-8212-4c44-9c1f-3ac98fe625bf': 'عمر خالد - مشغل خط الجدل والتجميع',
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
    // Supabase standard provisioned accounts
    'ffffffff-ffff-4fff-8fff-ffffffffffff': 'أحمد سعيد - مشغل خط السحب',
    '11111111-1111-4111-8111-111111111111': 'عمر خالد - مشغل خط الجدل',
    'b2222222-2222-4222-8222-222222222222': 'محمد يوسف - مشغل خط CCV',
    'c3333333-3333-4333-8333-333333333333': 'علي حسن - مشغل خطوط العزل والبثق',
    'd4444444-4444-4444-8444-444444444444': 'مصطفى إبراهيم - مشغل التجميع والتسليح',
    'e5555555-5555-4555-8555-555555555555': 'ياسر حمدي - مشغل الحجب والشريط',
    'f6666666-6666-4666-8666-666666666666': 'تامر نبيل - مشغل تدريع الأشرطة',
    '88888888-8888-4888-8888-888888888888': 'م. محمود علي - مدير المصنع',
    '99999999-9999-4999-8999-999999999999': 'م. هشام راضي - مشرف الصيانة',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa': 'م. كريم عزت - مشرف الإنتاج',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb': 'طارق المنصور - فني كهرباء',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc': 'سمير فوزي - فني ميكانيكا',
    'cc9f6212-bf05-4610-b8a5-64f911565f37': 'طارق المنصور - فني كهرباء وتحكم',
    '90e23813-fe01-4796-8138-61f17275f432': 'سمير فوزي - فني ميكانيكا وهيدروليك',
  };

  static final Map<String, UserModel> _memoryUsers = {};

  /// Registers a user in the in-memory cache and persists to local Hive box.
  static void registerUser(UserModel user) {
    if (user.id.trim().isNotEmpty && user.name.trim().isNotEmpty) {
      _memoryDirectory[user.id] = user.name;
      _memoryUsers[user.id] = user;
      try {
        if (Hive.isBoxOpen(HiveBoxes.usersBox)) {
          final box = Hive.box<UserModel>(HiveBoxes.usersBox);
          box.put(user.id, user);
        }
      } catch (e) {
        debugPrint('UserDirectoryHelper: could not persist user locally: $e');
      }
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

  /// Resolves a full UserModel from ID or UUID across memory, Hive, or synthesis.
  static UserModel? getUser(String? idOrUuid) {
    if (idOrUuid == null || idOrUuid.trim().isEmpty) return null;
    final cleanId = idOrUuid.trim();

    if (_memoryUsers.containsKey(cleanId)) {
      return _memoryUsers[cleanId];
    }

    final current = currentUser;
    if (current != null && current.id == cleanId) {
      _memoryUsers[cleanId] = current;
      _memoryDirectory[cleanId] = current.name;
      return current;
    }

    try {
      if (Hive.isBoxOpen(HiveBoxes.usersBox)) {
        final box = Hive.box<UserModel>(HiveBoxes.usersBox);
        final user = box.get(cleanId);
        if (user != null) {
          _memoryUsers[cleanId] = user;
          _memoryDirectory[cleanId] = user.name;
          return user;
        }
      }
    } catch (e) {
      debugPrint('UserDirectoryHelper: getUser Hive lookup error: $e');
    }

    if (_memoryDirectory.containsKey(cleanId)) {
      final name = _memoryDirectory[cleanId]!;
      final fallbackUser = UserModel(
        id: cleanId,
        name: name,
        email: '$cleanId@cableops.local',
        role: _inferRoleFromName(name),
      );
      _memoryUsers[cleanId] = fallbackUser;
      return fallbackUser;
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

    // 2. Memory user lookup
    if (_memoryUsers.containsKey(cleanId)) {
      return _memoryUsers[cleanId]!.name;
    }

    // 3. Current user lookup
    final current = currentUser;
    if (current != null && current.id == cleanId) {
      return current.name;
    }

    // 4. Hive usersBox lookup if open
    try {
      if (Hive.isBoxOpen(HiveBoxes.usersBox)) {
        final box = Hive.box<UserModel>(HiveBoxes.usersBox);
        final user = box.get(cleanId);
        if (user != null && user.name.trim().isNotEmpty) {
          _memoryDirectory[cleanId] = user.name;
          _memoryUsers[cleanId] = user;
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

  static UserRole _inferRoleFromName(String name) {
    final lower = name.toLowerCase();
    if (name.contains('فني') || lower.contains('tech')) {
      return UserRole.maintenanceTech;
    }
    if (name.contains('مشرف') || lower.contains('sup')) {
      return name.contains('إنتاج')
          ? UserRole.productionSupervisor
          : UserRole.maintenanceSupervisor;
    }
    if (name.contains('مشغل') || lower.contains('lead') || lower.contains('oper')) {
      return UserRole.operator;
    }
    if (name.contains('مدير') || lower.contains('manager')) {
      return UserRole.plantManager;
    }
    return UserRole.operator;
  }
}
