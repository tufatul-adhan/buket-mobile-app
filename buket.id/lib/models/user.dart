class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String? address;
  final String? password;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    this.address,
    this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      city: json['city'] as String,
      address: json['address'] as String?,
      password: json['password'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'address': address,
      'password': password,
    };
  }
}
