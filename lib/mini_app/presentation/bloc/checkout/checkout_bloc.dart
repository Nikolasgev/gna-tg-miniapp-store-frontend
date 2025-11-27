import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/mini_app/domain/entities/order.dart' as entities;
import 'package:tg_store/mini_app/domain/repositories/order_repository.dart';
import 'package:dio/dio.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final OrderRepository orderRepository;
  final ApiClient _apiClient = ApiClient();

  CheckoutBloc({required this.orderRepository}) : super(const CheckoutInitial()) {
    on<SubmitOrder>(_onSubmitOrder);
    on<ResetCheckout>(_onResetCheckout);
    on<UpdateCustomerName>(_onUpdateCustomerName);
    on<UpdateCustomerPhone>(_onUpdateCustomerPhone);
    on<UpdateCustomerAddress>(_onUpdateCustomerAddress);
    on<UpdateDeliveryMethod>(_onUpdateDeliveryMethod);
    on<UpdatePaymentMethod>(_onUpdatePaymentMethod);
    on<CalculateDeliveryCost>(_onCalculateDeliveryCost);
  }

  Future<void> _onSubmitOrder(
    SubmitOrder event,
    Emitter<CheckoutState> emit,
  ) async {
    logger.i('SubmitOrder event received');
    emit(CheckoutLoading());
    
    try {
      logger.d('Creating order with data:');
      logger.d('  Name: ${event.customerName}');
      logger.d('  Phone: ${event.customerPhone}');
      logger.d('  Address: ${event.customerAddress}');
      logger.d('  Delivery: ${event.deliveryMethod}');
      logger.d('  Payment: ${event.paymentMethod}');
      logger.d('  Items: ${event.items.length}');
      logger.d('  User Telegram ID: ${event.userTelegramId}');
      
      // Вызываем реальный API
      final result = await orderRepository.createOrder(
        businessSlug: event.businessSlug,
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        customerAddress: event.customerAddress,
        items: event.items,
        paymentMethod: event.paymentMethod,
        userTelegramId: event.userTelegramId,
      );
      
      result.fold(
        (failure) {
          logger.e('❌ Failed to create order: ${failure.message}');
          emit(CheckoutError(failure.message));
        },
        (order) {
          logger.i('✅ Order created successfully: ${order.id}');
          logger.d('Order payment method: ${order.paymentMethod}');
          logger.d('Order metadata: ${order.metadata}');
          logger.d('Order metadata is null: ${order.metadata == null}');
          
          // Извлекаем payment_url из metadata, если он есть
          String? paymentUrl;
          if (order.metadata != null) {
            logger.d('Order metadata keys: ${order.metadata!.keys.toList()}');
            logger.d('Order metadata contains payment_url: ${order.metadata!.containsKey('payment_url')}');
            
            if (order.metadata!.containsKey('payment_url')) {
              paymentUrl = order.metadata!['payment_url'] as String?;
              logger.i('💰 Payment URL extracted from metadata: $paymentUrl');
              logger.d('Payment URL type: ${paymentUrl.runtimeType}');
              logger.d('Payment URL is null: ${paymentUrl == null}');
              logger.d('Payment URL is empty: ${paymentUrl?.isEmpty ?? true}');
            } else {
              logger.w('⚠️ Order metadata does not contain payment_url key');
              logger.d('Available metadata keys: ${order.metadata!.keys.toList()}');
            }
          } else {
            logger.w('⚠️ Order metadata is null');
          }
          
          logger.d('Emitting CheckoutSuccess with paymentUrl: $paymentUrl');
          emit(CheckoutSuccess(order, paymentUrl: paymentUrl));
          logger.d('CheckoutSuccess state emitted');
        },
      );
    } catch (e) {
      logger.e('Error creating order', error: e);
      emit(CheckoutError('Ошибка при создании заказа: $e'));
    }
  }

  void _onResetCheckout(ResetCheckout event, Emitter<CheckoutState> emit) {
    logger.i('ResetCheckout event received');
    emit(const CheckoutInitial());
  }

  void _onUpdateCustomerName(UpdateCustomerName event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      emit(CheckoutInitial(
        customerName: event.name,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
      ));
    }
  }

  void _onUpdateCustomerPhone(UpdateCustomerPhone event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: event.phone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
      ));
    }
  }

  void _onUpdateCustomerAddress(UpdateCustomerAddress event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      // Обновляем адрес, но НЕ рассчитываем доставку автоматически
      // Расчет будет происходить только при выборе адреса из подсказок
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: event.address,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: null, // Сбрасываем стоимость доставки при изменении адреса
        isCalculatingDelivery: false,
      ));
    }
  }

  void _onUpdateDeliveryMethod(UpdateDeliveryMethod event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      final newState = CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: event.method,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: event.method == 'pickup' ? null : currentState.deliveryCost,
        isCalculatingDelivery: false,
      );
      emit(newState);
      
      // Если выбрана доставка и адрес указан, рассчитываем стоимость
      if (event.method == 'delivery' && currentState.customerAddress.isNotEmpty) {
        add(CalculateDeliveryCost(
          customerAddress: currentState.customerAddress,
          items: [],
        ));
      }
    }
  }

  void _onUpdatePaymentMethod(UpdatePaymentMethod event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: event.method,
        deliveryCost: currentState.deliveryCost,
        isCalculatingDelivery: currentState.isCalculatingDelivery,
      ));
    }
  }

  Future<void> _onCalculateDeliveryCost(
    CalculateDeliveryCost event,
    Emitter<CheckoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CheckoutInitial) return;
    
    // Если адрес пустой или выбрана самовывоз, не рассчитываем
    if (event.customerAddress.isEmpty || currentState.deliveryMethod != 'delivery') {
      return;
    }
    
    logger.i('Calculating delivery cost for address: ${event.customerAddress}');
    
    // Устанавливаем флаг расчета
    emit(CheckoutInitial(
      customerName: currentState.customerName,
      customerPhone: currentState.customerPhone,
      customerAddress: currentState.customerAddress,
      deliveryMethod: currentState.deliveryMethod,
      paymentMethod: currentState.paymentMethod,
      deliveryCost: currentState.deliveryCost,
      isCalculatingDelivery: true,
    ));
    
    try {
      // Адрес отправления (из настроек бэкенда)
      final fromAddress = {
        "fullname": "Москва, 1-й проезд Марьиной Рощи, дом 7/9",
        "coordinates": [37.6000, 55.8000],
        "city": "Москва",
        "country": "Россия",
        "street": "1-й проезд Марьиной Рощи",
      };
      
      // Адрес назначения (адрес клиента)
      // Используем примерные координаты, так как геокодер требует API ключ
      final toAddress = {
        "fullname": event.customerAddress,
        "coordinates": [37.6173, 55.7558], // Примерные координаты (центр Москвы)
        "city": "Москва",
        "country": "Россия",
        "street": event.customerAddress,
      };
      
      // Подготавливаем товары для расчета
      // Если товары не переданы, используем примерные значения (1 товар, 0.5 кг)
      final items = event.items.isNotEmpty
          ? event.items.map((item) {
              return {
                "quantity": item['quantity'] ?? 1,
                "weight": (item['weight'] ?? 0.1).toDouble(), // Минимальный вес
                "size": item['size'] ?? {
                  "length": 0.05,
                  "width": 0.05,
                  "height": 0.05,
                },
              };
            }).toList()
          : [
              {
                "quantity": 1,
                "weight": 0.1, // Минимальный вес для снижения стоимости
                "size": {
                  "length": 0.05,
                  "width": 0.05,
                  "height": 0.05,
                },
              }
            ];
      
      logger.d('Calculating delivery with ${items.length} items');
      
      // Вызываем API расчета доставки
      final response = await _apiClient.dio.post(
        ApiConstants.calculateDeliveryCost(),
        data: {
          "from_address": fromAddress,
          "to_address": toAddress,
          "items": items,
          "taxi_classes": ["courier"],
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final offers = data['offers'] as List?;
        
        if (offers != null && offers.isNotEmpty) {
          final firstOffer = offers[0] as Map<String, dynamic>;
          final price = firstOffer['price'] as Map<String, dynamic>;
          final totalPrice = price['total_price_with_vat'] ?? price['total_price'];
          final deliveryCost = double.tryParse(totalPrice.toString()) ?? 0.0;
          
          logger.i('✅ Delivery cost calculated: $deliveryCost RUB');
          
          emit(CheckoutInitial(
            customerName: currentState.customerName,
            customerPhone: currentState.customerPhone,
            customerAddress: currentState.customerAddress,
            deliveryMethod: currentState.deliveryMethod,
            paymentMethod: currentState.paymentMethod,
            deliveryCost: deliveryCost,
            isCalculatingDelivery: false,
          ));
        } else {
          logger.w('⚠️ No delivery offers found');
          emit(CheckoutInitial(
            customerName: currentState.customerName,
            customerPhone: currentState.customerPhone,
            customerAddress: currentState.customerAddress,
            deliveryMethod: currentState.deliveryMethod,
            paymentMethod: currentState.paymentMethod,
            deliveryCost: null,
            isCalculatingDelivery: false,
          ));
        }
      } else {
        throw Exception('Failed to calculate delivery cost: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logger.e('Error calculating delivery cost', error: e);
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: null,
        isCalculatingDelivery: false,
      ));
    } catch (e) {
      logger.e('Unexpected error calculating delivery cost', error: e);
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: null,
        isCalculatingDelivery: false,
      ));
    }
  }
}

