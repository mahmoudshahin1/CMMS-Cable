import 'package:orning_and_evening_remembrances/features/auth/domain/models/user_model.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/repositories/auth_repository.dart';
import 'package:orning_and_evening_remembrances/features/auth/data/mock_users.dart';

/// A fake [AuthRepository] for use in unit/widget tests.
///
/// Bypasses Supabase entirely — [signIn] always returns a user matched by
/// email from [MockUsers], and [signOut] is a no-op.
class FakeAuthRepository implements AuthRepository {
  UserModel? _cachedUser;

  FakeAuthRepository() : _cachedUser = MockUsers.maintenanceSupervisor;

  @override
  UserModel? get cachedUser => _cachedUser;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final user = MockUsers.allMockUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => MockUsers.maintenanceSupervisor,
    );
    _cachedUser = user;
    return user;
  }

  @override
  Future<UserModel> getUserProfile(String userId) async {
    final user = MockUsers.findById(userId);
    _cachedUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    _cachedUser = null;
  }

  @override
  Future<List<UserModel>> getUsersByRole(
    String role, {
    String? speciality,
  }) async {
    return MockUsers.getTechnicians(speciality: speciality);
  }
}
