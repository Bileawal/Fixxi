import 'user_role.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.address,
    this.fatherName,
    this.skills = const [],
    this.isAvailable = true,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.latitude = 31.5204,
    this.longitude = 74.3587,
    this.distanceKm,
    this.checkFee,
    this.extraSkills,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? address;
  final String? fatherName;
  final List<String> skills;
  final String? extraSkills;
  bool isAvailable;
  double rating;
  int reviewCount;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final int? checkFee;

  bool get isTechnician => role == UserRole.technician;
  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        role: UserRole.values.byName(json['role'] as String),
        address: json['address'] as String?,
        fatherName: json['fatherName'] as String?,
        skills: (json['skills'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        extraSkills: json['extraSkills'] as String?,
        isAvailable: json['isAvailable'] as bool? ?? true,
        rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
        reviewCount: json['reviewCount'] as int? ?? 0,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 31.5204,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 74.3587,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        checkFee: json['checkFee'] as int?,
      );

  AppUser copyWith({
    bool? isAvailable,
    double? rating,
    int? reviewCount,
  }) =>
      AppUser(
        id: id,
        name: name,
        email: email,
        phone: phone,
        role: role,
        address: address,
        fatherName: fatherName,
        skills: skills,
        extraSkills: extraSkills,
        isAvailable: isAvailable ?? this.isAvailable,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        latitude: latitude,
        longitude: longitude,
        distanceKm: distanceKm,
        checkFee: checkFee,
      );
}
