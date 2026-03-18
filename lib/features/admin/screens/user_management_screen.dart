import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/glass_container.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../admin_user_provider.dart';
import '../../../models/user_model.dart';
import '../../../models/card_model.dart';
import '../../../shared/galaxy_button.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(filteredUsersProvider);
    final searchController = TextEditingController(text: ref.read(userSearchQueryProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('USER MANAGEMENT'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (v) => ref.read(userSearchQueryProvider.notifier).set(v),
              decoration: InputDecoration(
                hintText: 'Search by Name, Email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    ref.read(userSearchQueryProvider.notifier).set('');
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserCard(user: user);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('L?i: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
        ),
        leading: UserAvatar(
          name: user.name,
          radius: 20,
        ),
        title: Text(user.name, style: AppTextStyles.bodyLarge),
        subtitle: Text(user.email, style: AppTextStyles.bodySmall),
        trailing: Icon(
          user.isLocked ? Icons.lock : Icons.chevron_right,
          color: user.isLocked ? AppColors.danger : AppColors.textMuted,
        ),
      ),
    );
  }
}

class UserDetailScreen extends ConsumerWidget {
  final UserModel user;
  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(userCardsProvider(user.uid));
    final transactionsAsync = ref.watch(userTransactionsProvider(user.uid));
    final checkinsAsync = ref.watch(userCheckinsProvider(user.uid));
    final fmt = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('USER DETAILS'),
        actions: [
          IconButton(
            icon: Icon(user.isLocked ? Icons.lock_open : Icons.lock, 
              color: user.isLocked ? AppColors.success : AppColors.danger),
            onPressed: () => _handleToggleLock(context, ref),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _buildUserHeader(user, fmt),
            const TabBar(
              tabs: [
                Tab(text: 'Thông tin chi tiết'),
                Tab(text: 'Giao dịch'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDetailedInfo(context, ref, cardsAsync, checkinsAsync, fmt),
                  _buildTransactionsList(transactionsAsync, fmt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggleLock(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isLocked ? 'Mở khoá tài khoản?' : 'Khoá tài khoản?'),
        content: Text(user.isLocked 
          ? 'Bạn có chắc chắn muốn mở khoá cho ${user.name}?' 
          : 'Người dùng sẽ không thể đăng nhập hoặc sử dụng ứng dụng.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('HỦY')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(user.isLocked ? 'MỞ KHOÁ' : 'KHOÁ')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(adminUserActionsProvider).toggleUserLock(user.uid, !user.isLocked);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _buildUserHeader(UserModel user, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          UserAvatar(
            name: user.name,
            radius: 40,
            fontSize: 32,
          ),
          const SizedBox(height: 16),
          Text(user.name, style: AppTextStyles.displaySmall),
          Text(user.email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Text(
            'Số dư: ${fmt.format(user.balance)} VND',
            style: AppTextStyles.displaySmall.copyWith(color: AppColors.accentCyan, fontSize: 20),
          ),
          if (user.isLocked)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger),
              ),
              child: const Text('ACCOUNT LOCKED', 
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(BuildContext context, WidgetRef ref, AsyncValue<List<CardModel>> cardsAsync, AsyncValue<List<Map<String, dynamic>>> checkinsAsync, NumberFormat fmt) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('THÔNG TIN LIÊN HỆ'),
        _buildInfoTile('Họ và tên', user.name, Icons.person_outline),
        _buildInfoTile('Email', user.email, Icons.email_outlined),
        _buildInfoTile('Số điện thoại', user.phone.isEmpty ? 'Chưa cập nhật' : user.phone, Icons.phone_outlined),
        const SizedBox(height: 32),
        _buildSectionHeader('TÀI KHOẢN & VAI TRÒ'),
        _buildInfoTile('Vai trò', user.role.toUpperCase(), Icons.admin_panel_settings_outlined),
        _buildInfoTile('Số dư ví', '${fmt.format(user.balance)} VND', Icons.account_balance_wallet_outlined),
        _buildInfoTile(
          'Trạng thái', 
          user.isLocked ? 'Đã khóa' : 'Đang hoạt động', 
          user.isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
          color: user.isLocked ? AppColors.danger : AppColors.success,
        ),
        const SizedBox(height: 32),
        GalaxyButton(
          text: user.isLocked ? 'MỞ KHÓA TÀI KHOẢN' : 'KHÓA TÀI KHOẢN',
          baseColor: user.isLocked ? AppColors.success : AppColors.danger,
          onPressed: () => _handleToggleLock(context, ref),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (color ?? AppColors.accentBlue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color ?? AppColors.accentBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(AsyncValue<List<Map<String, dynamic>>> txAsync, NumberFormat fmt) {
    return txAsync.when(
      data: (txs) => txs.isEmpty 
        ? const Center(child: Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.white38)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: txs.length,
            itemBuilder: (context, index) {
              final tx = txs[index];
              final type = tx['type'] as String;
              final amount = tx['amount'] as num;
              return ListTile(
                title: Text(tx['description'] ?? type, style: AppTextStyles.bodyMedium),
                subtitle: Text(
                  DateFormat('HH:mm dd/MM/yyyy').format((tx['timestamp'] as Timestamp).toDate()),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
                trailing: Text(
                  '${amount > 0 ? '+' : ''}${fmt.format(amount)}',
                  style: TextStyle(
                    color: amount > 0 ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }
}
