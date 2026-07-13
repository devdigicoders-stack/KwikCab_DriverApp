import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/constants/app_colors.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _PhoneBody(),
    );
  }
}

class _PhoneBody extends StatefulWidget {
  const _PhoneBody();
  @override
  State<_PhoneBody> createState() => _PhoneBodyState();
}

class _PhoneBodyState extends State<_PhoneBody> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(child: Image.asset('assets/logo_icon.png', width: 80, height: 80, fit: BoxFit.contain)),
              const SizedBox(height: 8),
              const Center(child: Text('DRIVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.yellow, letterSpacing: 5))),
              const SizedBox(height: 40),
              const Text('Enter your\nmobile number', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white, height: 1.2)),
              const SizedBox(height: 8),
              const Text('We\'ll send you a verification code', style: TextStyle(fontSize: 14, color: AppColors.grey500)),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey800)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.grey800))),
                      child: const Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 18, color: AppColors.white, fontWeight: FontWeight.w600, letterSpacing: 2),
                        decoration: const InputDecoration(
                          hintText: '00000 00000',
                          hintStyle: TextStyle(color: AppColors.grey700, fontSize: 16, letterSpacing: 2),
                          border: InputBorder.none, counterText: '', filled: false,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: vm.setPhone,
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 8),
                Text(vm.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: vm.isLoading ? null : () async {
                    await vm.sendOtp();
                    if (vm.otpSent && context.mounted) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(value: vm, child: const OtpScreen()),
                      ));
                    }
                  },
                  child: vm.isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black))
                      : const Text('Get OTP'),
                ),
              ),
              const Spacer(),
              const Center(
                child: Text('By continuing, you agree to our\nTerms of Service & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.grey600, height: 1.5)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
