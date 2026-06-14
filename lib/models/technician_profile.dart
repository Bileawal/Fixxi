class TechnicianProfile {
  TechnicianProfile({
    required this.id,
    required this.userId,
    required this.skills,
    this.extraSkills = '',
    this.idCardFrontUrl = '',
    this.idCardBackUrl = '',
    required this.status,
    this.rejectionReason,
    this.testScore,
  });

  final String id;
  final String userId;
  final List<String> skills;
  final String extraSkills;
  final String idCardFrontUrl;
  final String idCardBackUrl;
  final String status;
  final String? rejectionReason;
  final double? testScore;

  bool get isPendingAdmin => status == 'pending_admin';
  bool get isRejected => status == 'rejected';
  bool get needsTest => status == 'approved' || status == 'test_failed';
  bool get isActive => status == 'test_passed';

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) =>
      TechnicianProfile(
        id: json['id'] as String? ?? json['_id'] as String? ?? '',
        userId: json['userId'] as String,
        skills: (json['skills'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        extraSkills: json['extraSkills'] as String? ?? '',
        idCardFrontUrl: json['idCardFrontUrl'] as String? ?? '',
        idCardBackUrl: json['idCardBackUrl'] as String? ?? '',
        status: json['status'] as String? ?? 'pending_admin',
        rejectionReason: json['rejectionReason'] as String?,
        testScore: (json['testScore'] as num?)?.toDouble(),
      );
}
