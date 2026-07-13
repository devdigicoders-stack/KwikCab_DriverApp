import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('driver_isLoggedIn') ?? false;
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, isLoggedIn ? AppRoutes.home : AppRoutes.welcome);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo_icon.png', width: 180, height: 180, fit: BoxFit.contain),
              const SizedBox(height: 16),
              const Text('DRIVER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.yellow, letterSpacing: 6)),
            ],
          ),
        ),
      ),
    );
  }
}
