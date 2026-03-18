import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../models/card_model.dart';
import '../../../models/gym_model.dart';
import '../widgets/gym_card.dart';
import '../gym_provider.dart';
import '../card_provider.dart';
import '../../../shared/galaxy_button.dart';
import 'qr_screen.dart';

class CardDetailSheet extends ConsumerStatefulWidget {
  final CardModel card;
  final GymModel? initialGym;

  const CardDetailSheet({
    super.key,
    required this.card,
    this.initialGym,
  });

  @override
  ConsumerState<CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends ConsumerState<CardDetailSheet> {
  GymModel? _selectedGymForCheckin;

  @override
  void initState() {
    super.initState();
    _selectedGymForCheckin = widget.initialGym;
  }

  @override
  Widget build(BuildContext context) {
    final gymsAsync = ref.watch(gymsProvider);
    
    // Auto-set the single gym if not global and not set yet
    final gym = gymsAsync.whenOrNull(data: (gyms) => gyms.firstWhereOrNull((g) => g.id == widget.card.gymId));
    if (widget.card.gymId != null && _selectedGymForCheckin == null && gym != null) {
      _selectedGymForCheckin = gym;
    }

    final displayGym = _selectedGymForCheckin ?? gym ?? GymModel(
      id: widget.card.gymId ?? '',
      name: widget.card.gymId == null ? 'Vpass Global Member' : 'Gym Membership',
      address: 'Membership Details',
      city: '',
      description: '',
      imageUrl: '',
      pricePerMonth: widget.card.priceSnapshot,
      ownerUid: '',
      ownerName: '',
      partnerEmail: '',
      bankName: '',
      bankCardNumber: '',
      bankAccountName: '',
      feeRate: 0,
      status: 'active',
      openTime: '06:00',
      closeTime: '22:00',
      crowdLevel: 'average',
      isClosedOverride: false,
    );

    // ── Determine badge text based on card type ──
    final daysLeft = widget.card.endDate.difference(DateTime.now()).inDays;
    String? badgeText;

    final bool isRegularCard = widget.card.gymId != null; // Regular monthly card
    final bool isVipCard = widget.card.gymId == null && widget.initialGym == null; // VIP main view
    final bool isGymInVip = widget.card.gymId == null && widget.initialGym != null; // Gym selected within VIP

    if (isRegularCard) {
      // Regular card: show "Còn X ngày"
      badgeText = daysLeft < 0 ? 'Hết hạn' : 'Còn $daysLeft ngày';
    } else if (isGymInVip) {
      // Gym within VIP: no days badge needed (VIP card itself shows days)
      badgeText = null;
    } else {
      // VIP card main view: days shown on VIP card widget itself
      badgeText = daysLeft < 0 ? 'Hết hạn' : 'Còn $daysLeft ngày';
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2),),
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Hero(
                      tag: 'card_${widget.card.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: GymCard(
                          gym: displayGym,
                          showOperationalInfo: false,
                          customBadgeText: badgeText,
                          useSolidColor: true,
                          onTap: () {},
                        ),
                      ),
                    ),
                    
                    // ── VIP card only: show quota section ──
                    if (widget.card.isMembership && widget.card.gymId == null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildQuotaSection(widget.card, _selectedGymForCheckin),
                    ],

                    // ── Regular card: show simple "days remaining" info ──
                    if (isRegularCard && widget.card.isMembership) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildRegularCardInfo(widget.card),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    
                    if (isVipCard) ...[
                      Text('CHỌN PHÒNG GYM ĐỂ VÀO TẬP', style: AppTextStyles.labelLarge.copyWith(color: Colors.white38)),
                      const SizedBox(height: AppSpacing.md),
                      _buildGymPicker(gymsAsync),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    _buildDetails(displayGym),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    if (!widget.card.isExpired) ...[
                      GalaxyButton(
                        text: 'TẠO MÃ QR CHECK-IN',
                        onPressed: (widget.card.gymId == null && _selectedGymForCheckin == null)
                          ? null 
                          : () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QrScreen(
                                    card: widget.card,
                                    gymId: widget.card.gymId ?? _selectedGymForCheckin!.id,
                                  ),
                                ),
                              );
                            },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (widget.card.gymId != null) // Only for single gym cards
                        TextButton(
                          onPressed: () => _handleCancel(context, ref),
                          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                          child: const Text('Hủy thẻ thành viên này', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text('Xác nhận hủy thẻ'),
        content: const Text('Bạn có chắc chắn muốn hủy thẻ này không? Sau khi hủy, thẻ sẽ không còn sử dụng được và không được hoàn tiền.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('KHÔNG')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('CÓ, HỦY THẺ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(cardRepositoryProvider).updateCardStatus(
        widget.card.id, 
        'expired',
        reason: 'Cancelled by User',
      );
      // Also update reason in a separate call if needed, but for now we can just use set status
      // In the future we might want to update multiple fields at once.
      // Let's refine the updateCardStatus to accept reason too if we want better history.
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy thẻ thành công.'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Widget _buildQuotaSection(CardModel card, GymModel? selectedGym) {
    final limit = (card.membershipPrice ?? 0) * 0.95;
    final progress = (card.usedValue / limit).clamp(0.0, 1.0);
    final isHighUsage = progress > 0.8;
    
    int? estimatedRemaining;
    if (selectedGym != null) {
      final remaining = limit - card.usedValue;
      final sessionPrice = selectedGym.pricePerMonth / 30;
      if (sessionPrice > 0 && remaining >= sessionPrice) {
        // Fix: only count full sessions that actually fit within remaining
        estimatedRemaining = (remaining / sessionPrice).floor();
      } else {
        estimatedRemaining = 0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('HẠN MỨC SỬ DỤNG', style: AppTextStyles.labelLarge.copyWith(color: Colors.white38)),
            Text('${(progress * 100).toInt()}%', style: AppTextStyles.labelLarge.copyWith(color: isHighUsage ? AppColors.danger : AppColors.success)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(isHighUsage ? AppColors.danger : AppColors.accentCyan),
            minHeight: 8,
          ),
        ),
        if (estimatedRemaining != null)
           Padding(
             padding: const EdgeInsets.only(top: 16),
             child: Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: AppColors.accentCyan.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
               ),
               child: Row(
                 children: [
                   const Icon(Icons.flash_on, color: AppColors.accentCyan, size: 20),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'ƯỚC TÍNH CÒN LẠI',
                           style: AppTextStyles.labelLarge.copyWith(color: AppColors.accentCyan, fontSize: 10, letterSpacing: 1),
                         ),
                         Text(
                           '$estimatedRemaining buổi tập tại đây',
                           style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                         ),
                       ],
                     ),
                   ),
                 ],
               ),
             ),
           ),
      ],
    );
  }

  Widget _buildRegularCardInfo(CardModel card) {
    final daysLeft = card.endDate.difference(DateTime.now()).inDays;
    final isExpiring = daysLeft <= 3;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isExpiring ? AppColors.danger : AppColors.success).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isExpiring ? AppColors.danger : AppColors.success).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isExpiring ? Icons.timer_off : Icons.timer,
            color: isExpiring ? AppColors.danger : AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THỜI HẠN THẺ',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isExpiring ? AppColors.danger : AppColors.success,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  daysLeft < 0 
                    ? 'Thẻ đã hết hạn'
                    : 'Còn $daysLeft ngày — Quẹt không giới hạn',
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGymPicker(AsyncValue<List<GymModel>> gymsAsync) {
    return gymsAsync.when(
      data: (gyms) => SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: gyms.length,
          itemBuilder: (context, index) {
            final gym = gyms[index];
            final isSelected = _selectedGymForCheckin?.id == gym.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedGymForCheckin = gym),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentBlue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColors.accentBlue : Colors.white.withOpacity(0.05), width: 2),
                ),
                child: Center(
                  child: Text(
                    gym.name, 
                    textAlign: TextAlign.center, 
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(color: isSelected ? Colors.white : Colors.white60, fontSize: 12),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Lỗi tải phòng: $e'),
    );
  }

  Widget _buildDetails(GymModel gym) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoTile('Địa chỉ', '${gym.address}, ${gym.city}', Icons.location_on_outlined),
        _buildInfoTile('Giờ mở cửa', '${gym.openTime} - ${gym.closeTime}', Icons.access_time),
        _buildInfoTile('Giá niêm yết', '${NumberFormat("#,###").format(gym.pricePerMonth)}đ/tháng', Icons.payments_outlined),
        _buildInfoTile('Liên hệ', gym.partnerEmail, Icons.email_outlined),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: Colors.white10),
        const SizedBox(height: AppSpacing.md),
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
              Text(label, style: AppTextStyles.labelLarge.copyWith(color: Colors.white38, fontSize: 10)),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}
