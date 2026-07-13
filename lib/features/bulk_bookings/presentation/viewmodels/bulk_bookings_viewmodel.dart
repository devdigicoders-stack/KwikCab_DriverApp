import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';

class BulkAssignment {
  final String id;
  final String pickupAddress;
  final String dropAddress;
  final String pickupDateTime;
  final String status;
  final String startOtp;
  final num offeredPrice;
  final num advancePaid;
  final Map<String, dynamic>? myCar;
  final String myStatus;
  
  // Detailed fields
  final String? customerName;
  final String? customerPhone;
  final Map<String, dynamic>? createdBy;
  final List<dynamic>? assignedDrivers;
  final String? notes;
  final Map<String, dynamic>? finalPayment;
  final bool isOutstation;
  final num mcdStateTaxApplied;

  BulkAssignment({
    required this.id,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupDateTime,
    required this.status,
    required this.startOtp,
    required this.offeredPrice,
    required this.advancePaid,
    this.myCar,
    required this.myStatus,
    this.customerName,
    this.customerPhone,
    this.createdBy,
    this.assignedDrivers,
    this.notes,
    this.finalPayment,
    this.isOutstation = false,
    this.mcdStateTaxApplied = 0,
  });

  factory BulkAssignment.fromJson(Map<String, dynamic> json) {
    return BulkAssignment(
      id: json['_id'] ?? '',
      pickupAddress: json['pickup']?['address'] ?? 'Unknown',
      dropAddress: json['drop']?['address'] ?? 'Unknown',
      pickupDateTime: json['pickupDateTime'] ?? '',
      status: json['status'] ?? 'Pending',
      startOtp: json['startOtp'] ?? '',
      offeredPrice: json['offeredPrice'] ?? 0,
      advancePaid: json['advancePayment']?['amount'] ?? 0,
      myCar: json['myCar'],
      myStatus: json['myStatus'] ?? 'Pending',
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      createdBy: json['createdBy'],
      assignedDrivers: json['assignedDrivers'],
      notes: json['notes'],
      finalPayment: json['finalPayment'],
      isOutstation: json['isOutstation'] ?? false,
      mcdStateTaxApplied: json['mcdStateTaxApplied'] ?? 0,
    );
  }
}

class BulkBookingsViewModel extends ChangeNotifier {
  bool isLoading = false;
  List<BulkAssignment> assignments = [];

  Future<void> fetchAssignments() async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.getMyBulkAssignments),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['assignments'] != null) {
          final List<dynamic> list = data['assignments'];
          assignments = list.map((a) => BulkAssignment.fromJson(a)).toList();
        }
      }
    } catch (e) {
      print('Bulk Assignments Fetch Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startTrip(String bookingId, String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final response = await http.post(
        Uri.parse('${ApiConstants.startBulkBooking}/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'otp': otp}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await fetchAssignments();
        return true;
      } else {
        throw Exception(data['message'] ?? 'Failed to start trip');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> endTrip(String bookingId, String paymentMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final response = await http.post(
        Uri.parse('${ApiConstants.endBulkBooking}/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'paymentMode': paymentMode}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await fetchAssignments();
        return data; // Return full data in case there is a paymentLink
      } else {
        throw Exception(data['message'] ?? 'Failed to end trip');
      }
    } catch (e) {
      rethrow;
    }
  }
}
