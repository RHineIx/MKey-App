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
  final double? costPriceIqd;
  final String? imagePath;
  final List<String>? categories;
  final int? alertLevel;
  final String? oemPartNumber;
  final String? compatiblePartNumber;
  final String? notes;

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
      costPriceIqd: _tryParseDouble(json['costPriceIqd']),
      imagePath: json['imagePath'],
      categories: categories,
      alertLevel: json['alertLevel'],
      oemPartNumber: json['oemPartNumber'],
      compatiblePartNumber: json['compatiblePartNumber'],
      notes: json['notes'],
    );
  }

  // --- Methods for Database Interaction ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'quantity': quantity,
      'sellPriceIqd': sellPriceIqd,
      'costPriceIqd': costPriceIqd,
      'imagePath': imagePath,
      'categories': categories?.join(','), // Store list as comma-separated string
      'alertLevel': alertLevel,
      'oemPartNumber': oemPartNumber,
      'compatiblePartNumber': compatiblePartNumber,
      'notes': notes,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final categoriesString = map['categories'] as String?;
    return Product(
      id: map['id'] ?? 'no-id',
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      quantity: map['quantity'],
      sellPriceIqd: map['sellPriceIqd'],
      costPriceIqd: map['costPriceIqd'],
      imagePath: map['imagePath'],
      categories: (categoriesString?.isNotEmpty ?? false)
          ? categoriesString!.split(',')
          : [],
      alertLevel: map['alertLevel'],
      oemPartNumber: map['oemPartNumber'],
      compatiblePartNumber: map['compatiblePartNumber'],
      notes: map['notes'],
    );
  }
}