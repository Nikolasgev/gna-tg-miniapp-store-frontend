import 'package:logger/logger.dart';

/// Глобальный экземпляр логгера для использования во всем приложении
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // Количество методов в стек-трейсе
    errorMethodCount: 8, // Количество методов в стек-трейсе для ошибок
    lineLength: 120, // Длина строки
    colors: true, // Цветной вывод
    printEmojis: true, // Эмодзи в логах
    printTime: true, // Время в логах
  ),
  level: Level.debug, // Уровень логирования (debug, info, warning, error)
);

/// Упрощенный логгер для production (без деталей)
final productionLogger = Logger(
  printer: SimplePrinter(
    colors: false,
    printTime: true,
  ),
  level: Level.warning, // В production только warning и error
);

/// Получить логгер в зависимости от режима
Logger get logger {
  // В production используем упрощенный логгер
  // В debug используем детальный
  return appLogger;
}
