import '../models/user_model.dart';

/// Abstract contract for authentication operations.
///
/// Implementations may use Supabase, Firebase, or mock data sources.
abstract class AuthRepository {
  /// Authenticates a user with email and password.
  ///
  /// Throws:
  /// - [InvalidCredentialsException] if the credentials are wrong.
  /// - [NetworkException] if the server is unreachable.
  /// - [ProfileNotFoundException] if the user has no profile row.
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  /// Fetches the user profile from `public.user_profiles` by [userId].
  ///
  /// Throws [ProfileNotFoundException] if no row matches the given ID.
  Future<UserModel> getUserProfile(String userId);

  /// Signs the current user out and clears the session.
  Future<void> signOut();

  /// Returns the currently cached user, or `null` if not authenticated.
  UserModel? get cachedUser;

  /// Fetches all users with the given [role] from `public.user_profiles`.
  ///
  /// Used to load real technician lists for assignment dialogs.
  /// Pass [speciality] to filter by speciality field (e.g. 'Electrical').
  Future<List<UserModel>> getUsersByRole(
    String role, {
    String? speciality,
  });

  /// Synchronously returns locally cached users with the given [role] from Hive.
  List<UserModel> getLocalUsersByRole(
    String role, {
    String? speciality,
  });
}
