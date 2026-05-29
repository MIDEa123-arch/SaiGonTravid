import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_app/core/constants.dart';
import 'package:travel_app/models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';


/// AuthService – Quản lý trạng thái đăng nhập người dùng.
///
/// Gọi Auth API thật tại ${ApiConstants.authEndpoint}
/// Session được lưu local bằng SharedPreferences.
class AuthService {
  static const String _userKey = 'current_user';
  static const String _loggedInKey = 'is_logged_in';

  /// Notifier toàn cục – UI lắng nghe để rebuild khi login/logout
  static final ValueNotifier<AppUser?> currentUserNotifier =
      ValueNotifier<AppUser?>(null);

  /// Kiểm tra nhanh trạng thái đăng nhập (sync)
  static bool get isLoggedIn => currentUserNotifier.value != null;

  /// User hiện tại (nullable)
  static AppUser? get currentUser => currentUserNotifier.value;

  // ────────────────────────────────────────────────────────────────────────────
  // Session management
  // ────────────────────────────────────────────────────────────────────────────

  /// Tải trạng thái đăng nhập từ bộ nhớ cục bộ khi app khởi động
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final bool loggedIn = prefs.getBool(_loggedInKey) ?? false;
    if (!loggedIn) return;

    final String? userJson = prefs.getString(_userKey);
    if (userJson == null) return;

    try {
      final Map<String, dynamic> data = json.decode(userJson);
      currentUserNotifier.value = AppUser.fromJson(data);
    } catch (_) {
      await _clearSession(prefs);
    }
  }

  /// Lưu user vào bộ nhớ và cập nhật notifier
  static Future<void> signIn(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_userKey, json.encode(user.toJson()));
    currentUserNotifier.value = user;
  }

  /// Đăng xuất – xóa toàn bộ session local
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    currentUserNotifier.value = null;
  }

  /// Đăng nhập bằng tài khoản Google thật qua package google_sign_in
  /// -> POST ${ApiConstants.authEndpoint}/google
  static Future<AuthResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '450334915499-860icr7vp9fgbi82nnd8g2dlnn63bqhp.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      
      // Mở Google account picker
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult.error('Đã hủy đăng nhập Google.');
      }
      
      // Lấy credentials (idToken)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final response = await http
          .post(
            Uri.parse('${ApiConstants.authEndpoint}/google'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: json.encode({
              'google_id': googleUser.id,
              'email': googleUser.email,
              'full_name': googleUser.displayName ?? 'Google User',
              'avatar_url': googleUser.photoUrl,
              'id_token': googleAuth.idToken,
            }),
          )
          .timeout(const Duration(seconds: 15));
          
      final body = json.decode(utf8.decode(response.bodyBytes));
      
      if (response.statusCode == 200) {
        final user = AppUser(
          userId: body['user_id'] as int,
          fullName: body['full_name'] as String,
          email: body['email'] as String,
          avatarUrl: body['avatar_url'] as String?,
          googleId: body['google_id'] as String?,
        );
        await signIn(user);
        return AuthResult.success(user, message: body['message'] as String?);
      } else {
        final detail = body['detail'] as String? ?? 'Đăng nhập Google thất bại.';
        return AuthResult.error(detail);
      }
    } on http.ClientException {
      return AuthResult.error('Không thể kết nối đến server. Kiểm tra kết nối mạng.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return AuthResult.error('Server không phản hồi. Vui lòng thử lại.');
      }
      return AuthResult.error('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  static Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_loggedInKey);
    await prefs.remove(_userKey);
  }

  /// Cập nhật thông tin user (ví dụ sau khi đổi avatar)
  static Future<void> updateUser(AppUser updatedUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(updatedUser.toJson()));
    currentUserNotifier.value = updatedUser;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Auth API calls (thật – không dùng mock)
  // ────────────────────────────────────────────────────────────────────────────

  /// Đăng nhập bằng email/password
  /// → POST ${ApiConstants.authEndpoint}/login
  static Future<AuthResult> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    // Client-side validation cơ bản
    if (email.trim().isEmpty || password.isEmpty) {
      return AuthResult.error('Vui lòng nhập email và mật khẩu.');
    }

    try {
      final uri = Uri.parse('${ApiConstants.authEndpoint}/login');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: json.encode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final user = AppUser(
          userId: body['user_id'] as int,
          fullName: body['full_name'] as String,
          email: body['email'] as String,
          avatarUrl: body['avatar_url'] as String?,
        );
        await signIn(user);
        return AuthResult.success(user);
      } else {
        // 401, 400 → đọc detail từ backend
        final detail = body['detail'] as String? ?? 'Đăng nhập thất bại.';
        return AuthResult.error(detail);
      }
    } on http.ClientException {
      return AuthResult.error(
        'Không thể kết nối đến server. Kiểm tra kết nối mạng.',
      );
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return AuthResult.error('Server không phản hồi. Vui lòng thử lại.');
      }
      return AuthResult.error('Đã xảy ra lỗi. Vui lòng thử lại.');
    }
  }

  /// Đăng ký tài khoản mới
  /// → POST ${ApiConstants.authEndpoint}/register
  static Future<AuthResult> registerWithEmailPassword(
    String fullName,
    String email,
    String password,
  ) async {
    // Client-side validation
    if (fullName.trim().isEmpty) {
      return AuthResult.error('Vui lòng nhập họ và tên.');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return AuthResult.error('Email không hợp lệ.');
    }
    if (password.length < 6) {
      return AuthResult.error('Mật khẩu phải có ít nhất 6 ký tự.');
    }

    try {
      final uri = Uri.parse('${ApiConstants.authEndpoint}/register');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: json.encode({
              'full_name': fullName.trim(),
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        final user = AppUser(
          userId: body['user_id'] as int,
          fullName: body['full_name'] as String,
          email: body['email'] as String,
          avatarUrl: body['avatar_url'] as String?,
        );
        await signIn(user);
        return AuthResult.success(
          user,
          message: body['message'] as String?,
        );
      } else {
        final detail =
            body['detail'] as String? ?? 'Đăng ký thất bại. Vui lòng thử lại.';
        return AuthResult.error(detail);
      }
    } on http.ClientException {
      return AuthResult.error(
        'Không thể kết nối đến server. Kiểm tra kết nối mạng.',
      );
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return AuthResult.error('Server không phản hồi. Vui lòng thử lại.');
      }
      return AuthResult.error('Đã xảy ra lỗi. Vui lòng thử lại.');
    }
  }

  /// Yêu cầu đặt lại mật khẩu
  /// → POST ${ApiConstants.authEndpoint}/forgot-password
  static Future<AuthResult> sendPasswordReset(String email) async {
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return AuthResult.error('Email không hợp lệ.');
    }

    try {
      final uri = Uri.parse('${ApiConstants.authEndpoint}/forgot-password');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: json.encode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 15));

      final body = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final message = body['message'] as String? ??
            'Nếu email tồn tại, chúng tôi đã gửi liên kết đặt lại mật khẩu.';
        return AuthResult.successMessage(message);
      } else {
        final detail = body['detail'] as String? ?? 'Đã xảy ra lỗi.';
        return AuthResult.error(detail);
      }
    } on http.ClientException {
      return AuthResult.error(
        'Không thể kết nối đến server. Kiểm tra kết nối mạng.',
      );
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return AuthResult.error('Server không phản hồi. Vui lòng thử lại.');
      }
      return AuthResult.error('Đã xảy ra lỗi. Vui lòng thử lại.');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthResult – kết quả trả về từ các thao tác Auth
// ─────────────────────────────────────────────────────────────────────────────
class AuthResult {
  final bool isSuccess;
  final AppUser? user;
  final String? message;
  final String? errorMessage;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.message,
    this.errorMessage,
  });

  factory AuthResult.success(AppUser user, {String? message}) =>
      AuthResult._(isSuccess: true, user: user, message: message);

  factory AuthResult.successMessage(String message) =>
      AuthResult._(isSuccess: true, message: message);

  factory AuthResult.error(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
