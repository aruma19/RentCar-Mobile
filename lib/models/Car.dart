class Car {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double dailyRate;
  final String description;
  final String price;
  final String plate;
  final List<String> images;

  Car({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.dailyRate,
    required this.description,
    required this.price,
    required this.plate,
    required this.images,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      category: json['category'],
      dailyRate: json['daily_rate'].toDouble(),
      description: json['description'],
      price: json['price'],
      plate: json['plate'],
      images: List<String>.from(json['images']),
    );
  }

  String? get imageUrl => null;
}
