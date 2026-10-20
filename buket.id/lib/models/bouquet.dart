class Bouquet {
  final String id;
  final String name;
  final String description;
  final double price;
  final String city;
  final List<String> images;
  final String category;
  final double rating;
  final int reviews;
  final int readyStock;

  Bouquet({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.city,
    required this.images,
    required this.category,
    this.rating = 4.5,
    this.reviews = 0,
    this.readyStock = 10,
  });

  factory Bouquet.fromJson(Map<String, dynamic> json) {
    return Bouquet(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      city: json['city'] as String,
      images: List<String>.from(json['images'] as List),
      category: json['category'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviews: json['reviews'] as int? ?? 0,
      readyStock: json['readyStock'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'city': city,
      'images': images,
      'category': category,
      'rating': rating,
      'reviews': reviews,
      'readyStock': readyStock,
    };
  }
}
