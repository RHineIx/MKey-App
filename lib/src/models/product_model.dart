// Helper function to safely parse a value that could be a String, int, or double.
double? _tryParseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class Product {
  final String id;
  final String name;
  final String sku;
  final int? quantity;
  final double? sellPriceIqd;
  final double? costPriceIqd; // New field
  final String? imagePath;
  final List<String>? categories;
  final int? alertLevel;
  final String? oemPartNumber; // New field
  final String? compatiblePartNumber; // New field
  final String? notes; // New field

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.quantity,
    this.sellPriceIqd,
    this.costPriceIqd,
    this.imagePath,
    this.categories,
    this.alertLevel,
    this.oemPartNumber,
    this.compatiblePartNumber,
    this.notes,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String>? categories;
    if (json['categories'] != null && json['categories'] is List) {
      categories = (json['categories'] as List)
          .map((item) => item?.toString())
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    }
    else if (json['category'] != null && json['category'] is String && (json['category'] as String).isNotEmpty) {
      categories = [json['category'] as String];
    }

    return Product(
      id: json['id'] ?? 'no-id',
      name: json['name'] ?? 'Unnamed Product',
      sku: json['sku'] ?? 'no-sku',
      quantity: json['quantity'],
      sellPriceIqd: _tryParseDouble(json['sellPriceIqd']),
      costPriceIqd: _tryParseDouble(json['costPriceIqd']), // Read new field
      imagePath: json['imagePath'],
      categories: categories,
      alertLevel: json['alertLevel'],
      oemPartNumber: json['oemPartNumber'], // Read new field
      compatiblePartNumber: json['compatiblePartNumber'], // Read new field
      notes: json['notes'], // Read new field
    );
  }
}