import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/auth_response.dart';
import '../../../../routes/app_routes.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _LoginBody(),
    );
  }
}

class _LoginBody extends StatefulWidget {
  const _LoginBody();
  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.grey900.withOpacity(0.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.yellow.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset('assets/logo_icon.png', width: 130, height: 130, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('DRIVER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.yellow, letterSpacing: 5)),
                  ),
                  const SizedBox(height: 30),
                  const Text('Welcome back!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: -0.5)),
                  
                  if (vm.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(vm.error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  // Email field
                  _inputField(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    hint: 'driver@example.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: vm.setEmail,
                    prefixIcon: Icons.email_rounded,
                  ),
                  const SizedBox(height: 24),

                  // Password field
                  _inputField(
                    controller: _passCtrl,
                    label: 'Password',
                    hint: '••••••••',
                    obscure: vm.obscurePassword,
                    onChanged: vm.setPassword,
                    prefixIcon: Icons.lock_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(vm.obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.grey600, size: 22),
                      onPressed: vm.togglePassword,
                    ),
                  ),



                  const SizedBox(height: 40),
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
                      onPressed: vm.isLoading ? null : () async {
                        final response = await vm.login();
                        if (!context.mounted) return;

                        switch (response.status) {
                          case LoginStatus.success:
                            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
                            break;
                          case LoginStatus.pending:
                            Navigator.pushNamed(context, AppRoutes.pending, arguments: {'message': response.message});
                            break;
                          case LoginStatus.rejected:
                            Navigator.pushNamed(context, AppRoutes.rejected, arguments: {'message': response.message, 'driverData': response.data});
                            break;
                          case LoginStatus.blocked:
                            Navigator.pushNamed(context, AppRoutes.blocked, arguments: {'message': response.message});
                            break;
                          default:
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response.message), backgroundColor: AppColors.error),
                            );
                            break;
                        }
                      },
                      child: vm.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.black))
                          : const Text('Login to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account?',
                        style: TextStyle(color: AppColors.grey500, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.registration);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.yellow,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Register Now',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),


                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontSize: 16, color: AppColors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 15, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: AppColors.yellow, fontSize: 16, fontWeight: FontWeight.w700),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.grey700.withOpacity(0.5), fontSize: 15, fontWeight: FontWeight.w400),
        filled: true,
        fillColor: AppColors.grey900.withOpacity(0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 20, right: 12),
          child: Icon(prefixIcon, color: AppColors.grey500, size: 24),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 56),
        suffixIcon: suffixIcon != null ? Padding(
          padding: const EdgeInsets.only(right: 8),
          child: suffixIcon,
        ) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.grey800, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.yellow, width: 2),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
