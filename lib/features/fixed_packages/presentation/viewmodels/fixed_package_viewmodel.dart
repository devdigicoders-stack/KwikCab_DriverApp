import 'package:flutter/material.dart';
import '../../data/repositories/fixed_package_service.dart';

class FixedPackageViewModel extends ChangeNotifier {
  final FixedPackageService _service = FixedPackageService.instance;

  List<dynamic> marketplacePackages = [];
  List<dynamic> acceptedPackages = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchMarketplacePackages() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _service.getMarketplacePackages();
      if (res['success'] == true) {
        // Assume backend returns 'bookings' or 'packages' array
        marketplacePackages = res['bookings'] ?? res['data'] ?? [];
      } else {
        error = res['message'] ?? 'Failed to fetch fixed packages';
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAcceptedPackages() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _service.getMyAcceptedPackages();
      if (res['success'] == true) {
        acceptedPackages = res['bookings'] ?? res['data'] ?? [];
      } else {
        error = res['message'] ?? 'Failed to fetch accepted packages';
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> acceptPackage(String packageId) async {
    return await _service.acceptPackage(packageId);
  }

  Future<Map<String, dynamic>> completePackage(String packageId) async {
    return await _service.completePackage(packageId);
  }
}
