import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../routes/app_routes.dart';

class PendingScreen extends StatelessWidget {
  final String? message;
  const PendingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return _StatusLayout(
      icon: Icons.hourglass_empty_rounded,
      iconColor: AppColors.yellow,
      title: 'Pending Approval',
      message: message ?? 'Your account is pending admin approval. Please wait while we review your details.',
    );
  }
}

class RejectedScreen extends StatelessWidget {
  final String? message;
  final Map<String, dynamic>? driverData;
  const RejectedScreen({super.key, this.message, this.driverData});

  @override
  Widget build(BuildContext context) {
    return _StatusLayout(
      icon: Icons.cancel_rounded,
      iconColor: Colors.redAccent,
      title: 'Registration Rejected',
      message: message ?? 'Your registration was rejected by the admin. Please update your details and resubmit.',
      showRetryButton: true,
      retryText: 'Resubmit Details',
      driverData: driverData,
    );
  }
}

class BlockedScreen extends StatelessWidget {
  final String? message;
  const BlockedScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return _StatusLayout(
      icon: Icons.block_rounded,
      iconColor: Colors.red,
      title: 'Account Blocked',
      message: message ?? 'Your account has been deactivated by the Admin. Please contact support.',
    );
  }
}

class _StatusLayout extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final bool showRetryButton;
  final String? retryText;
  final Map<String, dynamic>? driverData;

  const _StatusLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.showRetryButton = false,
    this.retryText,
    this.driverData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.black, const Color(0xFF1A1A1A)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withOpacity(0.1),
                  ),
                  child: Icon(icon, size: 80, color: iconColor),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.grey500, height: 1.5),
                ),
                const SizedBox(height: 48),
                if (showRetryButton)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      // Navigate to resubmit screen (Registration) instead of login
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.registration, (route) => false, arguments: {'driverData': driverData});
                    },
                    child: Text(retryText ?? 'Try Again', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                else
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.grey500),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                    },
                    child: const Text('Back to Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
