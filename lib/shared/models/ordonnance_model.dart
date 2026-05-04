class OrdonnanceModel {
  final String id;
  final String userId;
  final String userName;
  final String extractedText;
  final List<String> medicines;
  final String status; // "pending", "validated", "rejected"
  final DateTime createdAt;
  final DateTime? validatedAt;

  OrdonnanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.extractedText,
    required this.medicines,
    required this.status,
    required this.createdAt,
    this.validatedAt,
  });

  // Convertir Firestore → OrdonnanceModel
  factory OrdonnanceModel.fromMap(Map<String, dynamic> map, String id) {
    return OrdonnanceModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      extractedText: map['extractedText'] ?? '',
      medicines: List<String>.from(map['medicines'] ?? []),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt']),
      validatedAt: map['validatedAt'] != null
          ? DateTime.parse(map['validatedAt'])
          : null,
    );
  }

  // Convertir OrdonnanceModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'extractedText': extractedText,
      'medicines': medicines,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'validatedAt': validatedAt?.toIso8601String(),
    };
  }

  // Couleur selon le statut
  bool get isPending => status == 'pending';
  bool get isValidated => status == 'validated';
  bool get isRejected => status == 'rejected';
}