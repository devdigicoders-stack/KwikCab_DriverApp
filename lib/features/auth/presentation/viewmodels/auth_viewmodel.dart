import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kwikcabdriver/core/network/app_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/utils/auth_response.dart';

class AuthViewModel extends ChangeNotifier {
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  String get email => _email;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get obscurePassword => _obscurePassword;

  void setEmail(String v) { _email = v.trim(); _error = null; notifyListeners(); }
  void setPassword(String v) { _password = v; _error = null; notifyListeners(); }
  void togglePassword() { _obscurePassword = !_obscurePassword; notifyListeners(); }

  bool _isValidEmail(String e) => RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(e);

  /// ✅ Login ke baad silently FCM token backend mein save karta hai
  /// Non-blocking hai — login flow rok nahi dega
  Future<void> _updateFcmToken(String jwtToken) async {
    try {
      // Firebase se is device ka unique FCM token lo
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        debugPrint('FCM Token nahi mila — skip kar rahe hain');
        return;
      }

      debugPrint('FCM Token mila: ${fcmToken.substring(0, 20)}...');

      // Backend pe PUT /api/drivers/update-fcm-token call karo
      final response = await http.put(
        Uri.parse(ApiConstants.updateFcmToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM Token backend mein save ho gaya!');
      } else {
        debugPrint('⚠️ FCM Token save failed: ${response.statusCode}');
      }
    } catch (e) {
      // Silent fail — FCM error se login flow break nahi hona chahiye
      debugPrint('FCM Token Update Error (non-blocking): $e');
    }
  }

  Future<AuthResponse> login() async {
    if (!_isValidEmail(_email)) {
      _error = 'Enter a valid email address';
      notifyListeners();
      return AuthResponse(status: LoginStatus.invalidCredentials, message: _error!);
    }
    if (_password.isEmpty) {
      _error = 'Enter your password';
      notifyListeners();
      return AuthResponse(status: LoginStatus.invalidCredentials, message: _error!);
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.driverLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email,
          'password': _password,
        }),
      );

      dynamic responseBody;
      try {
        responseBody = jsonDecode(response.body);
      } catch (_) {
        _isLoading = false;
        _error = 'Server returned an invalid response (Error ${response.statusCode})';
        notifyListeners();
        return AuthResponse(status: LoginStatus.serverError, message: _error!);
      }

      final int statusCode = response.statusCode;
      final String message = responseBody['message'] ?? 'Unknown error';

      if (statusCode == 200 && responseBody['success'] == true) {
        // ✅ LOGIN SUCCESS — Token + Driver data save karo
        final token = responseBody['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('driver_isLoggedIn', true);
        await prefs.setString('driver_email', _email);
        if (token != null) {
          await prefs.setString('driver_token', token);
          // 🔔 FCM Token turant background mein update karo
          // await nahi laga raha — login screen wait nahi karegi
          _updateFcmToken(token);
        }
        _isLoading = false;
        notifyListeners();
        return AuthResponse(status: LoginStatus.success, message: message, data: responseBody['driver']);

      } else if (statusCode == 403) {
        _isLoading = false;
        notifyListeners();
        final lowerMessage = message.toLowerCase();
        if (lowerMessage.contains('rejected')) {
          return AuthResponse(status: LoginStatus.rejected, message: message, data: responseBody['driver']);
        } else if (lowerMessage.contains('pending')) {
          return AuthResponse(status: LoginStatus.pending, message: message);
        } else if (lowerMessage.contains('deactivated') || lowerMessage.contains('blocked') || lowerMessage.contains('ban')) {
          return AuthResponse(status: LoginStatus.blocked, message: message);
        } else {
          return AuthResponse(status: LoginStatus.serverError, message: message);
        }
      } else {
        _error = message;
        _isLoading = false;
        notifyListeners();
        if (statusCode == 400) return AuthResponse(status: LoginStatus.invalidCredentials, message: message);
        if (statusCode == 404) return AuthResponse(status: LoginStatus.notFound, message: message);
        return AuthResponse(status: LoginStatus.serverError, message: message);
      }
    } catch (e) {
      debugPrint('API Error: $e');
      _isLoading = false;
      _error = 'Failed to connect to server. Please try again.';
      notifyListeners();
      return AuthResponse(status: LoginStatus.networkError, message: _error!);
    }
  }
}
