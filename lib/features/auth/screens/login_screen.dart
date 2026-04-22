import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../medical_record/screens/medical_record_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpStage = false;

  void _handleAction() async {
    final auth = ref.read(authProvider.notifier);
    if (!_isOtpStage) {
      await auth.sendOtp(_emailController.text.trim());
      if (ref.read(authProvider).isOtpSent) {
        setState(() => _isOtpStage = true);
      }
    } else {
      await auth.verifyOtp(_emailController.text.trim(), _otpController.text.trim());
      if (ref.read(authProvider).isAuthenticated) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MedicalProfileScreen(isOnboarding: true)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Icon
              const Icon(Icons.favorite_rounded, size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                tr('app_name'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 48),
              
              Text(
                _isOtpStage ? tr('login.otp_hint') : tr('login.title'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              if (!_isOtpStage)
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: tr('login.email_hint'),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                )
              else
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: tr('login.otp_hint'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: state.isLoading ? null : _handleAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isOtpStage ? tr('login.verify') : tr('login.send_otp'),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(state.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
