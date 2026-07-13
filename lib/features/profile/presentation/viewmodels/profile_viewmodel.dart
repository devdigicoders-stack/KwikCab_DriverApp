import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';

class ProfileViewModel extends ChangeNotifier {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _driverData;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get driverData => _driverData;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    // Don't call notifyListeners here if we don't want to show a spinner immediately when the class is first created,
    // but since we want to show a spinner on initial load, it's fine.
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');

      if (token == null) {
        _error = 'No authentication token found. Please login again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.driverProfile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        _driverData = responseBody['driver'];
        _isLoading = false;
      } else {
        _error = responseBody['message'] ?? 'Failed to fetch profile';
        _isLoading = false;
      }
    } catch (e) {
      _error = 'Failed to connect to server. Please try again.';
      _isLoading = false;
    }
    notifyListeners();
  }
}
