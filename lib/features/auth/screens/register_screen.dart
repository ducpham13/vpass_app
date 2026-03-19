import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/galaxy_button.dart';
import '../auth_provider.dart';
import '../auth_utils.dart';
import '../../../core/utils/validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  String _selectedRole = 'customer';

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    final nameError = Validators.validateName(name);
    if (nameError != null) return nameError;

    final emailError = Validators.validateEmail(email);
    if (emailError != null) return emailError;

    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) return phoneError;

    final passError = Validators.validatePassword(pass);
    if (passError != null) return passError;

    final confirmError = Validators.validateConfirmPassword(confirm, pass);
    if (confirmError != null) return confirmError;

    return null;
  }

  Future<void> _handleRegister() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _selectedRole,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthUtils.cleanErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('CREATE ACCOUNT')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'JOIN VPASS',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.accentBlue,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Full Name',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.textMuted,
                      ),
                    ),
                    style: AppTextStyles.bodyLarge,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      hintText: 'Phone number (e.g. 0901234567)',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: AppColors.textMuted,
                      ),
                    ),
                    style: AppTextStyles.bodyLarge,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      hintText: 'Password (min. 6 characters)',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _confirmController,
                    obscureText: !_showConfirm,
                    decoration: InputDecoration(
                      hintText: 'Confirm password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirm ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _showConfirm = !_showConfirm),
                      ),
                    ),
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('I am a:', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('CUSTOMER')),
                          selected: _selectedRole == 'customer',
                          onSelected: (val) => setState(() => _selectedRole = 'customer'),
                          backgroundColor: AppColors.backgroundCard,
                          selectedColor: AppColors.accentBlue.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _selectedRole == 'customer' ? AppColors.accentBlue : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _selectedRole == 'customer' ? AppColors.accentBlue : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('GYM PARTNER')),
                          selected: _selectedRole == 'gym_partner',
                          onSelected: (val) => setState(() => _selectedRole = 'gym_partner'),
                          backgroundColor: AppColors.backgroundCard,
                          selectedColor: AppColors.accentCyan.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _selectedRole == 'gym_partner' ? AppColors.accentCyan : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _selectedRole == 'gym_partner' ? AppColors.accentCyan : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GalaxyButton(
                    text: 'SIGN UP',
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading ? null : _handleRegister,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
