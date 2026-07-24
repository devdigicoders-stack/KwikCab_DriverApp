import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kwikcabdriver/core/network/app_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';

class SupportTicket {
  final String id;
  final String subject;
  final String message;
  final String status;
  final String createdAt;
  final String? adminReply;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.adminReply,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['_id'] ?? '',
      subject: json['subject'] ?? 'No Subject',
      message: json['message'] ?? '',
      status: json['status'] ?? 'Open',
      createdAt: json['createdAt'] ?? '',
      adminReply: json['reply'], // API returns 'reply'
    );
  }
}

class HelpSupportViewModel extends ChangeNotifier {
  bool isLoading = false;
  List<SupportTicket> tickets = [];
  Map<String, dynamic> summary = {'total': 0, 'open': 0, 'closed': 0, 'inProgress': 0};

  Future<void> fetchSupportData() async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      // Fetch Summary
      final summaryRes = await http.get(
        Uri.parse(ApiConstants.getSupportSummary),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (summaryRes.statusCode == 200) {
        final data = jsonDecode(summaryRes.body);
        if (data['success'] == true) {
          summary = data['summary'] ?? data; // Depending on actual API response format
        }
      }

      // Fetch Tickets
      final ticketsRes = await http.get(
        Uri.parse(ApiConstants.getMyTickets),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (ticketsRes.statusCode == 200) {
        final data = jsonDecode(ticketsRes.body);
        if (data['success'] == true && data['requests'] != null) { // API returns 'requests'
          final List<dynamic> list = data['requests'];
          tickets = list.map((t) => SupportTicket.fromJson(t)).toList();
        }
      }
    } catch (e) {
      print('Support Fetch Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTicket(String subject, String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final response = await http.post(
        Uri.parse(ApiConstants.createSupportTicket),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'subject': subject,
          'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await fetchSupportData(); // Refresh list & summary
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Create Ticket Error: $e');
      return false;
    }
  }
}
