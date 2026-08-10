import 'package:json_annotation/json_annotation.dart';

part 'subscription.g.dart';

/// Represents a subscription request/response
@JsonSerializable()
class Subscription {
  final String? id;
  final String email;
  final String? name;
  final DateTime? subscriptionDate;
  final String? status;
  final Map<String, dynamic>? metadata;

  const Subscription({
    this.id,
    required this.email,
    this.name,
    this.subscriptionDate,
    this.status,
    this.metadata,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  /// Create a copy with optional fields replaced
  Subscription copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? subscriptionDate,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return Subscription(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      subscriptionDate: subscriptionDate ?? this.subscriptionDate,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Response from subscription creation
@JsonSerializable()
class SubscriptionResponse {
  final Subscription subscription;
  final String message;

  const SubscriptionResponse({
    required this.subscription,
    required this.message,
  });

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionResponseToJson(this);
}
