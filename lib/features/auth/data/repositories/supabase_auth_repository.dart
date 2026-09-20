import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

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
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        throw ProfileNotFoundException(userId: userId);
      }

      // Get the email from the current auth session
      final authUser = _client.auth.currentUser;
      final email = authUser?.email ?? '';

      final profile = UserModel.fromSupabaseProfile(
        response,
        email: email,
      );

      _cachedUser = profile;
      return profile;
    } on ProfileNotFoundException {
      rethrow;
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw const NetworkException();
      }
      throw ProfileNotFoundException(
        userId: userId,
        message: 'خطأ في جلب الملف الشخصي: $e',
      );
    }
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

      final response = await query;
      debugPrint('📡 SupabaseAuthRepository: got ${response.length} users for role=$role');

      return response
          .map((row) => UserModel.fromSupabaseProfile(row, email: ''))
          .toList();
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      debugPrint('❌ SupabaseAuthRepository getUsersByRole error: $e');
      // Return empty list gracefully — caller handles the empty case
      return [];
    }
  }
}
