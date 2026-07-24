import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';

class FixedPackageDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> package;
  const FixedPackageDetailsScreen({super.key, required this.package});

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = package['pickupLocation'] ?? package['pickup']?['address'] ?? 'Unknown';
    final drop = package['dropLocation'] ?? package['drop']?['address'] ?? 'Unknown';
    final date = _formatDateTime(package['scheduledAt'] ?? package['createdAt']);
    final price = package['totalFare'] ?? package['price'] ?? 0;
    final pkgName = package['route']?['name'] ?? package['packageName'] ?? 'Fixed Package';
    final status = (package['status'] ?? 'AVAILABLE').toString().toUpperCase();
    final paymentMethod = (package['paymentMethod'] ?? package['paymentType'] ?? 'CASH').toString().toUpperCase();

    final user = package['user'];
    final userName = user != null ? (user['name'] ?? 'User') : 'N/A';
    final userPhone = user != null ? (user['phone'] ?? 'N/A') : 'N/A';

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Package Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.white)),
        backgroundColor: AppColors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Name
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey800),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(pkgName, style: const TextStyle(color: AppColors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(status, style: TextStyle(color: status == 'COMPLETED' ? AppColors.success : (status == 'CANCELLED' ? AppColors.error : AppColors.yellow), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Locations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey800),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Locations', style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, color: AppColors.success, size: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pickup', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                            Text(pickup, style: const TextStyle(color: AppColors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Container(width: 2, height: 24, color: AppColors.grey700),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Drop', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                            Text(drop, style: const TextStyle(color: AppColors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Time and Price
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey800),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Scheduled At', style: TextStyle(color: AppColors.grey500, fontSize: 14)),
                      Text(date, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 32, color: AppColors.grey800),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Method', style: TextStyle(color: AppColors.grey500, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: paymentMethod == 'CASH' ? AppColors.success.withValues(alpha: 0.1) : AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(paymentMethod, style: TextStyle(color: paymentMethod == 'CASH' ? AppColors.success : AppColors.yellow, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Fare', style: TextStyle(color: AppColors.grey500, fontSize: 14)),
                      Text('₹$price', style: const TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Customer Info (if available and package is accepted)
            if (status != 'AVAILABLE' && user != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey800),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer Details', style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.grey800,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: AppColors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('+91 $userPhone', style: const TextStyle(color: AppColors.grey400, fontSize: 14)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {}, // Add dialer launch if needed
                          icon: const Icon(Icons.phone, color: AppColors.success),
                          style: IconButton.styleFrom(backgroundColor: AppColors.success.withValues(alpha: 0.1)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
