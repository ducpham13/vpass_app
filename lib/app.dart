import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'shared/role_guard.dart';
import 'features/cards/screens/cards_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'shared/mesh_gradient_background.dart';
import 'features/auth/auth_provider.dart';

class VpassApp extends ConsumerWidget {
  const VpassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      key: ValueKey(authState.user?.uid ?? 'logged-out'),
        title: 'Vpass',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) {
          return MeshGradientBackground(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const RoleGuard(
          customerChild: CardsScreen(),
          superAdminChild: AdminDashboardScreen(),
        ),
      );
  }
}
