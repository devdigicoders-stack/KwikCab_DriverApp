import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../routes/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.black,
              const Color(0xFF121212),
              const Color(0xFF1E1E1E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grey900.withOpacity(0.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: Lottie.asset('assets/aa46182e-1186-11ee-88e4-bb5e014fb375.json', width: 220, height: 220, fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DRIVER',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.yellow, letterSpacing: 3),
                ),
                const SizedBox(height: 60),
                const Text(
                  'Join Our Team',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Drive with us and earn on your own schedule. Your journey starts here.',
                  style: TextStyle(fontSize: 16, color: AppColors.grey500, fontWeight: FontWeight.w500, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    child: const Text(
                      'Get Started',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
