class Review {
  Review({
    required this.id,
    required this.technicianId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.repairCost,
    required this.actualIssue,
    required this.createdAt,
  });

  final String id;
  final String technicianId;
  final String customerId;
  final String customerName;
  final double rating;
  final String comment;
  final double repairCost;
  final String actualIssue;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    final techRaw = json['technicianId'];
    final custRaw = json['customerId'];
    return Review(
      id: (json['id'] ?? json['_id']).toString(),
      technicianId: (techRaw is Map ? (techRaw['id'] ?? techRaw['_id']) : techRaw).toString(),
      customerId: (custRaw is Map ? (custRaw['id'] ?? custRaw['_id']) : custRaw).toString(),
      customerName: json['customerName'] as String? ?? 'Customer',
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      repairCost: (json['repairCost'] as num?)?.toDouble() ?? 0,
      actualIssue: json['actualIssue'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
