import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/glass_container.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/galaxy_button.dart';
import '../auth_provider.dart';
import '../auth_utils.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEditing = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _handleUpdateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Họ tên không được để trống', isError: true);
      return;
    }
    try {
      await ref.read(authProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      setState(() => _isEditing = false);
      _showSnackBar('Cập nhật thông tin thành công');
    } catch (e) {
      _showSnackBar(AuthUtils.cleanErrorMessage(e), isError: true);
    }
  }

  Future<void> _handleChangePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu xác nhận không khớp', isError: true);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).reauthenticate(_currentPasswordController.text);
      await ref.read(authProvider.notifier).changePassword(_newPasswordController.text);
      
      setState(() => _isChangingPassword = false);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showSnackBar('Đổi mật khẩu thành công');
    } catch (e) {
      _showSnackBar(AuthUtils.cleanErrorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundPrimary,
              AppColors.backgroundPrimary.withOpacity(0.8),
              AppColors.backgroundPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    // Custom AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.05),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'TÀI KHOẢN',
                            style: AppTextStyles.displayMedium.copyWith(letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Profile Header
                    _buildProfileHeader(user),

                    const SizedBox(height: 32),

                    // Account Info Section
                    _buildSectionHeader('THÔNG TIN TÀI KHOẢN'),
                    const SizedBox(height: 12),
                    _buildInfoCard(user),

                    const SizedBox(height: 24),

                    // Settings Section
                    _buildSectionHeader('CÀI ĐẶT'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(),

                    const SizedBox(height: 32),

                    // Logout Button
                    _buildLogoutButton(),

                    const SizedBox(height: 48),
                  ],
                ),
              ),

              if (_isEditing) _buildEditOverlay(authState.isLoading),
              if (_isChangingPassword) _buildPasswordOverlay(authState.isLoading),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplay(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return 'QUẢN TRỊ VIÊN';
      case 'gym_partner': return 'ĐỐI TÁC';
      case 'customer': return 'KHÁCH HÀNG';
      default: return role.toUpperCase();
    }
  }

  Widget _buildProfileHeader(user) {
    return Column(
      children: [
        UserAvatar(
          name: user.name,
          radius: 50,
          fontSize: 36,
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: AppTextStyles.displaySmall.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
          ),
          child: Text(
            _getRoleDisplay(user.role),
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.accentBlue,
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 1.5,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildInfoCard(user) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 8),
      borderRadius: 16,
      child: Column(
        children: [
          _buildInfoItem('Họ tên', user.name),
          const Divider(color: Colors.white10, indent: 16, endIndent: 16),
          _buildInfoItem('Email', user.email, isEmail: true),
          const Divider(color: Colors.white10, indent: 16, endIndent: 16),
          _buildInfoItem('Số điện thoại', user.phone),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isEmail ? AppColors.accentBlue : Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 8),
      borderRadius: 16,
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.edit_note_outlined,
            iconColor: const Color(0xFFF97316),
            title: 'Chỉnh sửa thông tin',
            subtitle: 'Tên, số điện thoại',
            onTap: () => setState(() => _isEditing = true),
          ),
          const Divider(color: Colors.white10, indent: 16, endIndent: 16),
          _buildSettingsItem(
            icon: Icons.lock_outline,
            iconColor: const Color(0xFFEAB308),
            title: 'Đổi mật khẩu',
            subtitle: 'Cập nhật mật khẩu mới',
            onTap: () => setState(() => _isChangingPassword = true),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => ref.read(authProvider.notifier).logout(),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white.withOpacity(0.02),
        ),
        child: Text(
          'Đăng xuất',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEditOverlay(bool isLoading) {
    return _buildOverlay(
      title: 'CHỈNH SỬA THÔNG TIN',
      content: [
        _buildTextField('Họ tên', _nameController),
        const SizedBox(height: 16),
        _buildTextField('Số điện thoại', _phoneController, keyboardType: TextInputType.phone),
      ],
      onSave: _handleUpdateProfile,
      onCancel: () => setState(() => _isEditing = false),
      isLoading: isLoading,
    );
  }

  Widget _buildPasswordOverlay(bool isLoading) {
    return _buildOverlay(
      title: 'ĐỔI MẬT KHẨU',
      content: [
        _buildTextField('Mật khẩu hiện tại', _currentPasswordController, isPassword: true),
        const SizedBox(height: 16),
        _buildTextField('Mật khẩu mới', _newPasswordController, isPassword: true),
        const SizedBox(height: 16),
        _buildTextField('Xác nhận mật khẩu mới', _confirmPasswordController, isPassword: true),
      ],
      onSave: _handleChangePassword,
      onCancel: () {
        setState(() => _isChangingPassword = false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      },
      isLoading: isLoading,
    );
  }

  Widget _buildOverlay({
    required String title,
    required List<Widget> content,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required bool isLoading,
  }) {
    return Container(
      color: Colors.black87,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.displaySmall),
              const SizedBox(height: 24),
              ...content,
              const SizedBox(height: 32),
              GalaxyButton(text: 'LƯU THAY ĐỔI', isLoading: isLoading, onPressed: onSave),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isLoading ? null : onCancel,
                child: Text('Hủy bỏ', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
