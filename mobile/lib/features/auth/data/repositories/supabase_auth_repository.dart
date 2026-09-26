import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/hive_boxes.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/auth/user_directory_helper.dart';
import '../../domain/models/user_model.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mock_users.dart';

/// Supabase-backed implementation of [AuthRepository].
///
/// Uses `supabase.auth` for sign-in/sign-out and queries the
/// `public.user_profiles` table for role & profile data.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  UserModel? _cachedUser;

  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  UserModel? get cachedUser => _cachedUser;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📡 SupabaseAuthRepository: calling signInWithPassword for $email');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        debugPrint('⚠️ SupabaseAuthRepository: user is null in response');
        throw const InvalidCredentialsException();
      }

      debugPrint('📡 SupabaseAuthRepository: auth successful (UID: ${user.id}), fetching profile...');
      final profile = await getUserProfile(user.id);
      _cachedUser = profile;
      debugPrint('📡 SupabaseAuthRepository: profile retrieved: ${profile.name}');
      return profile;
    } on AuthException catch (e) {
      debugPrint('❌ SupabaseAuthRepository AuthException: [${e.statusCode}] ${e.message}');
      String friendlyMessage = 'بيانات الدخول غير صحيحة';
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
        friendlyMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      } else if (msg.contains('database error querying schema') || msg.contains('unexpected_failure')) {
        friendlyMessage = 'حسابات المستخدمين في Supabase تحتاج إلى تشغيل كود الإصلاح (SQL Fix) في SQL Editor لتفعيلها.';
      } else if (msg.contains('email not confirmed')) {
        friendlyMessage = 'البريد الإلكتروني لم يتم تأكيده بعد في Supabase';
      } else if (msg.contains('rate limit') || msg.contains('too many requests')) {
        friendlyMessage = 'تم تجاوز عدد المحاولات، يرجى الانتظار دقيقة والمحاولة ثانية';
      } else if (e.message.isNotEmpty) {
        friendlyMessage = e.message;
      }
      throw InvalidCredentialsException(friendlyMessage);
    } on SocketException catch (e) {
      debugPrint('❌ SupabaseAuthRepository SocketException: $e');
      throw const NetworkException();
    } on InvalidCredentialsException {
      rethrow;
    } on ProfileNotFoundException catch (e) {
      debugPrint('❌ SupabaseAuthRepository ProfileNotFoundException: ${e.message}');
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      debugPrint('❌ SupabaseAuthRepository unexpected error: $e');
      // Catch-all for unexpected errors (e.g. DNS resolution failures)
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException') ||
          e.toString().contains('Failed host lookup')) {
        throw const NetworkException();
      }
      throw InvalidCredentialsException('خطأ غير متوقع: $e');
    }
  }

  @override
  Future<UserModel> getUserProfile(String userId) async {
    // 1. Attempt to fetch remote profile from Supabase with 4s timeout
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (response != null) {
        final authUser = _client.auth.currentUser;
        final email = authUser?.email ?? '';
        final profile = UserModel.fromSupabaseProfile(
          response,
          email: email,
        );
        _cachedUser = profile;
        UserDirectoryHelper.registerUser(profile);
        _persistUserLocally(profile);
        return profile;
      }
    } catch (e) {
      debugPrint('⚠️ SupabaseAuthRepository: remote profile fetch failed: $e');
    }

    // 2. Fallback: Restore from local Hive cache if available
    final localProfile = _getLocalUserProfile(userId);
    if (localProfile != null) {
      debugPrint('📦 SupabaseAuthRepository: restored profile from Hive for $userId');
      _cachedUser = localProfile;
      UserDirectoryHelper.registerUser(localProfile);
      return localProfile;
    }

    // 3. Fallback: Synthesize from authenticated Supabase user metadata
    final authUser = _client.auth.currentUser;
    if (authUser != null && authUser.id == userId) {
      final synthesized = _synthesizeUserFromAuth(authUser);
      debugPrint('🛡️ SupabaseAuthRepository: synthesized profile from userMetadata for ${synthesized.name}');
      _cachedUser = synthesized;
      UserDirectoryHelper.registerUser(synthesized);
      _persistUserLocally(synthesized);
      return synthesized;
    }

    // 4. Fallback: Resolve friendly name if known
    final resolvedName = UserDirectoryHelper.resolveName(userId);
    if (resolvedName != null) {
      final fallback = UserModel.fromSupabaseProfile(
        {
          'id': userId,
          'full_name': resolvedName,
          'role': 'OPERATOR',
        },
        email: authUser?.email ?? '',
      );
      _cachedUser = fallback;
      _persistUserLocally(fallback);
      return fallback;
    }

    throw ProfileNotFoundException(
      userId: userId,
      message: 'لم يتم العثور على الملف الشخصي للمستخدم $userId',
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _cachedUser = null;
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      // Allow sign-out to succeed even if network fails
      // (local session is cleared regardless)
      _cachedUser = null;
    }
  }

  @override
  Future<List<UserModel>> getUsersByRole(
    String role, {
    String? speciality,
  }) async {
    try {
      debugPrint('📡 SupabaseAuthRepository: fetching users with role=$role speciality=$speciality');

      // Normalize role names: TECHNICIAN and MAINTENANCE_TECH are synonymous
      final isTechRole = role.toUpperCase() == 'TECHNICIAN' ||
          role.toUpperCase() == 'MAINTENANCE_TECH';

      var query = _client.from('user_profiles').select();

      if (isTechRole) {
        query = query.inFilter('role', [
          'TECHNICIAN',
          'technician',
          'MAINTENANCE_TECH',
          'maintenance_tech',
        ]);
      } else {
        query = query.inFilter('role', [role.toUpperCase(), role.toLowerCase()]);
      }

      // Column name in DB is 'specialty' (not 'speciality')
      if (speciality != null && speciality.isNotEmpty) {
        // Technicians with 'ALL' or matching speciality should appear
        query = query.or('specialty.ilike.%$speciality%,specialty.ilike.%ALL%');
      }

      final response = await query.timeout(const Duration(seconds: 4));
      debugPrint('📡 SupabaseAuthRepository: got ${response.length} users for role=$role');

      final users = (response as List)
          .map((row) => UserModel.fromSupabaseProfile(row as Map<String, dynamic>, email: ''))
          .toList();

      if (users.isNotEmpty) {
        UserDirectoryHelper.registerUsers(users);
        for (final u in users) {
          _persistUserLocally(u);
        }
        return users;
      }

      // If remote returned 0 users (e.g. RLS blocked anon, table empty, or mismatch), fallback to local/seed
      debugPrint('⚠️ Supabase returned 0 users for role=$role. Using local/seed fallback.');
      return getLocalUsersByRole(role, speciality: speciality);
    } catch (e) {
      debugPrint('❌ SupabaseAuthRepository getUsersByRole error: $e');
      return getLocalUsersByRole(role, speciality: speciality);
    }
  }

  UserModel? _getLocalUserProfile(String userId) {
    try {
      if (Hive.isBoxOpen(HiveBoxes.usersBox)) {
        final box = Hive.box<UserModel>(HiveBoxes.usersBox);
        return box.get(userId);
      }
    } catch (e) {
      debugPrint('⚠️ SupabaseAuthRepository: Hive read error: $e');
    }
    return null;
  }

  void _persistUserLocally(UserModel user) {
    try {
      if (Hive.isBoxOpen(HiveBoxes.usersBox)) {
        final box = Hive.box<UserModel>(HiveBoxes.usersBox);
        box.put(user.id, user);
      }
    } catch (e) {
      debugPrint('⚠️ SupabaseAuthRepository: Hive write error: $e');
    }
  }

  UserModel _synthesizeUserFromAuth(User authUser) {
    final meta = authUser.userMetadata ?? {};
    final email = authUser.email ?? '';
    final name = (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        UserDirectoryHelper.resolveName(authUser.id) ??
        (email.contains('@') ? email.split('@').first : 'مستخدم');

    final profileMap = <String, dynamic>{
      'id': authUser.id,
      'full_name': name,
      'role': (meta['role'] as String?) ?? 'OPERATOR',
      'specialty': (meta['specialty'] as String?) ?? (meta['speciality'] as String?),
      'department': meta['department'] as String?,
      'employee_code': meta['employee_code'] as String?,
    };

    return UserModel.fromSupabaseProfile(profileMap, email: email);
  }

  @override
  List<UserModel> getLocalUsersByRole(String role, {String? speciality}) {
    final isTechRole = role.toUpperCase() == 'TECHNICIAN' ||
        role.toUpperCase() == 'MAINTENANCE_TECH';
    try {
      if (Hive.isBoxOpen(HiveBoxes.usersBox)) {
        final box = Hive.box<UserModel>(HiveBoxes.usersBox);
        final local = box.values.where((user) {
          final matchRole = isTechRole
              ? (user.role == UserRole.maintenanceTech)
              : (user.role.name.toUpperCase() == role.toUpperCase());
          if (!matchRole) return false;
          if (speciality != null && speciality.isNotEmpty && user.speciality != null) {
            final userSpec = user.speciality!.toLowerCase();
            final targetSpec = speciality.toLowerCase();
            return userSpec.contains(targetSpec) || userSpec.contains('all') || targetSpec == 'all';
          }
          return true;
        }).toList();

        if (local.isNotEmpty) {
          UserDirectoryHelper.registerUsers(local);
          return local;
        }
      }
    } catch (e) {
      debugPrint('⚠️ SupabaseAuthRepository: _getLocalUsersByRole error: $e');
    }

    if (isTechRole) {
      final seedTechs = MockUsers.getTechnicians(speciality: speciality);
      UserDirectoryHelper.registerUsers(seedTechs);
      return seedTechs;
    }
    return [];
  }
}
