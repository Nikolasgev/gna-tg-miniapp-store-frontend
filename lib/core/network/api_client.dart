import 'package:dio/dio.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/utils/logger.dart' show logger;

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    // Проверяем, что baseUrl установлен
    final baseUrl = AppConfig.baseUrl;
    if (baseUrl.isEmpty) {
      throw StateError('AppConfig.baseUrl не установлен. Вызовите AppConfig.setEnvironment() перед использованием ApiClient.');
    }

    logger.i('ApiClient initializing with baseUrl: $baseUrl');

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          final token = _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // Log requests in development
          if (AppConfig.isDevelopment) {
            logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
            logger.d('Headers: ${options.headers}');
            if (options.data != null) {
              logger.d('Data: ${options.data}');
            }
          }
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (AppConfig.isDevelopment) {
            logger.d('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
            // Для 204 No Content ответа data может быть null
            if (response.statusCode == 204) {
              logger.d('Data: (No Content)');
            } else {
              logger.d('Data: ${response.data}');
            }
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (AppConfig.isDevelopment) {
            logger.e('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
            logger.e('Full URL: ${error.requestOptions.uri}');
            logger.e('Error type: ${error.type}');
            logger.e('Message: ${error.message}');
            if (error.response != null) {
              logger.e('Response data: ${error.response?.data}');
            }
            if (error.type == DioExceptionType.connectionError) {
              logger.w('Connection error - проверьте, что бэкенд запущен на ${error.requestOptions.baseUrl}');
              logger.w('   Попробуйте: cd backend && docker-compose up -d');
            }
          }
          
          // Handle 401/403 errors
          if (error.response?.statusCode == 401) {
            _handleUnauthorized();
          } else if (error.response?.statusCode == 403) {
            _handleForbidden();
          }
          
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  String? _getAuthToken() {
    // TODO: Get token from storage (shared_preferences or secure storage)
    return null;
  }

  void _handleUnauthorized() {
    // TODO: Handle unauthorized - clear token, navigate to login
  }

  void _handleForbidden() {
    // TODO: Handle forbidden - show error message
  }
}

