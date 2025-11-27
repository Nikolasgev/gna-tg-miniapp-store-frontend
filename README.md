# Telegram Mini App Builder - Flutter Frontend

Flutter Web приложение, состоящее из двух частей:
1. **Telegram Mini App** - клиентское приложение для покупателей
2. **Admin Web Panel** - административная панель для владельцев бизнеса

## Структура проекта

```
lib/
├── core/                    # Общие компоненты
│   ├── config/             # Конфигурация (environment, constants)
│   ├── constants/          # Константы приложения
│   ├── error/              # Обработка ошибок
│   ├── network/             # API клиент
│   ├── theme/               # Тема приложения
│   └── utils/               # Утилиты (Telegram WebApp)
│
├── mini_app/                # Telegram Mini App
│   ├── presentation/       # UI слой (screens, widgets, bloc)
│   ├── domain/             # Бизнес-логика (entities, repositories)
│   ├── data/               # Данные (models, repositories, datasources)
│   └── application/        # Use cases (bloc, services)
│
├── admin_panel/             # Admin Web Panel
│   ├── presentation/       # UI слой
│   ├── domain/             # Бизнес-логика
│   ├── data/               # Данные
│   └── application/        # Use cases
│
├── mini_app/main.dart       # Entry point для Mini App
└── admin_panel/main.dart    # Entry point для Admin Panel
```

## Технологический стек

- **Flutter** (Web)
- **State Management**: `flutter_bloc`
- **HTTP Client**: `dio`
- **Local Storage**: `hive`, `shared_preferences`
- **Routing**: `go_router`
- **Internationalization**: `intl`, `flutter_localizations`
- **Firebase**: `firebase_core`, `firebase_auth` (для Admin Panel)

## Установка и запуск

### Предварительные требования

- Flutter SDK (последняя LTS-совместимая версия)
- Dart SDK

### Установка зависимостей

```bash
flutter pub get
```

### Запуск Mini App

```bash
flutter run -d chrome --target lib/mini_app/main.dart
```

Или для production build:

```bash
flutter build web --target lib/mini_app/main.dart --release
```

### Запуск Admin Panel

```bash
flutter run -d chrome --target lib/admin_panel/main.dart
```

Или для production build:

```bash
flutter build web --target lib/admin_panel/main.dart --release
```

## Конфигурация

### Environment

Настройка окружения происходит в файле `lib/core/config/environment.dart`:

```dart
AppConfig.setEnvironment(Environment.development);
```

Доступные окружения:
- `Environment.development` - локальная разработка
- `Environment.staging` - тестовый сервер
- `Environment.production` - продакшн

### API Base URL

URL API настраивается автоматически в зависимости от выбранного окружения. Для изменения URL отредактируйте `AppConfig.setEnvironment()`.

## Архитектура

Проект следует принципам **Clean Architecture** с разделением на слои:

1. **Presentation** - UI компоненты, BLoC, виджеты
2. **Application** - Use cases, сервисы, бизнес-логика
3. **Domain** - Сущности, интерфейсы репозиториев
4. **Data** - Реализация репозиториев, модели данных, API клиенты

## Основные компоненты

### Mini App

- **AuthBloc** - управление авторизацией через Telegram init_data
- **CartBloc** - управление корзиной покупок
- **CatalogBloc** - загрузка каталога товаров
- **OrderBloc** - создание и отслеживание заказов

### Admin Panel

- **AuthBloc** - авторизация через Firebase
- **ProductsBloc** - управление товарами
- **OrdersBloc** - управление заказами
- **SettingsBloc** - настройки бизнеса

## Разработка

### Генерация кода

Для генерации кода из аннотаций (freezed, json_serializable, etc.):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Тестирование

```bash
# Unit тесты
flutter test

# Widget тесты
flutter test test/widget_test.dart

# Integration тесты
flutter test integration_test/
```

## Следующие шаги

1. Реализовать репозитории в `data` слое
2. Создать модели данных с json_serializable
3. Реализовать экраны Mini App (Каталог, Корзина, Checkout)
4. Реализовать экраны Admin Panel (Login, Products, Orders)
5. Настроить роутинг с go_router
6. Добавить локализацию (i18n)
7. Настроить Hive адаптеры для локального хранилища
8. Реализовать интеграцию с Telegram WebApp API

## Документация

- [Backend ТЗ](../backend/tz_back.md)
- [Frontend ТЗ](tz_front.md)
