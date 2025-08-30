// FILE: lib/src/models/sale_model.dart
class Sale {
  final String saleId;
  final String itemId;
  final String itemName;
  final int quantitySold;
  final double sellPriceIqd;
  final double costPriceIqd;
  final double sellPriceUsd;
  final double costPriceUsd;
  final String saleDate;
  final String? notes;
  final String timestamp;

  Sale({
    required this.saleId,
    required this.itemId,
    required this.itemName,
    required this.quantitySold,
    required this.sellPriceIqd,
    required this.costPriceIqd,
    required this.sellPriceUsd,
    required this.costPriceUsd,
    required this.saleDate,
    this.notes,
    required this.timestamp,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      saleId: json['saleId'],
      itemId: json['itemId'],
      itemName: json['itemName'],
      quantitySold: json['quantitySold'],
      sellPriceIqd: (json['sellPriceIqd'] as num).toDouble(),
      costPriceIqd: (json['costPriceIqd'] as num).toDouble(),
      sellPriceUsd: (json['sellPriceUsd'] as num).toDouble(),
      costPriceUsd: (json['costPriceUsd'] as num).toDouble(),
      saleDate: json['saleDate'],
      notes: json['notes'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'saleId': saleId,
      'itemId': itemId,
      'itemName': itemName,
      'quantitySold': quantitySold,
      'sellPriceIqd': sellPriceIqd,
      'costPriceIqd': costPriceIqd,
      'sellPriceUsd': sellPriceUsd,
      'costPriceUsd': costPriceUsd,
      'saleDate': saleDate,
      'notes': notes,
      'timestamp': timestamp,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale.fromJson(map);
  }
}