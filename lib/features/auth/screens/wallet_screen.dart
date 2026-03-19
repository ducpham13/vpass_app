import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/galaxy_button.dart';
import '../auth_provider.dart';
import '../deposit_provider.dart';
import '../../../shared/glass_container.dart';
import '../../../core/constants/app_constants.dart';
import '../../cards/gym_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _fmt = NumberFormat('#,###');
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Nạp tiền', 'Mua thẻ', 'Hoàn tiền'];

  // Top-up selection state (used in dialog)
  double _depositAmount = 100000;
  final List<double> _presetAmounts = [50000, 100000, 200000, 500000];
  bool _isProcessing = false;

  Future<void> _handleTopUp() async {
    final selected = await showDialog<double>(
      context: context,
      builder: (context) => _AmountSelectionDialog(
        presetAmounts: _presetAmounts,
        initialAmount: _depositAmount,
      ),
    );

    if (selected == null) return;
    _depositAmount = selected;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    final dateStr = DateFormat('ddMMHHmm').format(DateTime.now());
    final emailPrefix = user.email.split('@').first;
    final transferContent = '${emailPrefix}_${_depositAmount.toInt()}_$dateStr';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _TransferInfoDialog(amount: _depositAmount, content: transferContent),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(depositRepositoryProvider)
          .requestDeposit(
            user.uid,
            user.name,
            _depositAmount,
            adminNote: 'Content: $transferContent',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gửi yêu cầu nạp ${_fmt.format(_depositAmount.toInt())} VND thành công. Vui lòng chờ admin duyệt.',
            ),
            backgroundColor: AppColors.accentBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi yêu cầu thất bại. Vui lòng thử lại.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundPrimary,
              AppColors.backgroundPrimary.withOpacity(0.9),
              AppColors.backgroundPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                      'VÍ CỦA TÔI',
                      style: AppTextStyles.displayMedium.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(user?.balance ?? 0),
                      const SizedBox(height: 16),
                      _buildPendingSummaryBanner(),
                      const SizedBox(height: 32),
                      Text(
                        'LỊCH SỬ GIAO DỊCH',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFilters(),
                      const SizedBox(height: 20),
                      _buildTransactionList(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D2D5F),
            const Color(0xFF1E1E3F).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentBlue.withOpacity(0.05),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SỐ DƯ HIỆN TẠI',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt.format(balance.toInt()),
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'VND',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleTopUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D5FEF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Nạp tiền',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSummaryBanner() {
    final requestsAsync = ref.watch(userDepositRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        final pending = requests.where((r) => r.status == 'pending').toList();
        if (pending.isEmpty) return const SizedBox.shrink();

        final totalPending = pending.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );
        final latestReq = pending.first;
        final reqId = latestReq.adminNote?.split('Content: ').last ?? '???';

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF231B12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF433018)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pending.length} yêu cầu nạp tiền đang chờ xác nhận',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFFEAB308),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$reqId - ${_fmt.format(totalPending.toInt())}đ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFFEAB308).withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedFilter = f);
              },
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedColor: const Color(0xFF1E3A8A).withOpacity(0.3),
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.accentBlue : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.accentBlue.withOpacity(0.5)
                      : Colors.white10,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionList() {
    final historyAsync = ref.watch(unifiedWalletHistoryProvider);

    return historyAsync.when(
      data: (items) {
        final filtered = items.where((item) {
          if (_selectedFilter == 'Tất cả') return true;
          if (_selectedFilter == 'Nạp tiền') return item.isTopUp;
          if (_selectedFilter == 'Mua thẻ') return item.isPurchase;
          if (_selectedFilter == 'Hoàn tiền') return item.isRefund;
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Text(
                'Chưa có giao dịch nào',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return _buildHistoryItem(item);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Lỗi: $err'),
    );
  }

  Widget _buildHistoryItem(UnifiedHistoryItem item) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.iconBgColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/2026 - HH:mm').format(item.date),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentBlue.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.amountPrefix}${_fmt.format(item.amount.toInt())}',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: item.amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.statusLabel,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: item.statusColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UnifiedHistoryItem {
  final String title;
  final String? subtitle;
  final DateTime date;
  final double amount;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isTopUp;
  final bool isPurchase;
  final bool isRefund;
  final String? status; // Add status field

  UnifiedHistoryItem({
    required this.title,
    this.subtitle,
    required this.date,
    required this.amount,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.isTopUp = false,
    this.isPurchase = false,
    this.isRefund = false,
    this.status,
  });

  String get amountPrefix {
    if (status == 'rejected') return ""; // No prefix for rejected
    return (isTopUp || isRefund) ? "+" : "-";
  }

  Color get amountColor {
    if (status == 'rejected') return AppColors.danger;
    return (isTopUp || isRefund) ? const Color(0xFF10B981) : Colors.white;
  }
}

final unifiedWalletHistoryProvider =
    Provider<AsyncValue<List<UnifiedHistoryItem>>>((ref) {
      final txsAsync = ref.watch(transactionHistoryProvider_Internal);
      final depsAsync = ref.watch(userDepositRequestsProvider);
      final gymsAsync = ref.watch(allGymsProvider);

      if (txsAsync.isLoading || depsAsync.isLoading || gymsAsync.isLoading) {
        return const AsyncValue.loading();
      }

      if (txsAsync.hasError)
        return AsyncValue.error(txsAsync.error!, txsAsync.stackTrace!);
      if (depsAsync.hasError)
        return AsyncValue.error(depsAsync.error!, depsAsync.stackTrace!);

      final txs = txsAsync.value ?? [];
      final deps = depsAsync.value ?? [];
      final gyms = gymsAsync.value ?? [];

      final List<UnifiedHistoryItem> items = [];

      // 1. Process Deposit Requests (Show all: pending, approved, rejected)
      for (final d in deps) {
        items.add(
          UnifiedHistoryItem(
            title: 'Nạp tiền',
            subtitle: d.adminNote?.split('Content: ').last,
            date: d.timestamp,
            amount: d.amount,
            statusLabel: d.status == 'pending'
                ? 'Chờ duyệt'
                : d.status == 'approved'
                ? 'Đã duyệt'
                : 'Từ chối',
            statusColor: d.status == 'pending'
                ? AppColors.warning
                : d.status == 'approved'
                ? AppColors.success
                : AppColors.danger,
            icon: Icons.credit_card_outlined,
            iconColor: d.status == 'rejected' ? AppColors.danger : const Color(0xFF10B981),
            iconBgColor: d.status == 'rejected' ? AppColors.danger : const Color(0xFF10B981),
            isTopUp: true,
            status: d.status,
          ),
        );
      }

      // 2. Process Transactions (Filter out deposits to avoid duplication with deposit_requests)
      for (final tx in txs) {
        final type = tx['type']?.toString().toLowerCase() ?? '';
        if (type == 'deposit' || type == 'topup') continue;

        final isPurchase = type == 'purchase' || type == 'purchase_global';
        final isRefund = type == 'refund';
        final amount = (tx['amount'] ?? 0).toDouble().abs();
        final timestamp = tx['timestamp'];
        final date = timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.now();

        String title = 'Giao dịch';
        if (type == 'purchase_global') {
          title = 'Thẻ VIP';
        } else if (type == 'purchase') {
          final gymId = tx['gymId'];
          final gym = gyms.cast<dynamic>().firstWhere(
            (g) => g.id == gymId,
            orElse: () => null,
          );
          title = gym != null ? 'Thẻ ${gym.name}' : 'Mua thẻ';
        } else if (isRefund) {
          title = 'Hoàn tiền';
        }

        items.add(
          UnifiedHistoryItem(
            title: title,
            subtitle: tx['description'],
            date: date,
            amount: amount,
            statusLabel: 'Thành công',
            statusColor: AppColors.success,
            icon: isPurchase
                ? Icons.confirmation_number_outlined
                : isRefund
                ? Icons.refresh
                : Icons.receipt_long,
            iconColor: isRefund
                ? const Color(0xFF10B981)
                : const Color(0xFFEAB308),
            iconBgColor: isRefund
                ? const Color(0xFF10B981)
                : const Color(0xFF6366F1),
            isPurchase: isPurchase,
            isRefund: isRefund,
          ),
        );
      }

      items.sort((a, b) => b.date.compareTo(a.date));
      return AsyncValue.data(items);
    });

final transactionHistoryProvider_Internal =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
      final user = ref.watch(authProvider).user;
      if (user == null) return Stream.value([]);

      return FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList(),
          );
    });

class _AmountSelectionDialog extends StatefulWidget {
  final List<double> presetAmounts;
  final double initialAmount;

  const _AmountSelectionDialog({
    required this.presetAmounts,
    required this.initialAmount,
  });

  @override
  State<_AmountSelectionDialog> createState() => _AmountSelectionDialogState();
}

class _AmountSelectionDialogState extends State<_AmountSelectionDialog> {
  late double _selectedAmount;
  final _fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _selectedAmount = widget.initialAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CHỌN SỐ TIỀN NẠP', style: AppTextStyles.displaySmall),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: widget.presetAmounts.length,
              itemBuilder: (context, index) {
                final amount = widget.presetAmounts[index];
                final isSelected = _selectedAmount == amount;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAmount = amount),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accentBlue.withOpacity(0.2)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentBlue
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _fmt.format(amount.toInt()),
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            GalaxyButton(
              text: 'TIẾP TỤC',
              onPressed: () => Navigator.pop(context, _selectedAmount),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferInfoDialog extends StatelessWidget {
  final double amount;
  final String content;

  const _TransferInfoDialog({required this.amount, required this.content});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CHUYỂN KHOẢN NẠP TIỀN', style: AppTextStyles.displaySmall),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data:
                    'STK:${AppConstants.adminBankAccount}|Bank:${AppConstants.adminBankName}|Amount:$amount|Content:$content',
                version: QrVersions.auto,
                size: 160.0,
              ),
            ),

            const SizedBox(height: 20),
            _buildBankInfoRow('Ngân hàng', AppConstants.adminBankName),
            _buildBankInfoRow('Số tài khoản', AppConstants.adminBankAccount),
            _buildBankInfoRow('Chủ tài khoản', AppConstants.adminAccountName),
            _buildBankInfoRow('Số tiền', '${fmt.format(amount)} VND'),
            _buildBankInfoRow('Nội dung', content, isHighlight: true),

            const SizedBox(height: 24),
            GalaxyButton(
              text: 'XÁC NHẬN ĐÃ CHUYỂN',
              onPressed: () => Navigator.pop(context, true),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('HỦY', style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankInfoRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isHighlight ? AppColors.accentCyan : Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
