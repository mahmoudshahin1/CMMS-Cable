import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'auth_state.dart';
import '../../domain/models/user_model.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/enums/app_permission.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/auth_exceptions.dart';

/// Manages authentication state using a [AuthRepository] backend.
///
/// On construction, checks for an existing Supabase session and
/// auto-restores the user if one is found.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _initAuth();
  }

  /// Check for an existing session on app start.
  ///
  /// Gracefully handles cases where Supabase isn't initialized
  /// (e.g. in unit tests or when initialization fails).
  Future<void> _initAuth() async {
    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session != null) {
        emit(AuthLoading());
        final userId = session.user.id;
        final profile = await _authRepository.getUserProfile(userId);
        emit(Authenticated(profile));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      // Supabase not initialized, or profile fetch failed → force login
      emit(Unauthenticated());
    }
  }

  /// Authenticate with email and password via Supabase.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 AuthCubit.signIn called with email: $email');
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      debugPrint('✅ AuthCubit.signIn success: ${user.name} (${user.role})');
      emit(Authenticated(user));
    } on InvalidCredentialsException catch (e) {
      debugPrint('❌ AuthCubit.signIn InvalidCredentialsException: ${e.message}');
      emit(AuthError(e.message));
    } on NetworkException catch (e) {
      debugPrint('❌ AuthCubit.signIn NetworkException: ${e.message}');
      emit(AuthError(e.message));
    } on ProfileNotFoundException catch (e) {
      debugPrint('❌ AuthCubit.signIn ProfileNotFoundException: ${e.message}');
      emit(AuthError(e.message));
    } catch (e) {
      debugPrint('❌ AuthCubit.signIn Unexpected error: $e');
      emit(AuthError('خطأ غير متوقع: $e'));
    }
  }

  /// Sign out and clear the session.
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (_) {
      // Always transition to unauthenticated even if network fails
    }
    emit(Unauthenticated());
  }

  /// For test fixtures only — allows switching authenticated user directly without network.
  @visibleForTesting
  void switchUser(UserModel user) {
    emit(Authenticated(user));
  }

  /// Returns the currently authenticated user, or `null`.
  UserModel? get currentUser {
    if (state is Authenticated) {
      return (state as Authenticated).user;
    }
    return null;
  }

  /// Check if the current user has one of the given [roles].
  bool hasRole(List<UserRole> roles) {
    if (state is Authenticated) {
      return roles.contains((state as Authenticated).user.role);
    }
    return false;
  }

  /// Check if the current user has a specific [permission].
  bool can(AppPermission permission) {
    if (state is! Authenticated) return false;
    final role = (state as Authenticated).user.role;

    switch (permission) {
      case AppPermission.logDowntime:
        return role == UserRole.operator ||
            role == UserRole.maintenanceSupervisor;
      case AppPermission.confirmTestRun:
        return role == UserRole.operator;
      case AppPermission.recordProcessLogs:
        return role == UserRole.operator;
      case AppPermission.assignTechnician:
        return role == UserRole.maintenanceSupervisor;
      case AppPermission.startRepair:
      case AppPermission.addSpareParts:
      case AppPermission.completeRepair:
        return role == UserRole.maintenanceTech;
      case AppPermission.reclassifyDowntime:
        return role == UserRole.productionSupervisor ||
            role == UserRole.maintenanceSupervisor;
      case AppPermission.approveAndClose:
        return role == UserRole.maintenanceSupervisor ||
            role == UserRole.productionSupervisor;
      case AppPermission.viewAnalytics:
      case AppPermission.exportReports:
        return true;
    }
  }
}
