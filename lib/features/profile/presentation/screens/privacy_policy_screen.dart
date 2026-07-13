import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Privacy Policy', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy for KwikCab Driver',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.yellow,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last Updated: June 2026',
              style: TextStyle(fontSize: 14, color: AppColors.grey500),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Introduction',
              content:
                  'Welcome to the KwikCab Driver App. Your privacy is critically important to us. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our driver application.',
            ),
            _buildSection(
              title: '2. Information We Collect',
              content:
                  'We collect personal and vehicle-related data necessary to provide and improve our services:\n\n'
                  '• Personal Information: Name, phone number, email address, profile picture, and banking details for payment processing.\n'
                  '• Location Data: Real-time and background location data are strictly required for ride matching, route optimization, and safety monitoring.\n'
                  '• Documents: Driving license, vehicle RC, insurance, permit, PUC, Aadhar, and PAN card for verification purposes.\n'
                  '• Device Information: Device model, operating system, IP address, and app usage logs.',
            ),
            _buildSection(
              title: '3. How We Use Your Information',
              content:
                  'We use the collected data for the following purposes:\n\n'
                  '• To match you with riders and calculate trip fares.\n'
                  '• To process your weekly payouts and earnings.\n'
                  '• To maintain a secure and safe platform by verifying driver identities and tracking rides.\n'
                  '• To provide customer support and resolve any disputes.',
            ),
            _buildSection(
              title: '4. Data Sharing and Disclosure',
              content:
                  'We do not sell your personal data. We may share necessary information in the following ways:\n\n'
                  '• With Riders: We share your name, profile picture, vehicle details, and real-time location with riders for smooth pickups.\n'
                  '• With Third-Party Service Providers: Such as payment gateways to process your withdrawals, or cloud hosting services.\n'
                  '• For Legal Requirements: We may disclose your information to law enforcement agencies if required by law or to protect our legal rights.',
            ),
            _buildSection(
              title: '5. Location Tracking (Background & Foreground)',
              content:
                  'The KwikCab Driver app relies heavily on location services. We track your location even when the app is running in the background to ensure you are matched with riders accurately and to track ongoing trips for safety and billing purposes. You can disable background tracking, but doing so will severely limit your ability to receive new ride requests.',
            ),
            _buildSection(
              title: '6. Data Security',
              content:
                  'We implement standard security measures to protect your personal information and documents from unauthorized access or disclosure. However, no internet transmission is 100% secure, and we cannot guarantee absolute security.',
            ),
            _buildSection(
              title: '7. Your Rights',
              content:
                  'You have the right to access, update, or delete your personal information. You can do this by visiting your profile section or contacting our support team via the "Help & Support" menu.',
            ),
            _buildSection(
              title: '8. Contact Us',
              content:
                  'If you have any questions or concerns about this Privacy Policy, please contact us using the "Help & Support" feature within the app.',
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                '© 2026 KwikCabs. All rights reserved.',
                style: TextStyle(fontSize: 12, color: AppColors.grey600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grey400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
