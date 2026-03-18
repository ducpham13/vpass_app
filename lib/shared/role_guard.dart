import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/partner/screens/partner_dashboard_screen.dart';
import '../core/constants/app_colors.dart';

class RoleGuard extends ConsumerWidget {
  final Widget customerChild;
  final Widget superAdminChild;

  const RoleGuard({
    super.key,
    required this.customerChild,
    required this.superAdminChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );
    }

    if (authState.user == null) {
      return const LoginScreen();
    }

    final user = authState.user!;
    if (user.isCustomer) return customerChild;
    if (user.isGymPartner) return const PartnerDashboardScreen();
    if (user.isSuperAdmin) return superAdminChild;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            const Text("Invalid Role Configured"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
