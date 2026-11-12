import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Authenticates with email and password via mock REST API
  Future<UserEntity> login(String email, String password);

  /// Retrieves the currently cached/logged-in user session
  Future<UserEntity?> getCurrentUser();

  /// Logs out the user and clears session
  Future<void> logout();
}