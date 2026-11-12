import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../../data/datasources/remote/mock_employee_data.dart';

class DioClient {
  static Dio? _dio;

  /// Global toggle to test network failures and offline SQLite sync
  static bool simulateOffline = false;

  static Dio get dio {
    if (_dio != null) return _dio!;

    final options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Content-Type': 'application/json'},
    );

    _dio = Dio(options);
    _dio!.interceptors.add(_MockDioInterceptor());

    return _dio!;
  }
}

class _MockDioInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Simulate Network Latency
    await Future.delayed(const Duration(milliseconds: 400));

    // 2. Simulate Offline / Network Failure if toggled
    if (DioClient.simulateOffline) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'No internet connection. Simulated network failure.',
          type: DioExceptionType.connectionError,
        ),
      );
    }

    final path = options.path;

    // --- Endpoint 1: POST /auth/login ---
    if (path.contains(AppConstants.endpointLogin) && options.method == 'POST') {
      final body = options.data is String
          ? jsonDecode(options.data)
          : options.data as Map<String, dynamic>;

      final email = (body['email'] ?? '').toString().trim().toLowerCase();
      final password = (body['password'] ?? '').toString();

      final user = MockEmployeeData.dummyEmployees.firstWhere(
        (u) =>
            u['email'].toString().toLowerCase() == email &&
            u['password'] == password,
        orElse: () => {},
      );

      if (user.isNotEmpty) {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'token': 'mock-jwt-token-${user['id']}-${DateTime.now().millisecondsSinceEpoch}',
              'user': {
                'id': user['id'],
                'name': user['name'],
                'email': user['email'],
                'role': user['role'],
              },
            },
          ),
        );
      } else {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'success': false, 'message': 'Invalid email or password'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      }
    }

    // --- Endpoint 2: POST /attendance/mark ---
    if (path.contains(AppConstants.endpointAttendanceMark) && options.method == 'POST') {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Attendance registered on server successfully',
          },
        ),
      );
    }

    // Default passthrough
    super.onRequest(options, handler);
  }
}