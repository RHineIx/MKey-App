// FILE: lib/src/models/product_model.dart
import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String sku;
  final int quantity;
  final int alertLevel;
  final double costPriceIqd;
  final double sellPriceIqd;
  final double costPriceUsd;
  final double sellPriceUsd;
  final String? imagePath;
  final List<String> categories;
  final String? oemPartNumber;
  final String? compatiblePartNumber;
  final String? notes;
  final String? supplierId;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.quantity = 0,
    this.alertLevel = 2,
    this.costPriceIqd = 0.0,
    this.sellPriceIqd = 0.0,
    this.costPriceUsd = 0.0,
    this.sellPriceUsd = 0.0,
    this.imagePath,
    this.categories = const [],
    this.oemPartNumber,
    this.compatiblePartNumber,
    this.notes,
    this.supplierId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> categories = [];
    if (json['categories'] != null && json['categories'] is List) {
      categories = List<String>.from(json['categories']);
    } else if (json['category'] != null && json['category'] is String) {
      categories = [json['category']];
    }

    return Product(
      id: json['id'] ?? 'no-id-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? 'Unnamed Product',
      sku: json['sku'] ?? 'no-sku',
      quantity: json['quantity'] ?? 0,
      alertLevel: json['alertLevel'] ?? 2,
      costPriceIqd: (json['costPriceIqd'] as num?)?.toDouble() ?? 0.0,
      sellPriceIqd: (json['sellPriceIqd'] as num?)?.toDouble() ?? 0.0,
      costPriceUsd: (json['costPriceUsd'] as num?)?.toDouble() ?? 0.0,
      sellPriceUsd: (json['sellPriceUsd'] as num?)?.toDouble() ?? 0.0,
      imagePath: json['imagePath'],
      categories: categories,
      oemPartNumber: json['oemPartNumber'],
      compatiblePartNumber: json['compatiblePartNumber'],
      notes: json['notes'],
      supplierId: json['supplierId'],
    );
  }

  // For saving to local SQFlite database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'quantity': quantity,
      'alertLevel': alertLevel,
      'costPriceIqd': costPriceIqd,
      'sellPriceIqd': sellPriceIqd,
      'costPriceUsd': costPriceUsd,
      'sellPriceUsd': sellPriceUsd,
      'imagePath': imagePath,
      'categories': jsonEncode(categories),
      'oemPartNumber': oemPartNumber,
      'compatiblePartNumber': compatiblePartNumber,
      'notes': notes,
      'supplierId': supplierId,
    };
  }

  // For saving to GitHub JSON
  Map<String, dynamic> toMapForJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'quantity': quantity,
      'alertLevel': alertLevel,
      'costPriceIqd': costPriceIqd,
      'sellPriceIqd': sellPriceIqd,
      'costPriceUsd': costPriceUsd,
      'sellPriceUsd': sellPriceUsd,
      'imagePath': imagePath,
      'categories': categories, // Save as a list
      'oemPartNumber': oemPartNumber,
      'compatiblePartNumber': compatiblePartNumber,
      'notes': notes,
      'supplierId': supplierId,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    List<String> categories = [];
    final categoriesData = map['categories'];
    if (categoriesData is String) {
      try {
        categories = List<String>.from(jsonDecode(categoriesData));
      } catch (e) {
        categories = categoriesData.split(',').where((s) => s.isNotEmpty).toList();
      }
    }

    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      quantity: map['quantity'] ?? 0,
      alertLevel: map['alertLevel'] ?? 2,
      costPriceIqd: (map['costPriceIqd'] as num?)?.toDouble() ?? 0.0,
      sellPriceIqd: (map['sellPriceIqd'] as num?)?.toDouble() ?? 0.0,
      costPriceUsd: (map['costPriceUsd'] as num?)?.toDouble() ?? 0.0,
      sellPriceUsd: (map['sellPriceUsd'] as num?)?.toDouble() ?? 0.0,
      imagePath: map['imagePath'],
      categories: categories,
      oemPartNumber: map['oemPartNumber'],
      compatiblePartNumber: map['compatiblePartNumber'],
      notes: map['notes'],
      supplierId: map['supplierId'],
    );
  }
}