import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/galaxy_button.dart';
import '../auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.accentBlue,
      ),
    );
  }

  String? _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$');
    if (!emailRegex.hasMatch(email)) return 'Invalid email address';
    if (password.isEmpty) return 'Please enter your password';

    return null;
  }

  Future<void> _handleLogin() async {
    final validationError = _validate();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    final error = await ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (error != null) _showSnackBar(error, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'VPASS',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.accentBlue,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'YOUR GATEWAY TO FITNESS',
                  style: AppTextStyles.bodyMedium.copyWith(letterSpacing: 2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.textMuted,
                    ),
                  ),
                  style: AppTextStyles.bodyLarge,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
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
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.sm),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                GalaxyButton(
                  text: 'LOGIN',
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _handleLogin,
                ),
                const SizedBox(height: AppSpacing.lg),

                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: AppTextStyles.bodySmall,
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // --- DEV ONLY SEED BUTTON ---
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () async {
                    final repo = ref.read(authRepositoryProvider);
                    int successCount = 0;
                    
                    Future<void> createUser(String email, String role, String name) async {
                      try {
                        await repo.signUpWithEmailAndPassword(
                          email: email,
                          password: '111111',
                          name: name,
                          phone: '0901111111',
                          role: role,
                        );
                        successCount++;
                      } catch (e) {
                         print('Seed error for $email: $e');
                      }
                    }

                    _showSnackBar('Đang tạo tài khoản test...', isError: false);
                    await createUser('admin@gmail.com', 'super_admin', 'Admin Test');
                    await createUser('cus@gmail.com', 'customer', 'Customer Test');
                    await createUser('gym@gmail.com', 'gym_partner', 'Gym Partner Test');
                    
                    // Logout because Firebase auto logs in the last created user
                    await repo.signOut();
                    
                    _showSnackBar('Hoàn tất! Cần đăng nhập thủ công lại. Đã tạo mới: $successCount/3 (các tài khoản đã tồn tại sẽ bị bỏ qua).', isError: false);
                  },
                  child: const Text(
                    '🛠 BẤM VÀO ĐÂY ĐỂ TẠO 3 TÀI KHOẢN TEST (ADMIN, CUS, GYM)',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
