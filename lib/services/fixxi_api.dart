import 'dart:io';
import 'dart:math';
import 'dart:async' show unawaited;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/utils/firestore_helpers.dart';
import '../data/test_questions_bank.dart';
import 'cloudinary_service.dart';
import '../core/utils/fee_calculator.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/review.dart';
import '../models/service_request.dart';
import '../models/technician_profile.dart';
import '../models/user_role.dart';
import 'ai_learning_service.dart';

class LoginResult {
  LoginResult({
    required this.user,
    this.technicianProfile,
  });

  final AppUser user;
  final TechnicianProfile? technicianProfile;
}

class FixxiApi {
  FixxiApi({CloudinaryService? cloudinary}) : _cloudinary = cloudinary ?? CloudinaryService();

  final _auth = fb.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final CloudinaryService _cloudinary;

  Future<void> _sendFcmPushToUser(
    String recipientUid, {
    required String title,
    required String body,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(recipientUid).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) return;

      final serviceAccountJson = await rootBundle.loadString('assets/service_account.json');
      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);

      final projectId = accountCredentials.projectId;
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'fixxi_channel'
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default'
              }
            }
          }
        }
      };

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      client.close();
      if (kDebugMode) {
         print('[FCM] Send push response: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] Push error: $e');
    }
  }
  // ────────────────────────────────────────────────────────────────────────────

  // Haversine formula helper for distance calculation
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Earth radius in km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Future<void> _requireAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data()?['role'] != 'admin') {
      throw Exception('Admin access only');
    }
  }

  // --- OTP Verification (Direct Flutter Email + Client-side Firestore) ---

  Future<Map<String, dynamic>> sendCustomerOtp(String email) async {
    final normalized = email.trim().toLowerCase();
    
    // Generate 6 digit OTP
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    
    final docRef = _firestore.collection('otp_verifications').doc(normalized);
    await docRef.set({
      'code': otp,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
      'verified': false,
      'attempts': 0,
    });
    
    // Send email using mailer directly
    try {
      final smtpServer = gmail('bilawal22204@gmail.com', 'ucob giqd hspw mxuz');
      
      final message = Message()
        ..from = const Address('bilawal22204@gmail.com', 'Fixxi')
        ..recipients.add(normalized)
        ..subject = 'Fixxi - Your Email Verification Code'
        ..text = 'Your Fixxi verification code is: $otp\n\nThis code expires in 5 minutes.';

      await send(message, smtpServer);
    } catch (e) {
      debugPrint('Failed to send OTP email directly: $e');
      throw Exception('Failed to send OTP email directly. Please check your internet connection.');
    }

    return {
      'message': 'OTP sent to $normalized',
      'expiresInSeconds': 300,
    };
  }

  Future<String> verifyCustomerOtp(String email, String otp) async {
    final normalized = email.trim().toLowerCase();
    final docRef = _firestore.collection('otp_verifications').doc(normalized);
    final snap = await docRef.get();
    
    if (!snap.exists) {
      throw Exception('No OTP found for this email. Please request a new code.');
    }
    
    final data = snap.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if (expiresAt.isBefore(DateTime.now())) {
      throw Exception('OTP code expired. Please request a new one.');
    }
    
    if (data['code'] != otp.trim()) {
      throw Exception('Wrong OTP code. Please try again.');
    }
    
    await docRef.update({'verified': true});
    return 'verified_${normalized}_${DateTime.now().millisecondsSinceEpoch}';
  }

  // --- Authentication / Registration ---

  Future<LoginResult> registerCustomer({
    required String name,
    required String phone,
    required String address,
    required String email,
    required String password,
    required String otpToken,
  }) async {
    if (!otpToken.startsWith('verified_')) {
      throw Exception('Please verify OTP code first');
    }

    // Create Firebase Auth User
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;

    final userData = {
      'id': uid,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'role': 'customer',
      'address': address.trim(),
      'isAvailable': true,
      'rating': 4.5,
      'reviewCount': 0,
      'latitude': 31.5204,
      'longitude': 74.3587,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Save in Firestore
    await _firestore.collection('users').doc(uid).set(userData);

    final user = AppUser.fromJson(userData);
    return LoginResult(user: user);
  }

  Future<LoginResult> registerTechnician({
    required String name,
    required String fatherName,
    required String address,
    required String phone,
    required String email,
    required String password,
    required List<String> skills,
    String? extraSkills,
    required File idCardFront,
    required File idCardBack,
  }) async {
    // Create Firebase Auth User
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;

    final frontUrl = await _cloudinary.uploadImage(
      idCardFront,
      folder: 'fixxi/id_cards/$uid',
      fileName: 'front',
    );
    final backUrl = await _cloudinary.uploadImage(
      idCardBack,
      folder: 'fixxi/id_cards/$uid',
      fileName: 'back',
    );

    final userData = {
      'id': uid,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'role': 'technician',
      'address': address.trim(),
      'fatherName': fatherName.trim(),
      'skills': skills,
      'extraSkills': extraSkills ?? '',
      'isAvailable': false, // Available only after test passed
      'rating': 4.5,
      'reviewCount': 0,
      'latitude': 31.5204,
      'longitude': 74.3587,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final profileData = {
      'id': uid,
      'userId': uid,
      'skills': skills,
      'extraSkills': extraSkills ?? '',
      'idCardFrontUrl': frontUrl,
      'idCardBackUrl': backUrl,
      'status': 'pending_test',
      'testTries': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Save in Firestore
    await _firestore.collection('users').doc(uid).set(userData);
    await _firestore.collection('technician_profiles').doc(uid).set(profileData);

    final user = AppUser.fromJson(userData);
    final profile = TechnicianProfile.fromJson(profileData);

    return LoginResult(user: user, technicianProfile: profile);
  }

  Future<LoginResult> login(String email, String password, {UserRole? role}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      await _auth.signOut();
      if (role == UserRole.admin) {
        throw Exception(
          'Admin profile not found. Please contact super admin.',
        );
      }
      throw Exception('User data not found in database');
    }

    final userData = userDoc.data()!;
    userData['id'] = uid;

    if (role != null && userData['role'] != role.name) {
      await _auth.signOut();
      throw Exception('Not a ${role.name} account');
    }

    if (userData['role'] != 'admin' && (userData['isSuspended'] as bool? ?? false)) {
      final suspendedUntil = userData['suspendedUntil'] as Timestamp?;
      if (suspendedUntil == null || suspendedUntil.toDate().isAfter(DateTime.now())) {
        await _auth.signOut();
        throw Exception('Account suspended. ${userData['suspensionReason'] ?? "Contact admin."}');
      }
    }

    final user = AppUser.fromJson(userData);
    TechnicianProfile? profile;

    if (user.role == UserRole.technician) {
      final profileDoc = await _firestore.collection('technician_profiles').doc(uid).get();
      if (profileDoc.exists) {
        final profileData = profileDoc.data()!;
        profileData['id'] = uid;
        profile = TechnicianProfile.fromJson(profileData);
      }
    }

    return LoginResult(user: user, technicianProfile: profile);
  }

  /// Sends Firebase password-reset email. Role is checked so a customer
  /// reset is not sent for a technician email (and vice versa).
  Future<void> sendPasswordResetEmail(String email, {UserRole? role}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw Exception('Please enter a valid email');
    }

    final snap = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('No account found with this email');
    }

    final storedRole = snap.docs.first.data()['role'] as String? ?? '';
    if (role != null && storedRole != role.name) {
      throw Exception('This email is not registered as a ${role.label}');
    }

    await _auth.sendPasswordResetEmail(email: normalized);
  }

  Future<LoginResult> getMe() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');
    final uid = currentUser.uid;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) throw Exception('User record not found');

    final userData = userDoc.data()!;
    userData['id'] = uid;

    final user = AppUser.fromJson(userData);
    TechnicianProfile? profile;

    if (user.role == UserRole.technician) {
      final profileDoc = await _firestore.collection('technician_profiles').doc(uid).get();
      if (profileDoc.exists) {
        final profileData = profileDoc.data()!;
        profileData['id'] = uid;
        profile = TechnicianProfile.fromJson(profileData);
      }
    }

    return LoginResult(user: user, technicianProfile: profile);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// First-time admin setup (Firebase Auth + Firestore profile).
  Future<LoginResult> createAdminAccount({
    required String email,
    required String password,
    String name = 'Fixxi Admin',
  }) async {
    fb.UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        credential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } else {
        rethrow;
      }
    }

    final uid = credential.user!.uid;

    final existingAdmins = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    final otherAdmins = existingAdmins.docs.where((doc) => doc.id != uid).toList();
    if (otherAdmins.isNotEmpty) {
      await _auth.signOut();
      throw Exception('Admin already exists. Please login instead.');
    }

    final userData = {
      'id': uid,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': '03000000000',
      'role': 'admin',
      'address': 'Lahore',
      'isAvailable': true,
      'rating': 5.0,
      'reviewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).set(userData, SetOptions(merge: true));

    final user = AppUser.fromJson({...userData, 'id': uid});
    return LoginResult(user: user);
  }

  Future<void> updateFcmToken(String fcmToken) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({'fcmToken': fcmToken});
    }
  }

  // --- Admin Methods ---

  Future<List<Map<String, dynamic>>> adminListTechnicians({String? status}) async {
    await _requireAdmin();
    Query query = _firestore.collection('technician_profiles');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();

    final list = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final data = normalizeFirestoreMap(doc.data() as Map<String, dynamic>);
      data['id'] = doc.id;
      
      final userDoc = await _firestore.collection('users').doc(data['userId']).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        data['user'] = {
          'id': userDoc.id,
          'name': userData['name'],
          'email': userData['email'],
          'phone': userData['phone'],
          'address': userData['address'],
          'fatherName': userData['fatherName'],
        };
      }
      list.add(data);
    }
    list.sort((a, b) {
      final aDate = parseFirestoreDate(a['createdAt']);
      final bDate = parseFirestoreDate(b['createdAt']);
      return bDate.compareTo(aDate);
    });
    return list;
  }

  Future<Map<String, dynamic>> adminGetTechnician(String id) async {
    await _requireAdmin();
    final profileDoc = await _firestore.collection('technician_profiles').doc(id).get();
    if (!profileDoc.exists) throw Exception('Profile not found');

    final data = profileDoc.data()!;
    data['id'] = profileDoc.id;

    final userDoc = await _firestore.collection('users').doc(data['userId']).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      data['user'] = {
        'id': userDoc.id,
        'name': userData['name'],
        'email': userData['email'],
        'phone': userData['phone'],
        'address': userData['address'],
        'fatherName': userData['fatherName'],
        'rating': userData['rating'],
        'reviewCount': userData['reviewCount'],
      };
    }
    return data;
  }

  Future<void> adminApprove(String id) async {
    await _requireAdmin();
    final profileDoc = await _firestore.collection('technician_profiles').doc(id).get();
    if (!profileDoc.exists) throw Exception('Technician not found');

    await _firestore.collection('technician_profiles').doc(id).update({
      'status': 'test_passed',
      'rejectionReason': FieldValue.delete(),
    });

    final userId = profileDoc.data()!['userId'] as String;
    await _firestore.collection('users').doc(userId).update({'isAvailable': true});

    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': 'Application approved',
      'body': 'Congratulations! Your profile is approved. You can now receive service requests.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminReject(String id, {String? reason}) async {
    await _requireAdmin();
    final profileDoc = await _firestore.collection('technician_profiles').doc(id).get();
    if (!profileDoc.exists) throw Exception('Technician not found');

    final fallbackReason = reason ?? 'Application rejected by admin';
    await _firestore.collection('technician_profiles').doc(id).update({
      'status': 'rejected',
      'rejectionReason': fallbackReason,
    });

    final userId = profileDoc.data()!['userId'] as String;
    await _firestore.collection('users').doc(userId).update({'isAvailable': false});

    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': 'Application rejected',
      'body': fallbackReason,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  Future<void> adminResetTestTries(String id) async {
    await _requireAdmin();
    final profileDoc = await _firestore.collection('technician_profiles').doc(id).get();
    if (!profileDoc.exists) throw Exception('Technician not found');

    await _firestore.collection('technician_profiles').doc(id).update({
      'status': 'pending_test',
      'testTries': 0,
    });

    final userId = profileDoc.data()!['userId'] as String;
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': 'Test attempts reset',
      'body': 'Admin has reset your test attempts. You can take the skill test again.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendAdminMessage(String message) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};

    await _firestore.collection('admin_messages').add({
      'senderId': uid,
      'senderName': userData['name'] ?? 'Technician',
      'senderEmail': userData['email'] ?? '',
      'message': message.trim(),
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> adminListMessages({String? technicianId}) async {
    await _requireAdmin();
    Query query = _firestore.collection('admin_messages');
    if (technicianId != null) {
      query = query.where('senderId', isEqualTo: technicianId);
    }
    final snap = await query.get();
    final list = snap.docs.map((doc) {
      final d = normalizeFirestoreMap(doc.data() as Map<String, dynamic>);
      d['id'] = doc.id;
      return d;
    }).toList();
    list.sort((a, b) {
      final aDate = parseFirestoreDate(a['createdAt']);
      final bDate = parseFirestoreDate(b['createdAt']);
      return bDate.compareTo(aDate);
    });
    return list;
  }

  // --- Technician Qualification Test ---

  Future<List<Map<String, dynamic>>> getTestQuestions({String? category}) async {
    final questions = TestQuestionsBank.pickForCategory(category);
    return questions.asMap().entries.map((entry) {
      final q = Map<String, dynamic>.from(entry.value);
      q['id'] = 'q_${category ?? 'general'}_${entry.key}_${q['category']}_${q['difficulty']}';
      return q;
    }).toList();
  }

  int _correctIndexForQuestion(String questionId, List<Map<String, dynamic>> sessionQuestions) {
    for (final q in sessionQuestions) {
      if (q['id'] == questionId) {
        return q['correctIndex'] as int;
      }
    }
    return -1;
  }

  Future<Map<String, dynamic>> submitTest(
    List<Map<String, dynamic>> answers, {
    required List<Map<String, dynamic>> sessionQuestions,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final profileDoc = await _firestore.collection('technician_profiles').doc(uid).get();
    if (!profileDoc.exists) throw Exception('Profile not found');

    int correct = 0;
    for (final ans in answers) {
      final correctIdx = _correctIndexForQuestion(
        ans['questionId'] as String,
        sessionQuestions,
      );
      if (correctIdx >= 0 && correctIdx == ans['optionIndex']) {
        correct++;
      }
    }

    final total = answers.isNotEmpty ? answers.length : 10;
    final scorePercentage = ((correct / total) * 100).round();
    final passed = scorePercentage >= 80;

    int currentTries = profileDoc.data()?['testTries'] ?? 0;
    currentTries++;

    String newStatus;
    if (passed) {
      newStatus = 'pending_admin'; // Passed test, goes to admin for approval
    } else {
      if (currentTries >= 3) {
        newStatus = 'test_locked';
      } else {
        newStatus = 'pending_test';
      }
    }

    await _firestore.collection('technician_profiles').doc(uid).set({
      'testScore': scorePercentage.toDouble(),
      'status': newStatus,
      'testTries': currentTries,
      if (passed) 'testPassedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final updatedProfileDoc = await _firestore.collection('technician_profiles').doc(uid).get();
    final profileData = updatedProfileDoc.data()!;
    profileData['id'] = uid;

    return {
      'score': scorePercentage,
      'passed': passed,
      'passingScore': 80,
      'tries': currentTries,
      'message': passed
          ? 'Congratulations! You passed the test and your application is submitted for approval.'
          : (currentTries >= 3 
              ? 'You failed 3 times. Please contact admin.'
              : 'Test failed. You have ${3 - currentTries} tries left.'),
      'technicianProfile': profileData,
    };
  }

  // --- Customer booking workflow ---

  Future<List<AppUser>> nearbyTechnicians({
    String? category,
    bool urgentOnly = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');

    final customerDoc = await _firestore.collection('users').doc(uid).get();
    if (!customerDoc.exists) throw Exception('Customer profile not found');
    final customerLat = (customerDoc.data()?['latitude'] as num?)?.toDouble() ?? 31.5204;
    final customerLon = (customerDoc.data()?['longitude'] as num?)?.toDouble() ?? 74.3587;

    // Query approved technicians directly: isAvailable=true is set by adminApprove()
    // This avoids fragile status-string cross-checks with technician_profiles
    final userSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'technician')
        .where('isAvailable', isEqualTo: true)
        .get();

    debugPrint('[nearbyTechnicians] Available technician docs found: ${userSnap.docs.length}');

    final results = <AppUser>[];
    for (final doc in userSnap.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;

      final techLat = (data['latitude'] as num?)?.toDouble() ?? 31.5204;
      final techLon = (data['longitude'] as num?)?.toDouble() ?? 74.3587;
      final dist = _haversineKm(customerLat, customerLon, techLat, techLon);

      debugPrint('[nearbyTechnicians] ${data['name']} → dist: ${dist.toStringAsFixed(2)} km');

      if (dist > 15.0) continue; // within 15 km (wider net for demo)

      final techSkills = (data['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      if (category != null && category.isNotEmpty) {
        final catLower = category.toLowerCase();
        final matched = techSkills.any((s) {
          final sl = s.toLowerCase();
          return sl.contains(catLower) || catLower.contains(sl) ||
              (catLower.contains('ac') && sl.contains('ac')) ||
              (catLower.contains('plumb') && sl.contains('plumb')) ||
              (catLower.contains('electric') && sl.contains('electric'));
        });
        if (!matched) {
          debugPrint('[nearbyTechnicians] ${data['name']} skipped — category mismatch ($category vs $techSkills)');
          continue;
        }
      }

      data['distanceKm'] = dist;
      data['checkFee'] = checkFeeForDistanceKm(dist);

      results.add(AppUser.fromJson(data));
    }

    debugPrint('[nearbyTechnicians] Final results: ${results.length}');
    results.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return results;
  }

  Future<Map<String, dynamic>> getTechnicianPublic(String id) async {
    final userDoc = await _firestore.collection('users').doc(id).get();
    if (!userDoc.exists) throw Exception('Technician not found');

    final profileDoc = await _firestore.collection('technician_profiles').doc(id).get();

    final reviewsSnap = await _firestore
        .collection('reviews')
        .where('technicianId', isEqualTo: id)
        .get();

    final userData = userDoc.data()!;
    userData['id'] = id;

    final profileData = profileDoc.exists ? profileDoc.data()! : {};
    profileData['id'] = id;

    final reviewsList = reviewsSnap.docs.map((d) {
      final r = normalizeFirestoreMap(d.data());
      r['id'] = d.id;
      return r;
    }).toList();
    reviewsList.sort((a, b) {
      final aDate = parseFirestoreDate(a['createdAt']);
      final bDate = parseFirestoreDate(b['createdAt']);
      return bDate.compareTo(aDate);
    });

    return {
      'user': userData,
      'profile': profileData,
      'reviews': reviewsList,
    };
  }

  Future<ServiceRequest> createRequest(Map<String, dynamic> body) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');

    final customerDoc = await _firestore.collection('users').doc(uid).get();
    final customerName = customerDoc.data()?['name'] ?? 'Customer';

    String? technicianName;
    if (body['technicianId'] != null) {
      final techDoc = await _firestore.collection('users').doc(body['technicianId']).get();
      technicianName = techDoc.data()?['name'];
    }

    final docRef = await _firestore.collection('service_requests').add({
      'customerId': uid,
      'customerName': customerName,
      'category': body['category'],
      'description': body['description'],
      'type': body['type'],
      'scheduledAt': body['scheduledAt'] != null ? Timestamp.fromDate(DateTime.parse(body['scheduledAt'])) : null,
      'technicianId': body['technicianId'],
      'technicianName': technicianName,
      'address': body['address'] ?? customerDoc.data()?['address'],
      'distanceKm': body['distanceKm'] ?? 2.5,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final requestSnap = await docRef.get();
    final requestData = requestSnap.data()!;
    requestData['id'] = docRef.id;

    if (body['technicianId'] != null) {
      // Create request notification for technician
      final isUrgent = body['type'] == 'urgent';
      final notifTitle = isUrgent ? 'Urgent request' : 'New request';
      final notifBody = '$customerName: ${body['description']}';
      await _firestore.collection('notifications').add({
        'userId': body['technicianId'],
        'title': notifTitle,
        'body': notifBody,
        'requestId': docRef.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Send FCM push to technician even if app is closed
      unawaited(_sendFcmPushToUser(
        body['technicianId'] as String,
        title: notifTitle,
        body: notifBody,
      ));
    }

    return ServiceRequest.fromJson(requestData);
  }

  Future<List<ServiceRequest>> myRequests() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final role = userDoc.data()?['role'] as String?;

    Query query = _firestore.collection('service_requests');
    if (role == 'customer') {
      query = query.where('customerId', isEqualTo: uid);
    } else if (role == 'technician') {
      query = query.where('technicianId', isEqualTo: uid);
    }

    final snap = await query.get();
    final requests = snap.docs.map((doc) {
      final d = normalizeFirestoreMap(doc.data() as Map<String, dynamic>);
      d['id'] = doc.id;
      return ServiceRequest.fromJson(d);
    }).toList();
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests.take(50).toList();
  }

  Future<void> updateRequestStatus(String id, String status) async {
    final requestDoc = await _firestore.collection('service_requests').doc(id).get();
    if (!requestDoc.exists) throw Exception('Request not found');

    await _firestore.collection('service_requests').doc(id).update({
      'status': status,
    });

    final customerId = requestDoc.data()!['customerId'] as String;
    const notifTitle = 'Request update';
    final notifBody = 'Your request is now $status';
    await _firestore.collection('notifications').add({
      'userId': customerId,
      'title': notifTitle,
      'body': notifBody,
      'requestId': id,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Also push to customer even when app is closed
    unawaited(_sendFcmPushToUser(customerId, title: notifTitle, body: notifBody));
  }

  Future<void> setAvailability(bool available) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({'isAvailable': available});
    }
  }

  // --- Real-time Chat ---

  Future<List<ChatMessage>> getMessages(String requestId, String currentUserId) async {
    final snap = await _firestore
        .collection('chat_messages')
        .where('requestId', isEqualTo: requestId)
        .get();

    final messages = snap.docs.map((doc) {
      final data = doc.data();
      final sentAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return ChatMessage(
        id: doc.id,
        requestId: data['requestId'] as String,
        senderId: data['senderId'] as String,
        senderName: data['senderName'] as String,
        text: data['text'] as String,
        audioUrl: data['audioUrl'] as String?,
        sentAt: sentAt,
        isMe: data['senderId'] == currentUserId,
      );
    }).toList();

    // Sort in memory to cover any latency in FieldValue.serverTimestamp writes.
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return messages.take(100).toList();
  }

  Future<void> sendMessage(String requestId, String text, {String? audioUrl}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final senderName = userDoc.data()?['name'] ?? 'User';

    await _firestore.collection('chat_messages').add({
      'requestId': requestId,
      'senderId': uid,
      'senderName': senderName,
      'text': text.trim(),
      'audioUrl': audioUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send FCM push notification to the other party in the chat
    unawaited(_sendChatPushNotification(
      requestId: requestId,
      senderUid: uid,
      senderName: senderName,
      messageText: text.trim(),
    ));
  }

  Future<void> _sendChatPushNotification({
    required String requestId,
    required String senderUid,
    required String senderName,
    required String messageText,
  }) async {
    try {
      final requestDoc = await _firestore.collection('service_requests').doc(requestId).get();
      if (!requestDoc.exists) return;
      final data = requestDoc.data()!;
      final customerId = data['customerId'] as String?;
      final technicianId = data['technicianId'] as String?;

      // Recipient is the OTHER person
      final recipientId = senderUid == customerId ? technicianId : customerId;
      if (recipientId == null) return;

      await _sendFcmPushToUser(
        recipientId,
        title: 'Message from $senderName',
        body: messageText.length > 80 ? '${messageText.substring(0, 80)}...' : messageText,
      );
    } catch (_) {
      // Non-critical
    }
  }

  // --- Reviews ---

  Future<List<Review>> getReviews(String technicianId) async {
    final snap = await _firestore
        .collection('reviews')
        .where('technicianId', isEqualTo: technicianId)
        .get();

    final reviews = snap.docs.map((doc) {
      final d = normalizeFirestoreMap(doc.data());
      d['id'] = doc.id;
      return Review.fromJson(d);
    }).toList();

    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews.take(50).toList();
  }

  Future<void> addReview({
    required String technicianId,
    String? requestId,
    required double rating,
    String? comment,
    required double repairCost,
    String? actualIssue,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');

    if (requestId != null) {
      final existing = await _firestore
          .collection('reviews')
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('You already reviewed this order');
      }
    }

    final customerDoc = await _firestore.collection('users').doc(uid).get();
    final customerName = customerDoc.data()?['name'] ?? 'Customer';

    await _firestore.collection('reviews').add({
      'technicianId': technicianId,
      'customerId': uid,
      'customerName': customerName,
      'requestId': requestId,
      'rating': rating,
      'comment': comment ?? '',
      'repairCost': repairCost,
      'actualIssue': actualIssue ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update technician review count and average rating
    final reviewsSnap = await _firestore
        .collection('reviews')
        .where('technicianId', isEqualTo: technicianId)
        .get();

    int count = reviewsSnap.docs.length;
    double sum = 0.0;
    for (final doc in reviewsSnap.docs) {
      sum += (doc.data()['rating'] as num).toDouble();
    }
    double avg = count > 0 ? (sum / count) : 4.5;
    avg = (avg * 10).round() / 10;

    await _firestore.collection('users').doc(technicianId).update({
      'rating': avg,
      'reviewCount': count,
    });

    // Feed AI learning engine with real repair data
    if (actualIssue != null && actualIssue.trim().isNotEmpty && repairCost > 0) {
      unawaited(_updateAiLearning(
        actualIssue: actualIssue.trim(),
        repairCost: repairCost,
        requestId: requestId,
      ));
    }
  }

  Future<void> _updateAiLearning({
    required String actualIssue,
    required double repairCost,
    String? requestId,
  }) async {
    try {
      String category = 'Electrician';
      if (requestId != null) {
        final reqDoc = await _firestore.collection('service_requests').doc(requestId).get();
        category = reqDoc.data()?['category'] as String? ?? category;
      }
      final learning = AiLearningService(firestore: _firestore);
      await learning.learnFromReview(
        actualIssue: actualIssue,
        repairCost: repairCost,
        category: category,
      );
    } catch (e) {
      debugPrint('[FixxiApi] AI learning update failed: $e');
    }
  }

  // --- Support Reports ---

  Future<void> submitReport({
    required String reportedUserId,
    required String reason,
    String? reviewId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');
    if (uid == reportedUserId) {
      throw Exception('You cannot report yourself');
    }

    final reporterDoc = await _firestore.collection('users').doc(uid).get();
    final reportedDoc = await _firestore.collection('users').doc(reportedUserId).get();

    await _firestore.collection('reports').add({
      'reporterId': uid,
      'reporterName': reporterDoc.data()?['name'] ?? 'User',
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedDoc.data()?['name'] ?? 'User',
      'reason': reason,
      'reviewId': reviewId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Notifications ---

  Future<List<AppNotification>> getNotifications() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');

    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .get();

    final notifications = snap.docs.map((doc) {
      final d = normalizeFirestoreMap(doc.data());
      d['id'] = doc.id;
      return AppNotification.fromJson(d);
    }).toList();
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications.take(50).toList();
  }

  Future<void> markNotificationsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');

    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // --- Admin User Profile & Management ---

  Future<List<Map<String, dynamic>>> adminListUsers({String? role}) async {
    await _requireAdmin();
    Query query = _firestore.collection('users');
    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }
    final snap = await query.get();

    final users = snap.docs.map((doc) {
      final d = normalizeFirestoreMap(doc.data() as Map<String, dynamic>);
      d['id'] = doc.id;
      return d;
    }).where((u) => u['role'] != 'admin').toList();

    users.sort((a, b) {
      final aDate = parseFirestoreDate(a['createdAt']);
      final bDate = parseFirestoreDate(b['createdAt']);
      return bDate.compareTo(aDate);
    });
    return users;
  }

  Future<Map<String, dynamic>> adminGetUserProfile(String id) async {
    await _requireAdmin();
    final userDoc = await _firestore.collection('users').doc(id).get();
    if (!userDoc.exists) throw Exception('User not found');

    final userData = normalizeFirestoreMap(userDoc.data()!);
    userData['id'] = id;

    Map<String, dynamic>? techProfileData;
    if (userData['role'] == 'technician') {
      final techDoc = await _firestore.collection('technician_profiles').doc(id).get();
      if (techDoc.exists) {
        techProfileData = techDoc.data()!;
        techProfileData['id'] = id;
      }
    }

    // Get activities (requests, reviews, reports)
    final requestField = userData['role'] == 'customer' ? 'customerId' : 'technicianId';
    final requestSnap = await _firestore
        .collection('service_requests')
        .where(requestField, isEqualTo: id)
        .get();

    final reviewField = userData['role'] == 'technician' ? 'technicianId' : 'customerId';
    final reviewsSnap = await _firestore
        .collection('reviews')
        .where(reviewField, isEqualTo: id)
        .get();

    final reportsAgainstSnap = await _firestore
        .collection('reports')
        .where('reportedUserId', isEqualTo: id)
        .get();

    final reportsFiledSnap = await _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: id)
        .get();

    List<Map<String, dynamic>> mapDocs(QuerySnapshot snap) {
      final list = snap.docs.map((d) {
        final map = normalizeFirestoreMap(d.data() as Map<String, dynamic>);
        map['id'] = d.id;
        return map;
      }).toList();
      list.sort((a, b) {
        final aDate = parseFirestoreDate(a['createdAt']);
        final bDate = parseFirestoreDate(b['createdAt']);
        return bDate.compareTo(aDate);
      });
      return list.take(30).toList();
    }

    return {
      'user': userData,
      'technicianProfile': techProfileData,
      'activities': {
        'requests': mapDocs(requestSnap),
        'reviews': mapDocs(reviewsSnap),
        'reportsAgainst': mapDocs(reportsAgainstSnap),
        'reportsFiled': mapDocs(reportsFiledSnap),
      }
    };
  }

  Future<void> adminSuspendUser(
    String id, {
    required String duration,
    String? reason,
  }) async {
    await _requireAdmin();
    DateTime? suspendedUntil;
    final now = DateTime.now();
    if (duration == 'week') {
      suspendedUntil = now.add(const Duration(days: 7));
    } else if (duration == 'month') {
      suspendedUntil = now.add(const Duration(days: 30));
    }

    final fallbackReason = reason ?? 'Suspended by admin';
    await _firestore.collection('users').doc(id).update({
      'isSuspended': true,
      'suspensionType': duration,
      'suspendedUntil': suspendedUntil != null ? Timestamp.fromDate(suspendedUntil) : null,
      'suspensionReason': fallbackReason,
      'isAvailable': false,
    });

    await _firestore.collection('notifications').add({
      'userId': id,
      'title': 'Account suspended',
      'body': fallbackReason,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminUnsuspendUser(String id) async {
    await _requireAdmin();
    await _firestore.collection('users').doc(id).update({
      'isSuspended': false,
      'suspensionType': FieldValue.delete(),
      'suspendedUntil': FieldValue.delete(),
      'suspensionReason': '',
    });

    await _firestore.collection('notifications').add({
      'userId': id,
      'title': 'Account restored',
      'body': 'Your account suspension has been lifted by admin.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminNotifyUser(
    String id, {
    required String title,
    required String body,
  }) async {
    await _requireAdmin();
    await _firestore.collection('notifications').add({
      'userId': id,
      'title': title.trim(),
      'body': body.trim(),
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> adminListReports({String? status}) async {
    await _requireAdmin();
    Query query = _firestore.collection('reports');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();

    final reports = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final d = normalizeFirestoreMap(doc.data() as Map<String, dynamic>);
      d['id'] = doc.id;

      if (d['reporterName'] == null) {
        final reporterDoc = await _firestore.collection('users').doc(d['reporterId'] as String).get();
        d['reporterName'] = reporterDoc.data()?['name'] ?? 'User';
      }
      if (d['reportedUserName'] == null) {
        final reportedDoc =
            await _firestore.collection('users').doc(d['reportedUserId'] as String).get();
        d['reportedUserName'] = reportedDoc.data()?['name'] ?? 'User';
      }
      reports.add(d);
    }

    reports.sort((a, b) {
      final aDate = parseFirestoreDate(a['createdAt']);
      final bDate = parseFirestoreDate(b['createdAt']);
      return bDate.compareTo(aDate);
    });
    return reports;
  }

  Future<void> adminUpdateReport(
    String id, {
    String? status,
    String? adminNote,
  }) async {
    await _requireAdmin();
    final updateData = <String, dynamic>{};
    if (status != null) updateData['status'] = status;
    if (adminNote != null) updateData['adminNote'] = adminNote;

    await _firestore.collection('reports').doc(id).update(updateData);
  }
}
