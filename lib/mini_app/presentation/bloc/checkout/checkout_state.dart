part of 'checkout_bloc.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String deliveryMethod; // pickup or delivery
  final String paymentMethod; // cash or online
  final double? deliveryCost; // Стоимость доставки
  final bool isCalculatingDelivery; // Идет ли расчет доставки

  const CheckoutInitial({
    this.customerName = '',
    this.customerPhone = '',
    this.customerAddress = '',
    this.deliveryMethod = 'pickup',
    this.paymentMethod = 'cash',
    this.deliveryCost,
    this.isCalculatingDelivery = false,
  });

  @override
  List<Object?> get props => [
        customerName,
        customerPhone,
        customerAddress,
        deliveryMethod,
        paymentMethod,
        deliveryCost,
        isCalculatingDelivery,
      ];
}

class CheckoutLoading extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {
  final entities.Order order;
  final String? paymentUrl; // URL для оплаты (если paymentMethod == 'online')

  const CheckoutSuccess(this.order, {this.paymentUrl});

  @override
  List<Object?> get props => [order, paymentUrl];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError(this.message);

  @override
  List<Object?> get props => [message];
}

