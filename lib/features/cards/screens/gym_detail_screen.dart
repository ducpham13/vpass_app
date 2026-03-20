import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../models/gym_model.dart';
import '../../../shared/galaxy_button.dart';
import '../../auth/auth_provider.dart';
import '../../admin/gym_repository.dart';
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
  bool _isSaving = false;

  // Editing state
  bool _isEditingImage = false;
  bool _isEditingDescription = false;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _imageUrlController = TextEditingController(text: widget.gym.imageUrl);
    _descriptionController = TextEditingController(
      text: widget.gym.description,
    );
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final success = await ref
        .read(gymRepositoryProvider)
        .updateGymProfile(
          widget.gym.id,
          imageUrl: _imageUrlController.text,
          description: _descriptionController.text,
        );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditingImage = false;
        _isEditingDescription = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thất bại. Vui lòng thử lại.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handlePurchase() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (user.balance < widget.gym.pricePerMonth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số dư không đủ. Vui lòng nạp thêm tiền.'),
        ),
      );
      return;
    }

    setState(() => _isPurchasing = true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text('Xác nhận mua thẻ'),
        content: Text(
          'Bạn có chắc chắn muốn mua thẻ hội viên tại ${widget.gym.name} với giá ${NumberFormat("#,###").format(widget.gym.pricePerMonth)}đ không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      if (mounted) setState(() => _isPurchasing = false);
      return;
    }

    final success = await ref
        .read(gymRepositoryProvider)
        .purchaseCard(user.uid, widget.gym);

    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        await ref.read(authProvider.notifier).refreshUserData();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.backgroundSurface,
            title: const Text('Mua thẻ thành công!'),
            content: Text(
              'Bạn đã mua thành công thẻ hội viên tại ${widget.gym.name}.',
            ),
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
          const SnackBar(
            content: Text('Giao dịch thất bại. Vui lòng thử lại.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time updates for this gym if we are the owner or viewer
    final gymStream = ref.watch(gymDetailProvider(widget.gym.id));
    final gym = gymStream.value ?? widget.gym;

    final currentUser = ref.watch(authProvider).user;
    final bool isOwner = currentUser?.uid == gym.ownerUid;

    final activeCards = ref.watch(cardProvider).asData?.value ?? [];
    final bool isOwned = activeCards.any(
      (c) => c.isActive && c.gymId == gym.id,
    );
    final bool isVipActive = activeCards.any(
      (c) => c.isMembership && c.gymId == null && c.isActive,
    );

    final brandGradient = AppColors
        .cardGradients[gym.colorIndex % AppColors.cardGradients.length];
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
                      gym.name,
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
                    // 1. Gym Image Section (Editable for Owner)
                    _buildImageSection(gym, isOwner),
                    const SizedBox(height: 32),

                    // 2. Contract Info & Description
                    _buildContractInfo(gym, isOwner),

                    if (isOwner && (_isEditingImage || _isEditingDescription))
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: GalaxyButton(
                          text: 'LƯU THÔNG TIN',
                          isLoading: _isSaving,
                          onPressed: _handleSave,
                        ),
                      ),

                    const SizedBox(height: 120), // Space for bottom sheet
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: !isOwner
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: navyBg,
                border: const Border(top: BorderSide(color: Colors.white10)),
              ),
              child: GalaxyButton(
                text: isOwned
                    ? 'BẠN ĐÃ SỞ HỮU'
                    : (isVipActive ? 'BẠN ĐANG LÀ VIP' : 'MUA THẺ HỘI VIÊN'),
                isLoading: _isPurchasing,
                onPressed: (isOwned || isVipActive) ? null : _handlePurchase,
              ),
            )
          : null,
    );
  }

  Widget _buildImageSection(GymModel gym, bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HÌNH ẢNH PHÒNG TẬP',
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            if (isOwner)
              IconButton(
                icon: Icon(
                  _isEditingImage ? Icons.close : Icons.edit,
                  size: 18,
                  color: AppColors.accentCyan,
                ),
                onPressed: () =>
                    setState(() => _isEditingImage = !_isEditingImage),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isEditingImage)
          TextField(
            controller: _imageUrlController,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Nhập URL hình ảnh...',
              helperText: 'Dán URL ảnh từ Google Drive hoặc các trang web ảnh.',
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: gym.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: gym.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.white.withOpacity(0.05),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 48, color: Colors.white10),
          SizedBox(height: 8),
          Text('Chưa có hình ảnh', style: TextStyle(color: Colors.white10)),
        ],
      ),
    );
  }

  Widget _buildContractInfo(GymModel gym, bool isOwner) {
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
        _buildInfoTile(
          'Địa chỉ',
          '${gym.address}, ${gym.city}',
          Icons.location_on_outlined,
        ),
        _buildInfoTile(
          'Giờ mở cửa',
          '${gym.openTime} - ${gym.closeTime}',
          Icons.access_time,
        ),
        _buildInfoTile(
          'Giá niêm yết',
          '${NumberFormat("#,###").format(gym.pricePerMonth)}đ/tháng',
          Icons.payments_outlined,
        ),
        _buildInfoTile('Liên hệ', gym.partnerEmail, Icons.email_outlined),

        const SizedBox(height: AppSpacing.md),
        const Divider(color: Colors.white10),
        const SizedBox(height: AppSpacing.md),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MÔ TẢ PHÒNG TẬP',
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            if (isOwner)
              IconButton(
                icon: Icon(
                  _isEditingDescription ? Icons.close : Icons.edit,
                  size: 18,
                  color: AppColors.accentCyan,
                ),
                onPressed: () => setState(
                  () => _isEditingDescription = !_isEditingDescription,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isEditingDescription)
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Nhập mô tả phòng tập...',
            ),
          )
        else
          Text(
            gym.description.isNotEmpty
                ? gym.description
                : 'Phòng tập hiện đại với đầy đủ thiết bị, không gian sạch sẽ thoáng mát, phù hợp cho mọi đối tượng từ cơ bản đến chuyên sâu.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),

        const SizedBox(height: 24),
        Text('Điều khoản hội viên', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Thẻ hội viên cho phép sử dụng dịch vụ không giới hạn tại ${gym.name} trong khung giờ hoạt động chính thức. Vui lòng xuất trình mã QR để nhân viên quầy kiểm tra khi ra vào.',
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
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}
