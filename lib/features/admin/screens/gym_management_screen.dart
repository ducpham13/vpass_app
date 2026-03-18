import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/gym_model.dart';
import '../../cards/gym_provider.dart';
import 'gym_form_screen.dart';

class GymManagementScreen extends ConsumerStatefulWidget {
  final String? initialStatus;
  const GymManagementScreen({super.key, this.initialStatus});

  @override
  ConsumerState<GymManagementScreen> createState() => _GymManagementScreenState();
}

class _GymManagementScreenState extends ConsumerState<GymManagementScreen> {
  void _navigateToForm([GymModel? gym]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GymFormScreen(gym: gym)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gymsAsync = ref.watch(allGymsProvider);
    final initialIndex = _getInitialIndex();

    return DefaultTabController(
      length: 4,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gym Partner Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.accentBlue,
              onPressed: () => _navigateToForm(),
            )
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.accentBlue,
            tabs: [
              Tab(text: 'ALL'),
              Tab(text: 'ACTIVE'),
              Tab(text: 'INACTIVE'),
              Tab(text: 'PENDING'),
            ],
          ),
        ),
        body: gymsAsync.when(
          data: (gyms) {
            return TabBarView(
              children: [
                _buildGymList(gyms),
                _buildGymList(gyms.where((g) => g.status == 'active').toList()),
                _buildGymList(gyms.where((g) => g.status == 'inactive').toList()),
                _buildGymList(gyms.where((g) => g.status == 'pending').toList()),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('L?i: $err')),
        ),
      ),
    );
  }

  int _getInitialIndex() {
    if (widget.initialStatus == 'active') return 1;
    if (widget.initialStatus == 'inactive') return 2;
    if (widget.initialStatus == 'pending') return 3;
    return 0;
  }

  Widget _buildGymList(List<GymModel> gyms) {
    if (gyms.isEmpty) {
      return const Center(child: Text("No gym partners found in this category"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: gyms.length,
      itemBuilder: (context, index) {
        final gym = gyms[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    gym.name,
                    style: AppTextStyles.displaySmall.copyWith(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(gym.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('${gym.address}, ${gym.city}', style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(gym.partnerEmail, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue.withOpacity(0.8))),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToForm(gym),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.textMuted;
    if (status == 'active') color = AppColors.success;
    if (status == 'pending') color = AppColors.warning;
    if (status == 'inactive') color = AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
