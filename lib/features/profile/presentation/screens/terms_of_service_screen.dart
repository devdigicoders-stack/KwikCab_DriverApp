import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Terms of Service', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service for KwikCab Driver',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.yellow,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Effective Date: June 2026',
              style: TextStyle(fontSize: 14, color: AppColors.grey500),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Agreement to Terms',
              content:
                  'By accessing or using the KwikCab Driver App, you agree to be bound by these Terms of Service. If you do not agree, you must immediately stop using our platform.',
            ),
            _buildSection(
              title: '2. Driver Obligations and Requirements',
              content:
                  'As a KwikCab Driver, you must comply with the following:\n\n'
                  '• You must hold a valid driving license, commercial vehicle permit, and up-to-date insurance.\n'
                  '• You agree to provide safe, reliable, and professional service to riders at all times.\n'
                  '• Your vehicle must be well-maintained and pass all required local emission tests (PUC) and road safety standards.\n'
                  '• You must not share your driver account credentials with any third party. Your account is non-transferable.',
            ),
            _buildSection(
              title: '3. Payments, Earnings, and Fees',
              content:
                  '• KwikCab will calculate your trip fare based on distance, time, and active pricing rules.\n'
                  '• KwikCab deducts a platform commission fee from your total fare for each trip.\n'
                  '• Your net earnings will be reflected in your Wallet. You may request a payout to your registered bank account subject to minimum withdrawal limits.\n'
                  '• Cash payments collected directly from riders must be accurately reported in the app.',
            ),
            _buildSection(
              title: '4. Zero Tolerance Policy',
              content:
                  'KwikCab maintains a strict Zero Tolerance Policy. Your account will be permanently deactivated for any of the following:\n\n'
                  '• Driving under the influence of drugs or alcohol.\n'
                  '• Misbehaving, harassing, or physically abusing a rider.\n'
                  '• Fraudulent activities such as artificially inflating trip distances or using fake GPS applications.\n'
                  '• Discrimination against riders based on race, religion, gender, or destination.',
            ),
            _buildSection(
              title: '5. Account Suspension & Termination',
              content:
                  'KwikCab reserves the right to suspend or terminate your driver account at any time if you violate these Terms, receive consistently low ratings, or if your required documents (License, RC, Insurance) expire.',
            ),
            _buildSection(
              title: '6. Limitation of Liability',
              content:
                  'KwikCab acts solely as a technology platform that connects drivers with riders. We are not a transport operator. You operate as an independent contractor, and KwikCab is not liable for any damages, accidents, or losses that occur while you are online or driving.',
            ),
            _buildSection(
              title: '7. Changes to Terms',
              content:
                  'We may update these Terms from time to time. Your continued use of the Driver App after modifications signifies your acceptance of the new Terms.',
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
