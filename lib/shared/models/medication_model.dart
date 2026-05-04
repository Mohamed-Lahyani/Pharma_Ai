class MedicationModel {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final int stock;
  final String description;
  final String category;
  final String expiryDate;

  MedicationModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.stock,
    required this.description,
    required this.category,
    required this.expiryDate,
  });

  // Convertir Firestore → MedicationModel
  factory MedicationModel.fromMap(Map<String, dynamic> map, String id) {
    return MedicationModel(
      id: id,
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
    );
  }

  // Convertir MedicationModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
      'stock': stock,
      'description': description,
      'category': category,
      'expiryDate': expiryDate,
    };
  }

  // Vérifier si le stock est critique (moins de 5)
  bool get isLowStock => stock < 5;
}