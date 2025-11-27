import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String businessId;
  final String title;
  final String? description;
  final double price;
  final String currency;
  final String? sku;
  final String? imageUrl;
  final Map<String, dynamic>? variations;  // Вариации товара (размер, цвет и т.д.)
  final bool isActive;
  final List<String> categoryIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.businessId,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'RUB',
    this.sku,
    this.imageUrl,
    this.variations,
    this.isActive = true,
    this.categoryIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        title,
        description,
        price,
        currency,
        sku,
        imageUrl,
        variations,
        isActive,
        categoryIds,
        createdAt,
        updatedAt,
      ];
}

