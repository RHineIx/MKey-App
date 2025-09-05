class Supplier {
  final String id;
  final String name;
  final String? phone;

  Supplier({
    required this.id,
    required this.name,
    this.phone,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier.fromJson(map);
  }
}