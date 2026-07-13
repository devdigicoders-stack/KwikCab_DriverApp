import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../viewmodels/bookings_viewmodel.dart';

class HistoryDetailScreen extends StatelessWidget {
  final BookingHistory ride;

  const HistoryDetailScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    if (ride.status == 'Completed') {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (ride.status == 'Cancelled') {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = AppColors.yellow;
      statusIcon = Icons.directions_car_rounded;
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.grey900,
        title: const Text('Ride Details', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ride.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Text(ride.date, style: const TextStyle(color: AppColors.grey500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Trip ID and Fare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trip ID', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('#${ride.id.substring(ride.id.length > 8 ? ride.id.length - 8 : 0).toUpperCase()}', 
                          style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Fare', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(ride.fare, style: const TextStyle(color: AppColors.yellow, fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Passenger Details
              _buildSectionTitle('Passenger Details'),
              _buildDetailBox(
                child: Row(
                  children: [
                    Container(
                      width: 45, height: 45,
                      decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_rounded, color: AppColors.yellow, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ride.passengerName, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(ride.passengerPhone, style: const TextStyle(color: AppColors.grey500, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Route Information
              _buildSectionTitle('Route Information'),
              _buildDetailBox(
                child: Column(
                  children: [
                    Column(
                      children: [
                        _buildTimelineItem(
                          isFirst: true,
                          isLast: false,
                          color: AppColors.success,
                          title: 'Pickup',
                          subtitle: ride.pickup,
                        ),
                        _buildTimelineItem(
                          isFirst: false,
                          isLast: true,
                          color: AppColors.yellow,
                          title: 'Drop',
                          subtitle: ride.drop,
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: AppColors.grey800),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSmallInfo(Icons.straighten_rounded, 'Distance', ride.distance),
                        const SizedBox(width: 8),
                        _buildSmallInfo(Icons.directions_car_rounded, 'Category', ride.carCategoryName),
                        const SizedBox(width: 8),
                        _buildSmallInfo(Icons.merge_type_rounded, 'Type', ride.rideType),
                      ],
                    ),
                  ],
                ),
              ),

              // Ride Timings
              _buildSectionTitle('Trip Timings'),
              _buildDetailBox(
                child: Column(
                  children: [
                    _buildTimingRow('Arrived at Pickup', ride.arrivedAt),
                    const Divider(color: AppColors.grey800, height: 24),
                    _buildTimingRow('Ride Started', ride.startedAt),
                    const Divider(color: AppColors.grey800, height: 24),
                    _buildTimingRow('Ride Ended', ride.endedAt),
                  ],
                ),
              ),

              // Fare Breakdown
              _buildSectionTitle('Payment Summary'),
              _buildDetailBox(
                child: Column(
                  children: [
                    _buildPaymentRow('Base/Actual Fare', ride.fare),
                    const SizedBox(height: 10),
                    _buildPaymentRow('Waiting Charges (\${ride.waitingTimeMin} min)', ride.waitingCharges),
                    const Divider(color: AppColors.grey800, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(child: Text('Payment Method', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.grey800, borderRadius: BorderRadius.circular(6)),
                          child: Text(ride.paymentMode, style: const TextStyle(color: AppColors.yellow, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Cancel Reason (if any)
              if (ride.status == 'Cancelled' && ride.cancelReason.isNotEmpty) ...[
                _buildSectionTitle('Cancellation Reason'),
                _buildDetailBox(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(ride.cancelReason, style: const TextStyle(color: AppColors.error, fontSize: 14))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title, style: const TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildDetailBox({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey800),
      ),
      child: child,
    );
  }

  Widget _buildSmallInfo(IconData icon, String title, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.grey600, size: 18),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: AppColors.grey600, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value, 
            style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required bool isFirst,
    required bool isLast,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 4,
                  color: isFirst ? Colors.transparent : AppColors.grey700,
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingRow(String title, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(title, style: const TextStyle(color: AppColors.grey500, fontSize: 14))),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            time, 
            style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(child: Text(title, style: const TextStyle(color: AppColors.grey500, fontSize: 14))),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            amount, 
            style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
