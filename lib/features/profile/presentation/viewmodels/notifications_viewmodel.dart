import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class NotificationsViewModel extends ChangeNotifier {
  bool isLoading = false;
  List<NotificationItem> notifications = [];

  Future<void> fetchNotifications() async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.getMyNotifications),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['notifications'] != null) {
          final List<dynamic> list = data['notifications'];
          notifications = list.map((n) => NotificationItem.fromJson(n)).toList();
        }
      }
    } catch (e) {
      print('Notifications Fetch Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
