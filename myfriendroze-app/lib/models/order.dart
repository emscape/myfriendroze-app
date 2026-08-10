import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

/// Represents a customer for an order
@JsonSerializable()
class Customer {
  final String email;
  final String name;
  final String? phone;

  const Customer({
    required this.email,
    required this.name,
    this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerToJson(this);
}

/// Represents an order item
@JsonSerializable()
class OrderItem {
  final String sku;
  final String name;
  final int qty;
  final double price;
  final String? description;

  const OrderItem({
    required this.sku,
    required this.name,
    required this.qty,
    required this.price,
    this.description,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}

/// Represents a complete order
@JsonSerializable()
class Order {
  final String? id;
  final Customer customer;
  final List<OrderItem> items;
  final double total;
  final String currency;
  final String? notes;
  final DateTime? createdAt;
  final String? status;

  const Order({
    this.id,
    required this.customer,
    required this.items,
    required this.total,
    this.currency = 'USD',
    this.notes,
    this.createdAt,
    this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);

  /// Create a copy with optional fields replaced
  Order copyWith({
    String? id,
    Customer? customer,
    List<OrderItem>? items,
    double? total,
    String? currency,
    String? notes,
    DateTime? createdAt,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

/// Response from order creation
@JsonSerializable()
class OrderResponse {
  final Order order;
  final String message;

  const OrderResponse({
    required this.order,
    required this.message,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrderResponseToJson(this);
}
