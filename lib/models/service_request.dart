import '../core/utils/firestore_helpers.dart';

enum RequestType { urgent, scheduled }

enum RequestStatus {
  pending,
  accepted,
  rejected,
  inProgress,
  completed,
  cancelled,
}

class ServiceRequest {
  ServiceRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.category,
    required this.description,
    required this.type,
    this.technicianId,
    this.technicianName,
    this.scheduledAt,
    this.status = RequestStatus.pending,
    required this.createdAt,
    this.address,
    this.distanceKm = 2.5,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String category;
  final String description;
  final RequestType type;
  String? technicianId;
  String? technicianName;
  final DateTime? scheduledAt;
  RequestStatus status;
  final DateTime createdAt;
  final String? address;
  final double distanceKm;

  bool get isUrgent => type == RequestType.urgent;
  bool get isActive =>
      status == RequestStatus.accepted || status == RequestStatus.inProgress;

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'category': category,
        'description': description,
        'type': type.name,
        'technicianId': technicianId,
        'technicianName': technicianName,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'address': address,
        'distanceKm': distanceKm,
      };

  factory ServiceRequest.fromJson(Map<String, dynamic> json) =>
      ServiceRequest(
        id: (json['id'] ?? json['_id']).toString(),
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        type: RequestType.values.byName(json['type'] as String),
        technicianId: json['technicianId'] as String?,
        technicianName: json['technicianName'] as String?,
        scheduledAt: json['scheduledAt'] != null
            ? parseFirestoreDate(json['scheduledAt'])
            : null,
        status: RequestStatus.values.byName(json['status'] as String),
        createdAt: parseFirestoreDate(json['createdAt']),
        address: json['address'] as String?,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 2.5,
      );
}
