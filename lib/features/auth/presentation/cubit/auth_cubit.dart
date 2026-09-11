import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'auth_state.dart';
import '../../domain/models/user_model.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/enums/app_permission.dart';
import '../../data/mock_users.dart';
import '../../../../core/database/hive_boxes.dart';

class AuthCubit extends Cubit<AuthState> {
  static const String _activeUserKey = 'active_user_id';

  AuthCubit() : super(AuthInitial()) {
    initAuth();
  }

  void initAuth() {
    try {
      final box = Hive.box(HiveBoxes.settingsBox);
      final savedId = box.get(_activeUserKey) as String?;
      if (savedId != null) {
        final user = MockUsers.allMockUsers.firstWhere(
          (u) => u.id == savedId,
          orElse: () => MockUsers.maintenanceSupervisor,
        );
        emit(Authenticated(user));
        return;
      }
    } catch (_) {
      // If box not ready yet or error, fallback to default mock user
    }
    emit(const Authenticated(MockUsers.maintenanceSupervisor));
  }

  UserModel? get currentUser {
    if (state is Authenticated) {
      return (state as Authenticated).user;
    }
    return null;
  }

  void switchUser(UserModel user) {
    try {
      final box = Hive.box(HiveBoxes.settingsBox);
      box.put(_activeUserKey, user.id);
    } catch (_) {}
    emit(Authenticated(user));
  }

  void login(String email) {
    final user = MockUsers.allMockUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => MockUsers.operatorUser,
    );
    switchUser(user);
  }

  void logout() {
    try {
      final box = Hive.box(HiveBoxes.settingsBox);
      box.delete(_activeUserKey);
    } catch (_) {}
    emit(Unauthenticated());
  }

  bool hasRole(List<UserRole> roles) {
    if (state is Authenticated) {
      return roles.contains((state as Authenticated).user.role);
    }
    return false;
  }

  bool can(AppPermission permission) {
    if (state is! Authenticated) return false;
    final role = (state as Authenticated).user.role;

    switch (permission) {
      case AppPermission.logDowntime:
        return role == UserRole.operator || role == UserRole.maintenanceSupervisor;
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
        return role == UserRole.productionSupervisor || role == UserRole.maintenanceSupervisor;
      case AppPermission.approveAndClose:
        return role == UserRole.maintenanceSupervisor || role == UserRole.productionSupervisor;
      case AppPermission.viewAnalytics:
      case AppPermission.exportReports:
        return true;
    }
  }
}
