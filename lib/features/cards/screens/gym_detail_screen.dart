import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../models/gym_model.dart';
import '../../../shared/galaxy_button.dart';
import '../../auth/auth_provider.dart';
import '../card_provider.dart';
import '../gym_provider.dart';

class GymDetailScreen extends ConsumerStatefulWidget {
  final GymModel gym;
  const GymDetailScreen({super.key, required this.gym});

  @override
  ConsumerState<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends ConsumerState<GymDetailScreen> {
  bool _isPurchasing = false;

  Future<void> _handlePurchase() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (user.balance < widget.gym.pricePerMonth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số dư không đủ. Vui lòng nạp thêm tiền.')),
      );
      return;
    }

    setState(() => _isPurchasing = true);
    
    // Show confirmation dialog before purchase
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text('Xác nhận mua thẻ'),
        content: Text('Bạn có chắc chắn muốn mua thẻ hội viên tại ${widget.gym.name} với giá ${NumberFormat("#,###").format(widget.gym.pricePerMonth)}đ không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('HỦY')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('XÁC NHẬN')),
        ],
      ),
    );

    if (confirmed != true) {
      if (mounted) setState(() => _isPurchasing = false);
      return;
    }

    final success = await ref.read(gymRepositoryProvider).purchaseCard(user.uid, widget.gym);
    
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        // Refresh user data (balance)
        await ref.read(authProvider.notifier).refreshUserData();
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.backgroundSurface,
            title: const Text('Mua thẻ thành công!'),
            content: Text('Bạn đã mua thành công thẻ hội viên tại ${widget.gym.name}.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to store
                  Navigator.pop(context); // Back to cards
                },
                child: const Text('Xem Thẻ Của Tôi'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giao dịch thất bại. Vui lòng thử lại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCards = ref.watch(cardProvider).asData?.value ?? [];
    final bool isOwned = activeCards.any((c) => c.isActive && c.gymId == widget.gym.id);
    final bool isVipActive = activeCards.any((c) => c.isMembership && c.gymId == null && c.isActive);
    
    final brandGradient = AppColors.cardGradients[widget.gym.colorIndex % AppColors.cardGradients.length];
    final navyBg = const Color(0xFF15192C);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 120,
            pinned: true,
            automaticallyImplyLeading: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: brandGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Text(
                      widget.gym.name,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Container(
              color: navyBg,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildContractInfo(navyBg),
                    const SizedBox(height: 120), // Space for bottom sheet
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: navyBg,
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: GalaxyButton(
          text: isOwned ? 'BẠN ĐÃ SỞ HỮU' : (isVipActive ? 'BẠN ĐANG LÀ VIP' : 'MUA THẺ HỘI VIÊN'),
          isLoading: _isPurchasing,
          onPressed: (isOwned || isVipActive) ? null : _handlePurchase,
        ),
      ),
    );
  }

  Widget _buildContractInfo(Color bgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THÔNG TIN HỢP ĐỒNG',
          style: AppTextStyles.labelLarge.copyWith(
            color: Colors.white38,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoTile('Địa chỉ', '${widget.gym.address}, ${widget.gym.city}', Icons.location_on_outlined),
        _buildInfoTile('Giờ mở cửa', '${widget.gym.openTime} - ${widget.gym.closeTime}', Icons.access_time),
        _buildInfoTile('Giá niêm yết', '${NumberFormat("#,###").format(widget.gym.pricePerMonth)}đ/tháng', Icons.payments_outlined),
        _buildInfoTile('Liên hệ', widget.gym.partnerEmail, Icons.email_outlined),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: Colors.white10),
        const SizedBox(height: AppSpacing.md),
        Text('Điều khoản hội viên', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Thẻ hội viên cho phép sử dụng dịch vụ không giới hạn tại ${widget.gym.name} trong khung giờ hoạt động chính thức. Vui lòng xuất trình mã QR để nhân viên quầy kiểm tra khi ra vào.',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accentBlue.withOpacity(0.7)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelLarge.copyWith(color: Colors.white38, fontSize: 10)),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}
