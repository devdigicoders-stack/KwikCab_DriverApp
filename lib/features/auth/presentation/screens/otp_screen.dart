import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../routes/app_routes.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () { vm.goBack(); Navigator.pop(context); },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Verify OTP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white)),
              const SizedBox(height: 8),
              RichText(text: TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.grey500),
                children: [
                  const TextSpan(text: 'Sent to +91 '),
                  TextSpan(text: vm.phone, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                ],
              )),
              const SizedBox(height: 48),
              Center(
                child: Pinput(
                  length: 4,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  defaultPinTheme: PinTheme(
                    width: 65, height: 65,
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.white),
                    decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey800, width: 1.5)),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 65, height: 65,
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.white),
                    decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.yellow, width: 2)),
                  ),
                  submittedPinTheme: PinTheme(
                    width: 65, height: 65,
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.black),
                    decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: vm.setOtp,
                  onCompleted: (_) async {
                    final success = await vm.verifyOtp();
                    if (success && context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
                    }
                  },
                ),
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 16),
                Center(child: Text(vm.error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
              ],
              const SizedBox(height: 32),
              Center(
                child: vm.canResend
                    ? GestureDetector(
                        onTap: vm.resendOtp,
                        child: const Text('Resend OTP', style: TextStyle(fontSize: 15, color: AppColors.yellow, fontWeight: FontWeight.w600)),
                      )
                    : Text('Resend in ${vm.resendSeconds}s', style: const TextStyle(fontSize: 14, color: AppColors.grey600)),
              ),
              if (vm.isLoading) ...[
                const SizedBox(height: 32),
                const Center(child: CircularProgressIndicator(color: AppColors.yellow, strokeWidth: 2)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
