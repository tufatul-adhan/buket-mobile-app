import 'cart_item.dart';

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final String paymentMethod;
  final String address;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.paymentMethod,
    required this.address,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List)
          .map((e) => CartItem(
                id: e['id'],
                bouquet: e['bouquet'],
                quantity: e['quantity'],
              ))
          .toList(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      paymentMethod: json['paymentMethod'] as String,
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'paymentMethod': paymentMethod,
      'address': address,
    };
  }
}
