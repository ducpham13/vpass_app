import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/galaxy_button.dart';
import '../auth_provider.dart';
import '../auth_utils.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$');
    if (!emailRegex.hasMatch(email)) return 'Invalid email address';
    return null;
  }

  Future<void> _handleReset() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .sendPasswordReset(_emailController.text.trim());
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.backgroundSurface,
            title: const Text('Reset Link Sent'),
            content: const Text(
              'If an account exists for this email, you will receive a password reset link shortly.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthUtils.cleanErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RESET PASSWORD')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Enter your email to receive a password reset link.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
                style: AppTextStyles.bodyLarge,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.xl),
              GalaxyButton(
                text: 'SEND RESET LINK',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
