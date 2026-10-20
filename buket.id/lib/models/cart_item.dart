import 'bouquet.dart';

class CartItem {
  final String id;
  final Bouquet bouquet;
  int quantity;
  String? notes;
  String? greetingCard;

  CartItem({
    required this.id,
    required this.bouquet,
    this.quantity = 1,
    this.notes,
    this.greetingCard,
  });

  double get total => bouquet.price * quantity;
}
