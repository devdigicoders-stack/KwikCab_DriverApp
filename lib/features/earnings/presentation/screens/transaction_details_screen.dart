import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'earnings_viewmodel.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final EarningEntry entry;

  const TransactionDetailsScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.type == 'Credit';

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Transaction Details', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: (isCredit ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  entry.icon,
                  color: isCredit ? AppColors.success : AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                (isCredit ? '+' : '-') + entry.amount,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: isCredit ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.title,
                style: const TextStyle(fontSize: 18, color: AppColors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),
              
              // Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.grey900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey800),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Transaction ID', entry.id),
                    const Divider(color: AppColors.grey800, height: 30),
                    _buildDetailRow('Date & Time', entry.date),
                    const Divider(color: AppColors.grey800, height: 30),
                    _buildDetailRow('Type', entry.type),
                    const Divider(color: AppColors.grey800, height: 30),
                    _buildDetailRow('Status', entry.status, valueColor: entry.status == 'Completed' ? AppColors.success : AppColors.yellow),
                    if (entry.description.isNotEmpty) ...[
                      const Divider(color: AppColors.grey800, height: 30),
                      _buildDetailRow('Description', entry.description),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color valueColor = AppColors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.grey500),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor),
          ),
        ),
      ],
    );
  }
}
