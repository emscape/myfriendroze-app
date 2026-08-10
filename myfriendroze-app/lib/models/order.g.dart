// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
  email: json['email'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
  'email': instance.email,
  'name': instance.name,
  'phone': instance.phone,
};

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  sku: json['sku'] as String,
  name: json['name'] as String,
  qty: (json['qty'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
  description: json['description'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'sku': instance.sku,
  'name': instance.name,
  'qty': instance.qty,
  'price': instance.price,
  'description': instance.description,
};

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: json['id'] as String?,
  customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'USD',
  notes: json['notes'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  status: json['status'] as String?,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'customer': instance.customer,
  'items': instance.items,
  'total': instance.total,
  'currency': instance.currency,
  'notes': instance.notes,
  'createdAt': instance.createdAt?.toIso8601String(),
  'status': instance.status,
};

OrderResponse _$OrderResponseFromJson(Map<String, dynamic> json) =>
    OrderResponse(
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
      message: json['message'] as String,
    );

Map<String, dynamic> _$OrderResponseToJson(OrderResponse instance) =>
    <String, dynamic>{'order': instance.order, 'message': instance.message};
