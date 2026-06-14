import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/review.dart';
import '../models/service_request.dart';
import '../models/technician_profile.dart';
import '../models/user_role.dart';
import 'api_client.dart';

class LoginResult {
  LoginResult({
    required this.user,
    this.technicianProfile,
  });

  final AppUser user;
  final TechnicianProfile? technicianProfile;
}

class FixxiApi {
  FixxiApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> sendCustomerOtp(String email) async {
    final res = await _client.authDio.post('customer/send-otp', data: {'email': email});
    return res.data as Map<String, dynamic>;
  }

  Future<String> verifyCustomerOtp(String email, String otp) async {
    final res = await _client.authDio.post(
      'customer/verify-otp',
      data: {'email': email, 'otp': otp},
    );
    return res.data['otpToken'] as String;
  }

  Future<LoginResult> registerCustomer({
    required String name,
    required String phone,
    required String address,
    required String email,
    required String password,
    required String otpToken,
  }) async {
    final res = await _client.authDio.post('customer/register', data: {
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'password': password,
      'otpToken': otpToken,
    });
    final token = res.data['token'] as String;
    await _client.setToken(token);
    return _parseLogin(res.data as Map<String, dynamic>);
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
    final form = FormData.fromMap({
      'name': name,
      'fatherName': fatherName,
      'address': address,
      'phone': phone,
      'email': email,
      'password': password,
      'skills': jsonEncode(skills),
      'extraSkills': extraSkills ?? '',
      'idCardFront': await MultipartFile.fromFile(idCardFront.path, filename: 'front.jpg'),
      'idCardBack': await MultipartFile.fromFile(idCardBack.path, filename: 'back.jpg'),
    });

    final res = await _client.authDio.post(
      'technician/register',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final token = res.data['token'] as String;
    await _client.setToken(token);
    return _parseLogin(res.data as Map<String, dynamic>);
  }

  Future<LoginResult> login(String email, String password, {UserRole? role}) async {
    final res = await _client.authDio.post('login', data: {
      'email': email,
      'password': password,
      if (role != null) 'role': role.name,
    });
    final token = res.data['token'] as String;
    await _client.setToken(token);
    return _parseLogin(res.data as Map<String, dynamic>);
  }

  Future<LoginResult> getMe() async {
    final res = await _client.authDio.get('me');
    return _parseLogin(res.data as Map<String, dynamic>);
  }

  Future<void> logout() => _client.setToken(null);

  LoginResult _parseLogin(Map<String, dynamic> data) {
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    TechnicianProfile? profile;
    if (data['technicianProfile'] != null) {
      profile = TechnicianProfile.fromJson(
        data['technicianProfile'] as Map<String, dynamic>,
      );
    }
    return LoginResult(user: user, technicianProfile: profile);
  }

  Future<List<Map<String, dynamic>>> adminListTechnicians({String? status}) async {
    final res = await _client.adminDio.get(
      '/technicians',
      queryParameters: status != null ? {'status': status} : null,
    );
    return (res.data['technicians'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> adminGetTechnician(String id) async {
    final res = await _client.adminDio.get('technicians/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<void> adminApprove(String id) async {
    await _client.adminDio.patch('technicians/$id/approve');
  }

  Future<void> adminReject(String id, {String? reason}) async {
    await _client.adminDio.patch('technicians/$id/reject', data: {'reason': reason});
  }

  Future<List<Map<String, dynamic>>> getTestQuestions() async {
    final res = await _client.testDio.get('questions');
    return (res.data['questions'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> submitTest(List<Map<String, dynamic>> answers) async {
    final res = await _client.testDio.post('submit', data: {'answers': answers});
    return res.data as Map<String, dynamic>;
  }

  Future<List<AppUser>> nearbyTechnicians({
    String? category,
    bool urgentOnly = false,
  }) async {
    final res = await _client.dio.get(
      'technicians/nearby',
      queryParameters: {
        if (category != null) 'category': category,
        if (urgentOnly) 'urgentOnly': 'true',
      },
    );
    return (res.data['technicians'] as List)
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getTechnicianPublic(String id) async {
    final res = await _client.dio.get('technicians/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<ServiceRequest> createRequest(Map<String, dynamic> body) async {
    final res = await _client.dio.post('requests', data: body);
    return ServiceRequest.fromJson(res.data['request'] as Map<String, dynamic>);
  }

  Future<List<ServiceRequest>> myRequests() async {
    final res = await _client.dio.get('requests');
    return (res.data['requests'] as List)
        .map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateRequestStatus(String id, String status) async {
    await _client.dio.patch('requests/$id/status', data: {'status': status});
  }

  Future<void> setAvailability(bool available) async {
    await _client.dio.patch('technician/availability', data: {'available': available});
  }

  Future<List<ChatMessage>> getMessages(String requestId, String currentUserId) async {
    final res = await _client.dio.get('chat/$requestId');
    return (res.data['messages'] as List)
        .map((e) {
          final m = ChatMessage.fromJson(e as Map<String, dynamic>);
          return ChatMessage(
            id: m.id,
            requestId: m.requestId,
            senderId: m.senderId,
            senderName: m.senderName,
            text: m.text,
            sentAt: m.sentAt,
            isMe: m.senderId == currentUserId,
          );
        })
        .toList();
  }

  Future<void> sendMessage(String requestId, String text) async {
    await _client.dio.post('chat/$requestId', data: {'text': text});
  }

  Future<List<Review>> getReviews(String technicianId) async {
    final res = await _client.dio.get('technicians/$technicianId/reviews');
    return (res.data['reviews'] as List)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addReview({
    required String technicianId,
    String? requestId,
    required double rating,
    String? comment,
    required double repairCost,
    String? actualIssue,
  }) async {
    await _client.dio.post('reviews', data: {
      'technicianId': technicianId,
      'requestId': requestId,
      'rating': rating,
      'comment': comment,
      'repairCost': repairCost,
      if (actualIssue != null && actualIssue.isNotEmpty) 'actualIssue': actualIssue,
    });
  }

  Future<void> submitReport({
    required String reportedUserId,
    required String reason,
    String? reviewId,
  }) async {
    await _client.dio.post('reports', data: {
      'reportedUserId': reportedUserId,
      'reason': reason,
      if (reviewId != null) 'reviewId': reviewId,
    });
  }

  Future<List<AppNotification>> getNotifications() async {
    final res = await _client.dio.get('notifications');
    return (res.data['notifications'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationsRead() async {
    await _client.dio.patch('notifications/read');
  }

  Future<List<Map<String, dynamic>>> adminListUsers({String? role}) async {
    final res = await _client.adminDio.get(
      'users',
      queryParameters: role != null ? {'role': role} : null,
    );
    return (res.data['users'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> adminGetUserProfile(String id) async {
    final res = await _client.adminDio.get('users/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<void> adminSuspendUser(
    String id, {
    required String duration,
    String? reason,
  }) async {
    await _client.adminDio.patch('users/$id/suspend', data: {
      'duration': duration,
      'reason': reason,
    });
  }

  Future<void> adminUnsuspendUser(String id) async {
    await _client.adminDio.patch('users/$id/unsuspend');
  }

  Future<void> adminNotifyUser(
    String id, {
    required String title,
    required String body,
  }) async {
    await _client.adminDio.post('users/$id/notify', data: {
      'title': title,
      'body': body,
    });
  }

  Future<List<Map<String, dynamic>>> adminListReports({String? status}) async {
    final res = await _client.adminDio.get(
      'reports',
      queryParameters: status != null ? {'status': status} : null,
    );
    return (res.data['reports'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> adminUpdateReport(
    String id, {
    String? status,
    String? adminNote,
  }) async {
    await _client.adminDio.patch('reports/$id', data: {
      if (status != null) 'status': status,
      if (adminNote != null) 'adminNote': adminNote,
    });
  }
}
