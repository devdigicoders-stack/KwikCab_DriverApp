import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../viewmodels/bulk_bookings_viewmodel.dart';

class BulkBookingDetailsScreen extends StatelessWidget {
  final BulkAssignment assignment;

  const BulkBookingDetailsScreen({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final dateObj = DateTime.tryParse(assignment.pickupDateTime)?.toLocal();
    final dateStr = dateObj != null ? DateFormat('dd MMM yyyy, hh:mm a').format(dateObj) : assignment.pickupDateTime;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text('Booking History Details', style: TextStyle(color: AppColors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Price', style: TextStyle(color: AppColors.grey400, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('₹${assignment.offeredPrice}', style: const TextStyle(color: AppColors.yellow, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: assignment.status == 'Completed' ? Colors.green.withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      assignment.status,
                      style: TextStyle(
                        color: assignment.status == 'Completed' ? Colors.green : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Outstation Tax Details
            if (assignment.isOutstation && assignment.mcdStateTaxApplied > 0)
              _buildSection(
                title: 'Outstation Tax Details',
                icon: Icons.receipt_long_outlined,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('MCD/STATE TAX (Included)', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('₹${assignment.mcdStateTaxApplied}', style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'This tax is already included in the Total Price. Please collect this amount directly from the customer.',
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

            // Route Details
            _buildSection(
              title: 'Route Details',
              icon: Icons.map_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded, color: AppColors.yellow, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(assignment.pickupAddress, style: const TextStyle(color: AppColors.white, fontSize: 15))),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 9, top: 8, bottom: 8),
                    height: 24,
                    width: 2,
                    color: AppColors.grey800,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(assignment.dropAddress, style: const TextStyle(color: AppColors.white, fontSize: 15))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppColors.grey500, size: 20),
                      const SizedBox(width: 12),
                      Text('Pickup: $dateStr', style: const TextStyle(color: AppColors.grey400, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),

            // Customer Details
            if (assignment.customerName != null || assignment.createdBy != null)
              _buildSection(
                title: 'Customer / Agent Details',
                icon: Icons.person_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (assignment.customerName != null && assignment.customerName!.isNotEmpty)
                      _buildRow('Customer Name:', assignment.customerName!),
                    if (assignment.customerPhone != null && assignment.customerPhone!.isNotEmpty)
                      _buildRow('Customer Phone:', assignment.customerPhone!),
                    if (assignment.createdBy != null) ...[
                      const SizedBox(height: 8),
                      _buildRow('Booked By:', assignment.createdBy!['name'] ?? 'Unknown Agent'),
                      _buildRow('Agent Phone:', assignment.createdBy!['phone'] ?? 'N/A'),
                    ],
                    if (assignment.notes != null && assignment.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Notes:', style: TextStyle(color: AppColors.grey500, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(assignment.notes!, style: const TextStyle(color: AppColors.grey400, fontSize: 14)),
                    ],
                  ],
                ),
              ),

            // Driver Activity Details
            if (assignment.assignedDrivers != null && assignment.assignedDrivers!.isNotEmpty)
              _buildSection(
                title: 'Driver Activity (${assignment.assignedDrivers!.length} Cars)',
                icon: Icons.directions_car_outlined,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assignment.assignedDrivers!.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.grey800, height: 24),
                  itemBuilder: (context, index) {
                    final d = assignment.assignedDrivers![index];
                    final carInfo = d['car'] != null ? '${d['car']['carModel'] ?? ''} (${d['car']['carNumber'] ?? ''})' : 'Unknown Car';
                    final status = d['status'] ?? 'Pending';
                    final startedAt = d['startedAt'] != null ? DateFormat('hh:mm a, dd MMM').format(DateTime.parse(d['startedAt']).toLocal()) : 'Not started';
                    final endedAt = d['endedAt'] != null ? DateFormat('hh:mm a, dd MMM').format(DateTime.parse(d['endedAt']).toLocal()) : 'Not ended';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(carInfo, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold))),
                            Text(status, style: TextStyle(color: status == 'Completed' ? Colors.green : AppColors.yellow, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.play_circle_outline, color: AppColors.grey500, size: 16),
                            const SizedBox(width: 8),
                            Text('Started: $startedAt', style: const TextStyle(color: AppColors.grey400, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.stop_circle_outlined, color: AppColors.grey500, size: 16),
                            const SizedBox(width: 8),
                            Text('Ended: $endedAt', style: const TextStyle(color: AppColors.grey400, fontSize: 13)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.yellow, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.grey500, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
