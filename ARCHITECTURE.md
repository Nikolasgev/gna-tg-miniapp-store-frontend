# Архитектура проекта

## Общая структура

Проект следует принципам **Clean Architecture** с четким разделением на слои:

```
lib/
├── core/                    # Общие компоненты для обоих приложений
│   ├── config/             # Конфигурация окружения
│   ├── constants/          # Константы (API endpoints, storage keys)
│   ├── error/              # Обработка ошибок (Failures)
│   ├── network/            # API клиент (Dio wrapper)
│   ├── storage/             # Сервис локального хранилища
│   ├── theme/               # Тема приложения
│   └── utils/               # Утилиты (Telegram WebApp)
│
├── mini_app/                # Telegram Mini App
│   ├── presentation/        # UI слой
│   │   ├── screens/        # Экраны приложения
│   │   ├── widgets/        # Переиспользуемые виджеты
│   │   └── bloc/           # BLoC для UI логики
│   ├── domain/             # Бизнес-логика
│   │   ├── entities/      # Доменные сущности
│   │   └── repositories/   # Интерфейсы репозиториев
│   ├── data/               # Слой данных
│   │   ├── models/         # Модели данных (DTO)
│   │   ├── repositories/   # Реализация репозиториев
│   │   └── datasources/    # Источники данных (API, Local)
│   └── application/        # Use cases
│       ├── bloc/           # BLoC для бизнес-логики
│       └── services/       # Сервисы
│
└── admin_panel/            # Admin Web Panel
    └── [аналогичная структура]
```

## Слои архитектуры

### 1. Presentation Layer
- **Ответственность**: UI, взаимодействие с пользователем
- **Компоненты**: Screens, Widgets, BLoC для UI состояния
- **Зависимости**: Только от Domain слоя

### 2. Application Layer
- **Ответственность**: Use cases, бизнес-логика приложения
- **Компоненты**: BLoC для бизнес-логики, сервисы
- **Зависимости**: Domain слой

### 3. Domain Layer
- **Ответственность**: Бизнес-логика, сущности, интерфейсы
- **Компоненты**: Entities, Repository interfaces
- **Зависимости**: Нет зависимостей от других слоев

### 4. Data Layer
- **Ответственность**: Реализация репозиториев, работа с API и БД
- **Компоненты**: Models (DTO), Repository implementations, DataSources
- **Зависимости**: Domain слой, внешние библиотеки (Dio, Hive)

## State Management

Используется **BLoC (Business Logic Component)** паттерн:

- **Events** - события, которые происходят в UI
- **States** - состояния, которые отображаются в UI
- **Bloc** - логика обработки событий и генерации состояний

Пример:
```dart
// Event
class LoadProducts extends CatalogEvent {}

// State
class CatalogLoaded extends CatalogState {
  final List<Product> products;
}

// BLoC
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  // Обработка событий
}
```

## Dependency Injection

Для управления зависимостями используется **get_it**:

```dart
// Регистрация
getIt.registerSingleton<ApiClient>(ApiClient());
getIt.registerFactory<CatalogRepository>(() => CatalogRepositoryImpl());

// Использование
final repository = getIt<CatalogRepository>();
```

## Error Handling

Используется паттерн **Either** из библиотеки `dartz`:

```dart
Future<Either<Failure, List<Product>>> getProducts() async {
  try {
    final products = await apiClient.getProducts();
    return Right(products);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

## Data Flow

1. **UI** отправляет Event в BLoC
2. **BLoC** вызывает Repository
3. **Repository** обращается к DataSource (API или Local)
4. **DataSource** возвращает данные
5. **Repository** маппит данные в Domain Entity
6. **BLoC** генерирует State
7. **UI** обновляется на основе State

## Локальное хранилище

- **Hive** - для структурированных данных (корзина, кеш каталога)
- **SharedPreferences** - для простых настроек (токены, флаги)

## Сетевое взаимодействие

- **Dio** - HTTP клиент с interceptors
- **ApiClient** - обертка над Dio с обработкой ошибок
- **Retrofit** (опционально) - для генерации API клиентов

## Роутинг

Используется **go_router** для навигации:

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) => ProductScreen(
        productId: state.pathParameters['id']!,
      ),
    ),
  ],
);
```

## Тестирование

- **Unit тесты** - для BLoC и бизнес-логики
- **Widget тесты** - для UI компонентов
- **Integration тесты** - для полных сценариев

Используются библиотеки:
- `flutter_test` - базовые тесты
- `bloc_test` - тестирование BLoC
- `mockito` / `mocktail` - моки для зависимостей

