import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_constants.dart';

class EarningEntry {
  final String id;
  final String title;
  final String description;
  final String date;
  final String amount;
  final String type;
  final String status;
  final IconData icon;

  const EarningEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.amount,
    required this.type,
    required this.status,
    required this.icon,
  });
}

class EarningsViewModel extends ChangeNotifier {
  List<EarningEntry> entries = [];
  double walletBalance = 0;
  double totalEarnings = 0;
  bool isLoading = true;

  Future<void> fetchWalletDetails() async {
    try {
      isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.getWallet),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          walletBalance = (data['walletBalance'] ?? 0).toDouble();
          totalEarnings = (data['totalEarnings'] ?? 0).toDouble();
          
          final List<dynamic> txs = data['transactions'] ?? [];
          entries = txs.map((tx) {
            final isCredit = tx['type'] == 'Credit';
            final dateObj = DateTime.tryParse(tx['createdAt'] ?? '');
            final dateStr = dateObj != null ? DateFormat('dd MMM, hh:mm a').format(dateObj) : 'Unknown Date';
            return EarningEntry(
              id: tx['_id'] ?? '',
              title: tx['category'] ?? 'Transaction',
              description: tx['description'] ?? '',
              date: dateStr,
              amount: '₹${tx['amount']}',
              type: tx['type'] ?? '',
              status: tx['status'] ?? 'Completed',
              icon: isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            );
          }).toList();
        }
      }
    } catch (e) {
      print('Wallet Fetch Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestWithdrawal(double amount, String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final response = await http.post(
        Uri.parse(ApiConstants.requestWithdrawal),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Refresh the wallet details to show the new pending transaction and updated balance
          await fetchWalletDetails();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Withdrawal Error: $e');
      return false;
    }
  }
}
