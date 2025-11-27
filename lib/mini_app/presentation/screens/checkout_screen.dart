import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/core/utils/telegram_webapp.dart';
import 'package:tg_store/core/services/business_service.dart';
import 'package:tg_store/mini_app/presentation/bloc/cart/cart_bloc.dart';
import 'package:tg_store/mini_app/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:tg_store/mini_app/presentation/navigation/app_router.dart';
import 'package:tg_store/mini_app/presentation/widgets/app_text_field.dart';
import 'package:tg_store/mini_app/presentation/widgets/address_autocomplete_field.dart';
import 'package:tg_store/mini_app/application/bloc/auth/auth_bloc.dart';
import 'package:tg_store/mini_app/domain/entities/order.dart' as entities;
import 'package:tg_store/l10n/app_localizations.dart';

// Для веб-платформы используем dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _businessSlug;

  @override
  void initState() {
    super.initState();
    logger.i('CheckoutScreen initState');
    
    // Загружаем business slug
    _loadBusinessSlug();
    
    // Sync controllers with BLoC state
    final checkoutState = context.read<CheckoutBloc>().state;
    if (checkoutState is CheckoutInitial) {
      _nameController.text = checkoutState.customerName;
      _phoneController.text = checkoutState.customerPhone;
      _addressController.text = checkoutState.customerAddress;
    }
  }

  Future<void> _loadBusinessSlug() async {
    _businessSlug = await BusinessService.getBusinessSlug() ?? 'default-business';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(CheckoutInitial checkoutState) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      logger.w('Form validation failed');
      return;
    }

    if (checkoutState.deliveryMethod == 'delivery' && checkoutState.customerAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deliveryAddressRequired),
        ),
      );
      return;
    }

    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded || cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cartIsEmpty),
        ),
      );
      return;
    }

    // Prepare order items
    final items = cartState.items.map((item) {
      return {
        'product_id': item.productId,
        'quantity': item.quantity,
        'note': item.note,
        'selected_variations': item.selectedVariations,
      };
    }).toList();

    // Submit order via CheckoutBloc
    final businessSlug = _businessSlug ?? await BusinessService.getBusinessSlug() ?? 'default-business';
    
    // Получаем user_telegram_id из AuthBloc
    // TODO: Для тестирования без Telegram нужно добавить возможность мокирования Telegram ID
    // Можно использовать SharedPreferences или константу для разработки
    // Пример: final mockTelegramId = 123456789; // Для тестов
    int? userTelegramId;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      userTelegramId = authState.user.id;
    } else {
      // TODO: В режиме разработки использовать мок ID для тестирования
      // В production это должно быть null или показывать ошибку
      userTelegramId = 123456789; // Мок ID для тестов
      logger.w('Auth not authenticated, using mock telegramId: $userTelegramId');
    }
    
    context.read<CheckoutBloc>().add(
          SubmitOrder(
            businessSlug: businessSlug,
            customerName: checkoutState.customerName,
            customerPhone: checkoutState.customerPhone,
            customerAddress: checkoutState.deliveryMethod == 'delivery' ? checkoutState.customerAddress : null,
            items: items,
            deliveryMethod: checkoutState.deliveryMethod,
            paymentMethod: checkoutState.paymentMethod,
            totalAmount: cartState.totalAmount,
            userTelegramId: userTelegramId,
          ),
        );
  }

  Future<void> _openPaymentUrl(BuildContext context, String paymentUrl, String orderId) async {
    // Используем print и debugPrint для гарантированного вывода в консоль
    print('🔵 [CHECKOUT] === Starting payment URL opening process ===');
    debugPrint('🔵 [CHECKOUT] Payment URL: $paymentUrl');
    logger.i('=== Starting payment URL opening process ===');
    logger.i('Payment URL: $paymentUrl');
    
    try {
      if (!mounted) {
        print('🔴 [CHECKOUT] Widget not mounted, aborting');
        debugPrint('🔴 [CHECKOUT] Widget not mounted, aborting payment URL opening');
        logger.w('Widget not mounted, aborting payment URL opening');
        return;
      }
      
      final uri = Uri.parse(paymentUrl);
      print('🔵 [CHECKOUT] Parsed URI: ${uri.toString()}');
      debugPrint('🔵 [CHECKOUT] URI scheme: ${uri.scheme}, host: ${uri.host}');
      logger.d('Parsed URI: ${uri.toString()}');
      logger.d('URI scheme: ${uri.scheme}');
      logger.d('URI host: ${uri.host}');
      logger.d('URI path: ${uri.path}');
      
      // Для веб-браузера используем window.open напрямую
      if (kIsWeb) {
        print('🌐 [CHECKOUT] Running in web browser, using window.open');
        debugPrint('🌐 [CHECKOUT] Opening payment URL in new window: $paymentUrl');
        logger.i('Running in web browser, using window.open');
        
        try {
          html.window.open(paymentUrl, '_blank');
          print('✅ [CHECKOUT] Payment URL opened in new browser window');
          debugPrint('✅ [CHECKOUT] Payment URL opened successfully');
          logger.i('✅ Payment URL opened in new window: $paymentUrl');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.orderCreatedSuccessfully),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                duration: const Duration(seconds: 3),
              ),
            );
            // Переходим на детальный экран заказа после успешного открытия payment URL
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                AppRouter.toOrderDetail(context, orderId);
              }
            });
          }
          return; // Успешно открыли в браузере
        } catch (webError, webStackTrace) {
          print('🔴 [CHECKOUT] Error using window.open: $webError');
          debugPrint('🔴 [CHECKOUT] window.open error: $webError');
          logger.e('Error using window.open', error: webError, stackTrace: webStackTrace);
          // Продолжаем с url_launcher как запасной вариант
        }
      }
      
      // Для Telegram Mini App используем TelegramWebApp.openLink
      if (TelegramWebApp.isAvailable) {
        print('🟢 [CHECKOUT] Telegram WebApp is available, using TelegramWebApp.openLink');
        debugPrint('🟢 [CHECKOUT] Opening payment URL via Telegram WebApp: $paymentUrl');
        logger.i('Telegram WebApp is available, using TelegramWebApp.openLink');
        
        try {
          TelegramWebApp.openLink(paymentUrl);
          print('✅ [CHECKOUT] Payment URL opened via Telegram WebApp');
          debugPrint('✅ [CHECKOUT] Payment URL opened successfully via Telegram WebApp');
          logger.i('✅ Payment URL opened via Telegram WebApp: $paymentUrl');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.orderCreatedSuccessfully),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                duration: const Duration(seconds: 3),
              ),
            );
            // Переходим на детальный экран заказа после успешного открытия payment URL
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                AppRouter.toOrderDetail(context, orderId);
              }
            });
          }
          return; // Успешно открыли через Telegram WebApp
        } catch (telegramError, telegramStackTrace) {
          print('🔴 [CHECKOUT] Error using Telegram WebApp: $telegramError');
          debugPrint('🔴 [CHECKOUT] Telegram WebApp error: $telegramError');
          logger.e('Error using Telegram WebApp', error: telegramError, stackTrace: telegramStackTrace);
          // Продолжаем с url_launcher как запасной вариант
        }
      } else {
        print('🟡 [CHECKOUT] Telegram WebApp is NOT available, using url_launcher');
        debugPrint('🟡 [CHECKOUT] Telegram WebApp is NOT available');
        logger.w('Telegram WebApp is not available, using url_launcher');
      }
      
      // Проверяем, можно ли открыть URL через url_launcher
      print('🔵 [CHECKOUT] Checking if URL can be launched with url_launcher...');
      debugPrint('🔵 [CHECKOUT] Checking canLaunchUrl...');
      logger.d('Checking if URL can be launched...');
      final canLaunch = await canLaunchUrl(uri);
      print('🔵 [CHECKOUT] canLaunchUrl result: $canLaunch');
      debugPrint('🔵 [CHECKOUT] canLaunchUrl: $canLaunch');
      logger.d('canLaunchUrl result: $canLaunch');
      
      if (!canLaunch) {
        print('🔴 [CHECKOUT] ❌ Cannot launch payment URL: $paymentUrl');
        debugPrint('🔴 [CHECKOUT] Cannot launch URL');
        logger.e('❌ Cannot launch payment URL: $paymentUrl');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.couldNotOpenPaymentPage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              AppRouter.toOrderDetail(context, orderId);
            }
          });
        }
        return;
      }
      
      // Пытаемся открыть URL через url_launcher
      // Для веб используем externalApplication, для мобильных - inAppWebView
      final launchMode = kIsWeb ? LaunchMode.externalApplication : LaunchMode.inAppWebView;
      print('🔵 [CHECKOUT] Attempting to launch URL with LaunchMode: $launchMode');
      debugPrint('🔵 [CHECKOUT] Launching URL with mode: $launchMode');
      logger.d('Attempting to launch URL with LaunchMode: $launchMode');
      try {
        final launched = kIsWeb
            ? await launchUrl(uri, mode: LaunchMode.externalApplication)
            : await launchUrl(
                uri,
                mode: LaunchMode.inAppWebView,
                webViewConfiguration: const WebViewConfiguration(
                  enableJavaScript: true,
                  enableDomStorage: true,
                ),
              );
        
        print('🔵 [CHECKOUT] launchUrl returned: $launched');
        debugPrint('🔵 [CHECKOUT] launchUrl result: $launched');
        logger.d('launchUrl returned: $launched');
        
        if (launched) {
          print('✅ [CHECKOUT] Payment URL opened successfully: $paymentUrl');
          debugPrint('✅ [CHECKOUT] Payment URL opened successfully');
          logger.i('✅ Payment URL opened successfully: $paymentUrl');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.orderCreatedSuccessfully),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                duration: const Duration(seconds: 3),
              ),
            );
            // Переходим на детальный экран заказа после успешного открытия payment URL
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                AppRouter.toOrderDetail(context, orderId);
              }
            });
          }
        } else {
          print('🔴 [CHECKOUT] ❌ launchUrl returned false');
          debugPrint('🔴 [CHECKOUT] launchUrl returned false');
          logger.e('❌ launchUrl returned false for: $paymentUrl');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.couldNotOpenPaymentPage),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                AppRouter.toOrders();
              }
            });
          }
        }
      } catch (launchError, launchStackTrace) {
        print('🔴 [CHECKOUT] ❌ Error during launchUrl call: $launchError');
        debugPrint('🔴 [CHECKOUT] launchUrl error: $launchError');
        logger.e('❌ Error during launchUrl call', error: launchError, stackTrace: launchStackTrace);
        logger.e('Error type: ${launchError.runtimeType}');
        logger.e('Error message: ${launchError.toString()}');
        
        // Пробуем альтернативный режим для веб-платформы
        print('🟡 [CHECKOUT] Trying alternative launch mode: LaunchMode.platformDefault');
        debugPrint('🟡 [CHECKOUT] Trying platformDefault mode...');
        logger.w('Trying alternative launch mode: LaunchMode.platformDefault');
        try {
          final launchedAlt = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          print('🔵 [CHECKOUT] Alternative launch returned: $launchedAlt');
          debugPrint('🔵 [CHECKOUT] Alternative launch: $launchedAlt');
          logger.d('Alternative launch returned: $launchedAlt');
          
          if (launchedAlt) {
            print('✅ [CHECKOUT] Payment URL opened with platformDefault mode');
            debugPrint('✅ [CHECKOUT] Opened with platformDefault');
            logger.i('✅ Payment URL opened with platformDefault mode');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.orderCreatedSuccessfully),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  duration: const Duration(seconds: 3),
                ),
              );
              // Переходим на экран заказов после успешного открытия payment URL
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  AppRouter.toOrders();
                }
              });
            }
          } else {
            throw launchError; // Пробрасываем исходную ошибку
          }
        } catch (altError, altStackTrace) {
          print('🔴 [CHECKOUT] ❌ Alternative launch mode also failed: $altError');
          debugPrint('🔴 [CHECKOUT] Alternative launch failed: $altError');
          logger.e('❌ Alternative launch mode also failed', error: altError, stackTrace: altStackTrace);
          rethrow; // Пробрасываем ошибку дальше
        }
      }
    } catch (e, stackTrace) {
      print('🔴🔴🔴 [CHECKOUT] CRITICAL ERROR: $e');
      debugPrint('🔴🔴🔴 [CHECKOUT] CRITICAL ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      logger.e('❌❌❌ CRITICAL ERROR opening payment URL', error: e, stackTrace: stackTrace);
      logger.e('Error type: ${e.runtimeType}');
      logger.e('Error toString: ${e.toString()}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorOpeningPaymentPage}: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            AppRouter.toOrders();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i('CheckoutScreen build');
    
    return BlocListener<CheckoutBloc, CheckoutState>(
      listener: (context, checkoutState) async {
        print('🔵 [CHECKOUT] === BlocListener triggered ===');
        debugPrint('🔵 [CHECKOUT] CheckoutState type: ${checkoutState.runtimeType}');
        logger.d('=== BlocListener triggered ===');
        logger.d('CheckoutState type: ${checkoutState.runtimeType}');
        
        if (checkoutState is CheckoutSuccess) {
          print('✅ [CHECKOUT] CheckoutSuccess state received');
          debugPrint('✅ [CHECKOUT] CheckoutSuccess received');
          logger.i('✅ CheckoutSuccess state received');
          logger.i('Order ID: ${checkoutState.order.id}');
          logger.i('User Telegram ID: ${checkoutState.order.userTelegramId}');
          logger.i('Payment URL: ${checkoutState.paymentUrl}');
          logger.i('Payment URL is null: ${checkoutState.paymentUrl == null}');
          logger.i('Payment URL is empty: ${checkoutState.paymentUrl?.isEmpty ?? true}');
          logger.i('Payment method: ${checkoutState.order.paymentMethod}');
          logger.i('Payment method enum: ${checkoutState.order.paymentMethod.runtimeType}');
          
          print('💰 [CHECKOUT] Payment URL: ${checkoutState.paymentUrl}');
          print('💰 [CHECKOUT] Payment method: ${checkoutState.order.paymentMethod}');
          debugPrint('💰 [CHECKOUT] Payment URL: ${checkoutState.paymentUrl}');
          debugPrint('💰 [CHECKOUT] Payment method: ${checkoutState.order.paymentMethod}');
          
          // Очищаем корзину сразу после создания заказа
          logger.d('Clearing cart...');
          context.read<CartBloc>().add(ClearCart());
          
          // Если есть payment URL (онлайн оплата), открываем страницу оплаты
          if (checkoutState.paymentUrl != null && checkoutState.paymentUrl!.isNotEmpty) {
            print('💰 [CHECKOUT] Online payment detected, opening payment URL');
            debugPrint('💰 [CHECKOUT] Opening payment URL: ${checkoutState.paymentUrl}');
            logger.i('💰 Online payment detected, opening payment URL');
            logger.d('Payment URL value: "${checkoutState.paymentUrl}"');
            logger.d('Payment URL length: ${checkoutState.paymentUrl!.length}');
            
            // Закрываем экран оформления заказа перед открытием оплаты
            print('🔵 [CHECKOUT] Closing checkout screen...');
            debugPrint('🔵 [CHECKOUT] Closing checkout screen');
            logger.d('Closing checkout screen...');
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
              print('✅ [CHECKOUT] Checkout screen closed');
              debugPrint('✅ [CHECKOUT] Screen closed');
              logger.d('Checkout screen closed');
            } else {
              print('🟡 [CHECKOUT] Cannot pop checkout screen - already at root');
              debugPrint('🟡 [CHECKOUT] Cannot pop screen');
              logger.w('Cannot pop checkout screen - already at root');
            }
            
            // Небольшая задержка, чтобы экран успел закрыться
            print('🔵 [CHECKOUT] Waiting 100ms before opening payment URL...');
            debugPrint('🔵 [CHECKOUT] Waiting 100ms...');
            logger.d('Waiting 100ms before opening payment URL...');
            await Future.delayed(const Duration(milliseconds: 100));
            
            // Открываем окно оплаты и ждем его открытия
            print('🔵 [CHECKOUT] Calling _openPaymentUrl...');
            debugPrint('🔵 [CHECKOUT] Calling _openPaymentUrl');
            logger.d('Calling _openPaymentUrl...');
            await _openPaymentUrl(context, checkoutState.paymentUrl!, checkoutState.order.id);
            print('✅ [CHECKOUT] _openPaymentUrl completed');
            debugPrint('✅ [CHECKOUT] _openPaymentUrl completed');
            logger.d('_openPaymentUrl completed');
            
            // Навигация на экран заказов происходит внутри _openPaymentUrl после успешного открытия payment URL
          } else if (checkoutState.order.paymentMethod == entities.PaymentMethod.online) {
            // Если выбрана онлайн оплата, но нет paymentUrl - это ошибка
            logger.e('❌ Online payment selected but no payment URL received!');
            logger.e('Payment method: ${checkoutState.order.paymentMethod}');
            logger.e('Payment URL: ${checkoutState.paymentUrl}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка: не удалось получить ссылку на оплату. Заказ создан, но оплата недоступна.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 300), () {
                AppRouter.toOrderDetail(context, checkoutState.order.id);
              });
            }
          } else {
            // Для наличной оплаты показываем успешное сообщение и переходим в историю
            logger.i('💵 Cash payment detected, navigating to orders');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.orderCreatedSuccessfully),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
            // Закрываем экран оформления заказа
            Navigator.of(context).pop();
            // Небольшая задержка перед навигацией, чтобы заказ успел сохраниться в БД
            Future.delayed(const Duration(milliseconds: 300), () {
              AppRouter.toOrderDetail(context, checkoutState.order.id);
            });
          }
        } else if (checkoutState is CheckoutError) {
          logger.e('❌ CheckoutError state received');
          logger.e('Error message: ${checkoutState.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.orderCreationError(checkoutState.message)),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (checkoutState is CheckoutLoading) {
          logger.d('⏳ CheckoutLoading state received');
        } else {
          logger.d('ℹ️ Other checkout state: ${checkoutState.runtimeType}');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.checkout),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
          if (cartState is! CartLoaded || cartState.items.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.cartIsEmpty),
            );
          }

          return BlocBuilder<CheckoutBloc, CheckoutState>(
            builder: (context, checkoutState) {
              final formState = checkoutState is CheckoutInitial 
                  ? checkoutState 
                  : const CheckoutInitial();
              
              // Sync controllers with BLoC state
              if (_nameController.text != formState.customerName) {
                _nameController.text = formState.customerName;
              }
              if (_phoneController.text != formState.customerPhone) {
                _phoneController.text = formState.customerPhone;
              }
              if (_addressController.text != formState.customerAddress) {
                _addressController.text = formState.customerAddress;
              }

              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                    // Customer info
                    Text(
                      AppLocalizations.of(context)!.contactInfo,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _nameController,
                      labelText: AppLocalizations.of(context)!.name,
                      prefixIcon: Icons.person,
                      height: 56,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.enterName;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        context.read<CheckoutBloc>().add(UpdateCustomerName(value));
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _phoneController,
                      labelText: AppLocalizations.of(context)!.phone,
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      height: 56,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.enterPhone;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        context.read<CheckoutBloc>().add(UpdateCustomerPhone(value));
                      },
                    ),
                    const SizedBox(height: 24),
                    // Delivery method
                    Text(
                      AppLocalizations.of(context)!.deliveryMethodSection,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                            RadioListTile<String>(
                              title: Text(AppLocalizations.of(context)!.pickup),
                              value: 'pickup',
                              groupValue: formState.deliveryMethod,
                              onChanged: (value) {
                                if (value != null) {
                                  context.read<CheckoutBloc>().add(UpdateDeliveryMethod(value));
                                }
                              },
                            ),
                            RadioListTile<String>(
                              title: Text(AppLocalizations.of(context)!.delivery),
                              value: 'delivery',
                              groupValue: formState.deliveryMethod,
                              onChanged: (value) {
                                if (value != null) {
                                  context.read<CheckoutBloc>().add(UpdateDeliveryMethod(value));
                                  
                                  // Если выбрана доставка и адрес уже указан, рассчитываем стоимость
                                  if (value == 'delivery' && formState.customerAddress.isNotEmpty) {
                                    final cartState = context.read<CartBloc>().state;
                                    if (cartState is CartLoaded && cartState.items.isNotEmpty) {
                                      final items = cartState.items.map((item) {
                                        return {
                                          'quantity': item.quantity,
                                          'weight': 0.1,
                                          'size': {
                                            'length': 0.05,
                                            'width': 0.05,
                                            'height': 0.05,
                                          },
                                        };
                                      }).toList();
                                      
                                      context.read<CheckoutBloc>().add(
                                        CalculateDeliveryCost(
                                          customerAddress: formState.customerAddress,
                                          items: items,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                    if (formState.deliveryMethod == 'delivery') ...[
                      const SizedBox(height: 16),
                      AddressAutocompleteField(
                        controller: _addressController,
                        labelText: AppLocalizations.of(context)!.deliveryAddress,
                        prefixIcon: Icons.location_on,
                        maxLines: 2,
                        validator: (value) {
                          if (formState.deliveryMethod == 'delivery' &&
                              (value == null || value.isEmpty)) {
                            return AppLocalizations.of(context)!.enterDeliveryAddress;
                          }
                          return null;
                        },
                        onAddressSelected: (address) {
                          // Вызывается только при выборе адреса из подсказок
                          context.read<CheckoutBloc>().add(UpdateCustomerAddress(address));
                          
                          // Рассчитываем стоимость доставки только после выбора адреса
                          final cartState = context.read<CartBloc>().state;
                          if (cartState is CartLoaded && cartState.items.isNotEmpty) {
                            final items = cartState.items.map((item) {
                              return {
                                'quantity': item.quantity,
                                'weight': 0.1, // Минимальный вес для снижения стоимости
                                'size': {
                                  'length': 0.05,
                                  'width': 0.05,
                                  'height': 0.05,
                                },
                              };
                            }).toList();
                            
                            context.read<CheckoutBloc>().add(
                              CalculateDeliveryCost(
                                customerAddress: address,
                                items: items,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Payment method
                    Text(
                      AppLocalizations.of(context)!.paymentMethod,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<String>(
                      title: Text(AppLocalizations.of(context)!.cash),
                      value: 'cash',
                      groupValue: formState.paymentMethod,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<CheckoutBloc>().add(UpdatePaymentMethod(value));
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(AppLocalizations.of(context)!.online),
                      value: 'online',
                      groupValue: formState.paymentMethod,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<CheckoutBloc>().add(UpdatePaymentMethod(value));
                        }
                      },
                    ),
                        ],
                      ),
                    ),
                    // Total and checkout button (same style as cart)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow,
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Стоимость товаров
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.subtotal,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                '${cartState.totalAmount.toStringAsFixed(0)} ₽',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          // Стоимость доставки (если выбрана доставка)
                          BlocBuilder<CheckoutBloc, CheckoutState>(
                            builder: (context, checkoutState) {
                              final formState = checkoutState is CheckoutInitial 
                                  ? checkoutState 
                                  : const CheckoutInitial();
                              
                              if (formState.deliveryMethod == 'delivery') {
                                return Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    if (formState.isCalculatingDelivery)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!.delivery,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ],
                                      )
                                    else if (formState.deliveryCost != null)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!.delivery,
                                            style: Theme.of(context).textTheme.bodyLarge,
                                          ),
                                          Text(
                                            '${formState.deliveryCost!.toStringAsFixed(0)} ₽',
                                            style: Theme.of(context).textTheme.bodyLarge,
                                          ),
                                        ],
                                      )
                                    else if (formState.customerAddress.isNotEmpty)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!.delivery,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.error,
                                                ),
                                          ),
                                          Text(
                                            AppLocalizations.of(context)!.notAvailable,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.error,
                                                ),
                                          ),
                                        ],
                                      ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const Divider(height: 24),
                          // Итоговая сумма
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${AppLocalizations.of(context)!.total}:',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              BlocBuilder<CheckoutBloc, CheckoutState>(
                                builder: (context, checkoutState) {
                                  final formState = checkoutState is CheckoutInitial 
                                      ? checkoutState 
                                      : const CheckoutInitial();
                                  
                                  final deliveryCost = formState.deliveryMethod == 'delivery' 
                                      ? (formState.deliveryCost ?? 0.0)
                                      : 0.0;
                                  final totalAmount = cartState.totalAmount + deliveryCost;
                                  
                                  return Text(
                                    '${totalAmount.toStringAsFixed(0)} ₽',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          BlocBuilder<CheckoutBloc, CheckoutState>(
                            builder: (context, submitState) {
                              final isLoading = submitState is CheckoutLoading;
                              final formState = submitState is CheckoutInitial 
                                  ? submitState 
                                  : const CheckoutInitial();
                              
                              return SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: isLoading ? null : () => _submitOrder(formState),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Text(AppLocalizations.of(context)!.placeOrder),
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
          },
        ),
      ),
    );
  }
}

