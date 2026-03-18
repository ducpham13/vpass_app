import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'shared/role_guard.dart';
import 'features/cards/screens/cards_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'shared/mesh_gradient_background.dart';

class VpassApp extends StatelessWidget {
  const VpassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
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
      ),
    );
  }
}
