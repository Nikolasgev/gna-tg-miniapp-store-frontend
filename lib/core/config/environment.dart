enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  static Environment _environment = Environment.development;
  static String _baseUrl = '';

  static Environment get environment => _environment;
  static String get baseUrl => _baseUrl;

  static void setEnvironment(Environment env) {
    _environment = env;
    switch (env) {
      case Environment.development:
        // Для Telegram WebView нужно использовать IP-адрес вместо localhost
        // Можно переопределить через переменную окружения API_BASE_URL
        final apiBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
        if (apiBaseUrl.isNotEmpty) {
          _baseUrl = apiBaseUrl;
        } else {
          // По умолчанию используем IP-адрес для Telegram WebView (localhost не работает)
          // Для изменения IP-адреса используйте: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:8000
          // Или установите переменную окружения API_BASE_URL
          _baseUrl = 'http://192.168.31.173:8000';
        }
        break;
      case Environment.staging:
        _baseUrl = 'https://api-staging.example.com';
        break;
      case Environment.production:
        _baseUrl = 'https://api.example.com';
        break;
    }
  }

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;
}

