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
    this.testTries = 0,
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
  final int testTries;

  bool get isPendingAdmin => status == 'pending_admin';
  bool get isRejected => status == 'rejected';
  bool get needsTest => status == 'pending_test';
  bool get isTestLocked => status == 'test_locked' || testTries >= 3;
  bool get canTakeTest => needsTest && !isTestLocked;
  bool get isActive => status == 'approved';

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
        testTries: json['testTries'] as int? ?? 0,
      );
}
