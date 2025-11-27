# Инструкция по настройке и запуску

## Быстрый старт

### 1. Установка зависимостей

```bash
cd frontend
flutter pub get
```

### 2. Запуск Mini App

```bash
# Development режим
flutter run -d chrome --target lib/mini_app/main.dart

# Или с указанием порта
flutter run -d chrome --target lib/mini_app/main.dart --web-port=8080
```

### 3. Запуск Admin Panel

```bash
# Development режим
flutter run -d chrome --target lib/admin_panel/main.dart

# Или с указанием порта
flutter run -d chrome --target lib/admin_panel/main.dart --web-port=8081
```

## Сборка для production

### Mini App

```bash
flutter build web --target lib/mini_app/main.dart --release
```

Результат будет в `build/web/`

### Admin Panel

```bash
flutter build web --target lib/admin_panel/main.dart --release
```

## Настройка окружения

Отредактируйте `lib/core/config/environment.dart` для изменения базового URL API:

```dart
AppConfig.setEnvironment(Environment.development);
```

## Структура проекта

### Созданные компоненты

#### Core (общие)
- ✅ Конфигурация окружения
- ✅ API константы и клиент
- ✅ Обработка ошибок
- ✅ Тема приложения
- ✅ Утилиты для Telegram WebApp
- ✅ Сервис локального хранилища

#### Mini App
- ✅ Entry point (`main.dart`)
- ✅ Базовые экраны (Initialization, Catalog)
- ✅ Domain entities (Product, Category, Order, CartItem, BusinessConfig)
- ✅ Repository interfaces (Auth, Catalog, Order)
- ✅ BLoC (Auth, Cart)

#### Admin Panel
- ✅ Entry point (`main.dart`)
- ✅ Экран логина
- ✅ Базовая структура

## Следующие шаги разработки

### 1. Реализация репозиториев

Создать реализации в `data/repositories/`:
- `AuthRepositoryImpl`
- `CatalogRepositoryImpl`
- `OrderRepositoryImpl`

### 2. Создание моделей данных

Создать DTO модели в `data/models/` с `json_serializable`:
- `ProductModel`
- `CategoryModel`
- `OrderModel`

### 3. Настройка Dependency Injection

Использовать `get_it` для регистрации зависимостей:
- API клиент
- Репозитории
- BLoC

### 4. Реализация экранов Mini App

- ✅ Initialization Screen
- ✅ Catalog Screen (базовый)
- ⏳ Product Detail Screen
- ⏳ Cart Screen
- ⏳ Checkout Screen
- ⏳ Orders History Screen

### 5. Реализация экранов Admin Panel

- ✅ Login Screen
- ⏳ Dashboard
- ⏳ Products Management
- ⏳ Orders Management
- ⏳ Categories Management
- ⏳ Settings

### 6. Настройка роутинга

Использовать `go_router` для навигации в обоих приложениях.

### 7. Локализация

Добавить файлы локализации (`.arb`) и настроить `flutter_localizations`.

### 8. Hive адаптеры

Создать TypeAdapters для:
- CartItem
- Product (для кеша)
- BusinessConfig

### 9. Интеграция с Firebase

Настроить Firebase для Admin Panel:
- Добавить `firebase_options.dart`
- Настроить Firebase Auth

### 10. Тестирование

Создать тесты:
- Unit тесты для BLoC
- Widget тесты для экранов
- Integration тесты для основных сценариев

## Полезные команды

### Генерация кода

```bash
# Генерация для freezed, json_serializable, etc.
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode для автоматической генерации
flutter pub run build_runner watch
```

### Анализ кода

```bash
flutter analyze
```

### Форматирование

```bash
flutter format lib/
```

### Тестирование

```bash
# Все тесты
flutter test

# Конкретный тест
flutter test test/widget_test.dart
```

## Troubleshooting

### Проблемы с зависимостями

```bash
flutter clean
flutter pub get
```

### Проблемы с Web сборкой

```bash
flutter clean
flutter pub get
flutter build web --target lib/mini_app/main.dart
```

### Проблемы с Firebase

Убедитесь, что:
1. Firebase проект создан
2. `firebase_options.dart` сгенерирован
3. Firebase инициализирован в `main.dart`

