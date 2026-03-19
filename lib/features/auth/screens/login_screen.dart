import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/galaxy_button.dart';
import '../auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../../core/utils/test_seed_utils.dart';

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

  void _showSeedMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'DEVELOPER TOOLS',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSeedTile(
              title: 'Seed 1: Create Accounts',
              subtitle: 'Admin, Customers, & Partners (111111)',
              icon: Icons.person_add_alt_1,
              color: Colors.blue,
              onTap: () async {
                Navigator.pop(context);
                _showSnackBar('Đang khởi tạo tài khoản...');
                try {
                  await TestSeedUtils.seedStep1_Accounts();
                  _showSnackBar('Seed 1 thành công!');
                } catch (e) {
                  _showSnackBar('Lỗi Seed 1: $e', isError: true);
                }
              },
            ),
            const Divider(color: Colors.white10),
            _buildSeedTile(
              title: 'Seed 2: Historical Data',
              subtitle: '3 months of logs (10-15 entries/mo)',
              icon: Icons.history,
              color: Colors.orange,
              onTap: () async {
                Navigator.pop(context);
                _showSnackBar('Đang tạo dữ liệu lịch sử...');
                try {
                  await TestSeedUtils.seedStep2_HistoricalData();
                  _showSnackBar('Seed 2 thành công!');
                } catch (e) {
                  _showSnackBar('Lỗi Seed 2: $e', isError: true);
                }
              },
            ),
            const Divider(color: Colors.white10),
            _buildSeedTile(
              title: 'Seed 3: FULL WIPE',
              subtitle: 'Delete ALL data & reset everything',
              icon: Icons.delete_forever,
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                _showSnackBar('Đang xóa toàn bộ dữ liệu...');
                try {
                  final deleted = await TestSeedUtils.seedStep3_WipeAll();
                  _showSnackBar('Seed 3 thành công! Đã xóa $deleted bản ghi.');
                } catch (e) {
                  _showSnackBar('Lỗi Seed 3: $e', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
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
                      style: AppTextStyles.bodyMedium.copyWith(
                        letterSpacing: 2,
                      ),
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
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
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
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
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
                  ],
                ),
              ),
            ),
          ),

          // Discreet Developer Button
          Positioned(
            left: 12,
            bottom: 12,
            child: GestureDetector(
              onTap: _showSeedMenu,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Icon(
                  Icons.terminal_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
