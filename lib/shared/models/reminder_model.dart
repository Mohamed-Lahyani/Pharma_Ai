class ReminderModel {
  final String id;
  final String userId;
  final String medicationName;
  final String time;
  final String frequency;
  final bool active;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.medicationName,
    required this.time,
    required this.frequency,
    required this.active,
  });

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