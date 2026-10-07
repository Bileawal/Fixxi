import '../core/utils/firestore_helpers.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.requestId,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  bool read;
  final String? requestId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'requestId': requestId,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] ?? json['_id']).toString(),
        userId: json['userId'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: parseFirestoreDate(json['createdAt']),
        read: json['read'] as bool? ?? false,
        requestId: json['requestId'] as String?,
      );
}
