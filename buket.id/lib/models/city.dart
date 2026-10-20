class City {
  final String id;
  final String name;
  final String province;

  const City({
    required this.id,
    required this.name,
    required this.province,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      name: json['name'] as String,
      province: json['province'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province': province,
    };
  }
}
