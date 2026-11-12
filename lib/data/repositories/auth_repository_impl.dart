import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio dio;
  UserEntity? _currentUser;

  AuthRepositoryImpl({Dio? dioClient}) : dio = dioClient ?? DioClient.dio;

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final response = await dio.post(
        AppConstants.endpointLogin,
        data: {'email': email, 'password': password},
      );

      final userData = response.data['user'] as Map<String, dynamic>;
      final token = response.data['token'] as String?;

      final user = UserModel.fromJson({
        ...userData,
        'token': token,
      });

      _currentUser = user;
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthFailure('Invalid email or password.');
      } else if (e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkFailure('Cannot reach server. Check internet connection.');
      }
      throw ServerFailure(e.message ?? 'Authentication service failed.');
    } catch (e) {
      if (e is Failure) rethrow;
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}