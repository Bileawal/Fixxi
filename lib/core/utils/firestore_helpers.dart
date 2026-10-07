import 'package:cloud_firestore/cloud_firestore.dart';

DateTime parseFirestoreDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

String? formatFirestoreDate(dynamic value) {
  if (value == null) return null;
  final dt = parseFirestoreDate(value);
  return dt.toIso8601String();
}

Map<String, dynamic> normalizeFirestoreMap(Map<String, dynamic> data) {
  final map = Map<String, dynamic>.from(data);
  for (final key in ['createdAt', 'updatedAt', 'scheduledAt', 'suspendedUntil']) {
    if (map[key] != null) {
      map[key] = formatFirestoreDate(map[key]);
    }
  }
  return map;
}
