import 'package:dio/dio.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/network/api_client.dart';

class AdminAuthRepository {
  final ApiClient _apiClient;

  AdminAuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Проверка пароля администратора
  /// Возвращает true если пароль верный, false если неверный
  /// Выбрасывает исключение при ошибке сети
  Future<bool> verifyPassword(String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.adminLogin,
        data: {'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['ok'] == true;
      }

      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Неверный пароль
        return false;
      }
      // Другая ошибка сети
      rethrow;
    }
  }
}

