class ReminderModel {
  final String id;
  final String userId;
  final String medicationName;
  final String time; // ex: "08:30"
  final String frequency; // "daily", "weekly"
  final bool active;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.medicationName,
    required this.time,
    required this.frequency,
    required this.active,
  });

  // Convertir Firestore → ReminderModel
  factory ReminderModel.fromMap(Map<String, dynamic> map, String id) {
    return ReminderModel(
      id: id,
      userId: map['userId'] ?? '',
      medicationName: map['medicationName'] ?? '',
      time: map['time'] ?? '08:00',
      frequency: map['frequency'] ?? 'daily',
      active: map['active'] ?? true,
    );
  }

  // Convertir ReminderModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'medicationName': medicationName,
      'time': time,
      'frequency': frequency,
      'active': active,
    };
  }
}