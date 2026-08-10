// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
  id: json['id'] as String?,
  email: json['email'] as String,
  name: json['name'] as String?,
  subscriptionDate: json['subscriptionDate'] == null
      ? null
      : DateTime.parse(json['subscriptionDate'] as String),
  status: json['status'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'subscriptionDate': instance.subscriptionDate?.toIso8601String(),
      'status': instance.status,
      'metadata': instance.metadata,
    };

SubscriptionResponse _$SubscriptionResponseFromJson(
  Map<String, dynamic> json,
) => SubscriptionResponse(
  subscription: Subscription.fromJson(
    json['subscription'] as Map<String, dynamic>,
  ),
  message: json['message'] as String,
);

Map<String, dynamic> _$SubscriptionResponseToJson(
  SubscriptionResponse instance,
) => <String, dynamic>{
  'subscription': instance.subscription,
  'message': instance.message,
};
