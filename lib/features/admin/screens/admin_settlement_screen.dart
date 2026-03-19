import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/glass_container.dart';
import '../../partner/partner_earnings_provider.dart';
import '../../cards/gym_provider.dart';
import '../../../models/withdrawal_model.dart';

class AdminSettlementScreen extends ConsumerStatefulWidget {
  const AdminSettlementScreen({super.key});

  @override
  ConsumerState<AdminSettlementScreen> createState() => _AdminSettlementScreenState();
}

class _AdminSettlementScreenState extends ConsumerState<AdminSettlementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(filteredPendingWithdrawalsProvider);
    final historyAsync = ref.watch(filteredHistoryWithdrawalsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('QUẢN LÝ ĐỐI SOÁT'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => ref.read(settlementSearchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo Gym ID, Partner hoặc Ngân hàng...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(settlementSearchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accentCyan,
                labelColor: AppColors.accentCyan,
                unselectedLabelColor: AppColors.textMuted,
                tabs: const [
                  Tab(text: 'YÊU CẦU'),
                  Tab(text: 'LỊCH SỬ'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWithdrawalList(pendingAsync, currencyFormat, isHistory: false),
          _buildWithdrawalList(historyAsync, currencyFormat, isHistory: true),
        ],
      ),
    );
  }

  Widget _buildWithdrawalList(AsyncValue<List<WithdrawalModel>> asyncData, NumberFormat currencyFormat, {required bool isHistory}) {
    return asyncData.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Text(
              isHistory ? 'Không có lịch sử đối soát' : 'Không có yêu cầu nào đang chờ',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _WithdrawalCard(request: request, currencyFormat: currencyFormat, isHistory: isHistory);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Lỗi: $err')),
    );
  }
}

class _WithdrawalCard extends ConsumerWidget {
  final WithdrawalModel request;
  final NumberFormat currencyFormat;
  final bool isHistory;

  const _WithdrawalCard({required this.request, required this.currencyFormat, required this.isHistory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(request.timestamp);
    Color statusColor = AppColors.warning;
    if (request.status == 'paid') statusColor = AppColors.success;
    if (request.status == 'rejected') statusColor = AppColors.danger;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(request.amount),
                style: AppTextStyles.displaySmall.copyWith(color: AppColors.accentCyan, fontSize: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeStr, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                  if (isHistory)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor, width: 0.5),
                      ),
                      child: Text(
                        request.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          
          ref.watch(gymDetailProvider(request.gymId)).when(
            data: (gym) {
              if (gym == null) return _buildInfoRow('Lỗi', 'Không tìm thấy Gym data');
              return Column(
                children: [
                  _buildInfoRow('Phòng tập', gym.name),
                  _buildInfoRow('Địa chỉ', '${gym.address}, ${gym.city}'),
                  _buildInfoRow('Email', gym.partnerEmail),
                  Divider(height: 16, color: Colors.white.withOpacity(0.05)),
                  _buildInfoRow('Ngân hàng', gym.bankName),
                  _buildInfoRow('Số tài khoản', gym.bankCardNumber),
                  _buildInfoRow('Chủ tài khoản', gym.bankAccountName),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => _buildInfoRow('Lỗi tải Gym', e.toString()),
          ),

          if (request.adminNote != null)
            _buildInfoRow('Ghi chú', request.adminNote!),
          
          const SizedBox(height: 16),
          if (!isHistory) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(context, ref, 'rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                    child: const Text('TỪ CHỐI'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(context, ref, 'paid'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text('ĐÃ THANH TOÁN'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value, 
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String status) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'paid' ? 'Xác nhận thanh toán?' : 'Từ chối yêu cầu?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hành động này không thể hoàn tác.'),
            if (status == 'rejected')
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Lý do từ chối'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('HỦY')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('ĐỒNG Ý', style: TextStyle(color: AppColors.accentCyan)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(partnerEarningsRepositoryProvider).updateWithdrawalStatus(
        request.id, 
        status, 
        adminNote: status == 'rejected' ? noteController.text : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái: $status')),
        );
      }
    }
  }
}
