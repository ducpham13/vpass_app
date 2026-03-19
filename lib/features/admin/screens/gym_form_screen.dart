import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/gym_model.dart';
import '../../auth/auth_provider.dart';
import '../../cards/gym_provider.dart';
import '../../../core/utils/validators.dart';

class GymFormScreen extends ConsumerStatefulWidget {
  final GymModel? gym;
  final bool isReadOnly;
  final bool editOpsOnly;

  const GymFormScreen({
    super.key,
    this.gym,
    this.isReadOnly = false,
    this.editOpsOnly = false,
  });

  @override
  ConsumerState<GymFormScreen> createState() => _GymFormScreenState();
}

class _GymFormScreenState extends ConsumerState<GymFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _priceController;
  late TextEditingController _ownerNameController;
  late TextEditingController _partnerEmailController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankCardNumberController;
  late TextEditingController _bankAccountNameController;
  late TextEditingController _feeRateController;
  late TextEditingController _openTimeController;
  late TextEditingController _closeTimeController;
  late TextEditingController _emergencyNoticeController;
  String _status = 'pending';
  String _crowdLevel = 'average';
  bool _isClosedOverride = false;
  int _colorIndex = 1;
  late TextEditingController _rejectionReasonController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gym?.name ?? '');
    _addressController = TextEditingController(text: widget.gym?.address ?? '');
    _cityController = TextEditingController(text: widget.gym?.city ?? '');
    _priceController = TextEditingController(
      text: widget.gym?.pricePerMonth.toString() ?? '0',
    );
    _ownerNameController = TextEditingController(
      text: widget.gym?.ownerName ?? '',
    );
    _partnerEmailController = TextEditingController(
      text: widget.gym?.partnerEmail ?? '',
    );
    _bankNameController = TextEditingController(
      text: widget.gym?.bankName ?? '',
    );
    _bankCardNumberController = TextEditingController(
      text: widget.gym?.bankCardNumber ?? '',
    );
    _bankAccountNameController = TextEditingController(
      text: widget.gym?.bankAccountName ?? '',
    );
    _feeRateController = TextEditingController(
      text: (widget.gym?.feeRate ?? 0.1).toString(),
    );
    _openTimeController = TextEditingController(
      text: widget.gym?.openTime ?? '06:00',
    );
    _closeTimeController = TextEditingController(
      text: widget.gym?.closeTime ?? '22:00',
    );
    _emergencyNoticeController = TextEditingController(
      text: widget.gym?.emergencyNotice ?? '',
    );
    _rejectionReasonController = TextEditingController(
      text: widget.gym?.rejectionReason ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.gym?.imageUrl ?? '',
    );
    _status = widget.gym?.status ?? 'pending';
    _crowdLevel = widget.gym?.crowdLevel ?? 'average';
    _isClosedOverride = widget.gym?.isClosedOverride ?? false;
    _colorIndex = widget.gym?.colorIndex ?? 1; // Default to 1 (Blue) if new
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _ownerNameController.dispose();
    _partnerEmailController.dispose();
    _bankNameController.dispose();
    _bankCardNumberController.dispose();
    _bankAccountNameController.dispose();
    _feeRateController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    _emergencyNoticeController.dispose();
    _rejectionReasonController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    final isAdmin = currentUser.isSuperAdmin;

    final gym = GymModel(
      id: widget.gym?.id ?? '',
      name: _nameController.text,
      address: _addressController.text,
      city: _cityController.text,
      description: '', // Ghi chú đã bị loại bỏ
      imageUrl: _imageUrlController.text,
      pricePerMonth: double.tryParse(_priceController.text) ?? 0,
      ownerUid: widget.gym?.ownerUid ?? currentUser.uid,
      ownerName: isAdmin
          ? _ownerNameController.text
          : (widget.gym?.ownerName ?? currentUser.name),
      partnerEmail: isAdmin
          ? _partnerEmailController.text
          : (widget.gym?.partnerEmail ?? currentUser.email),
      bankName: _bankNameController.text,
      bankCardNumber: _bankCardNumberController.text,
      bankAccountName: _bankAccountNameController.text,
      feeRate: isAdmin
          ? (double.tryParse(_feeRateController.text) ?? 0.1)
          : (widget.gym?.feeRate ?? 0.1),
      status: isAdmin ? _status : (widget.gym?.status ?? 'pending'),
      createdAt: widget.gym?.createdAt,
      openTime: _openTimeController.text,
      closeTime: _closeTimeController.text,
      crowdLevel: _crowdLevel,
      isClosedOverride: _isClosedOverride,
      emergencyNotice: _emergencyNoticeController.text.isEmpty
          ? null
          : _emergencyNoticeController.text,
      lastOperationalReset: widget.gym?.lastOperationalReset ?? DateTime.now(),
      colorIndex: _colorIndex,
      rejectionReason: _rejectionReasonController.text.isEmpty
          ? null
          : _rejectionReasonController.text,
    );

    // Validate Time Range
    if (!Validators.isBefore(gym.openTime, gym.closeTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giờ mở cửa phải sớm hơn giờ đóng cửa!'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    try {
      if (widget.gym == null) {
        await ref.read(gymRepositoryProvider).addGym(gym);
      } else {
        await ref.read(gymRepositoryProvider).updateGym(gym);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('L?i: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isAdmin = currentUser?.isSuperAdmin ?? false;
    final isOwner = currentUser?.uid == widget.gym?.ownerUid;
    final isEdit = widget.gym != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReadOnly
              ? 'Chi tiết phòng tập'
              : (widget.editOpsOnly
                    ? 'Vận hành hàng ngày'
                    : (widget.gym == null
                          ? 'Đăng ký phòng tập'
                          : 'Quản lý phòng tập')),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isEdit && !isAdmin && !widget.isReadOnly) ...[
                _buildSectionHeader('VẬN HÀNH HÀNG NGÀY', Icons.update),
                const SizedBox(height: 16),
                _buildOperationalSection(),
                const SizedBox(height: 32),
              ],
              if (!widget.editOpsOnly) ...[
                _buildSectionHeader('THÔNG TIN HỢP ĐỒNG', Icons.description),
                const SizedBox(height: 16),
                _buildContractSection(isAdmin, isOwner),
                const SizedBox(height: 32),
              ],
              if (isAdmin && !widget.editOpsOnly && !widget.isReadOnly) ...[
                _buildAdminOnlyFields(isEdit, isAdmin),
                const SizedBox(height: 32),
              ],
              if (!widget.isReadOnly || (isOwner && !widget.editOpsOnly))
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isAdmin
                        ? 'LƯU THÔNG TIN'
                        : (widget.gym == null
                              ? 'GỬI YÊU CẦU DUYỆT'
                              : 'LƯU THAY ĐỔI'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accentBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.accentBlue,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trạng thái mở cửa hôm nay', style: AppTextStyles.bodyMedium),
              Switch(
                value: !_isClosedOverride,
                onChanged: (v) => setState(() => _isClosedOverride = !v),
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
          if (_isClosedOverride)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Lưu ý: Lựa chọn này sẽ ghi đè giờ hoạt động bình thường thành "Đóng cửa hôm nay"',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Mức độ đông đúc', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'quiet',
                label: Text('Vắng'),
                icon: Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: 'average',
                label: Text('Bình thường'),
                icon: Icon(Icons.people_outline),
              ),
              ButtonSegment(
                value: 'busy',
                label: Text('Đông'),
                icon: Icon(Icons.groups),
              ),
            ],
            selected: {_crowdLevel},
            onSelectionChanged: (v) => setState(() => _crowdLevel = v.first),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emergencyNoticeController,
            decoration: const InputDecoration(
              labelText: 'Thông báo khẩn cấp (Không bắt buộc)',
              hintText: 'VD: Nghỉ lễ, sửa chữa...',
              prefixIcon: Icon(Icons.warning_amber_rounded),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildContractSection(bool isAdmin, bool isOwner) {
    final isEdit = widget.gym != null;
    final canEdit =
        !widget.isReadOnly &&
        (isAdmin || widget.gym == null) &&
        !(isAdmin && isEdit);
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          enabled: canEdit,
          decoration: const InputDecoration(labelText: 'Tên phòng tập'),
          validator: (v) => v?.isEmpty ?? true ? 'Bắt buộc' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          enabled: canEdit,
          decoration: const InputDecoration(labelText: 'Địa chỉ'),
          validator: (v) => v?.isEmpty ?? true ? 'Bắt buộc' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cityController,
          enabled: canEdit,
          decoration: const InputDecoration(labelText: 'Thành phố'),
          validator: (v) => Validators.validateNotEmpty(v, 'Thành phố'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _imageUrlController,
          enabled: canEdit || isOwner,
          decoration: const InputDecoration(
            labelText: 'Ảnh phòng tập (URL - Không bắt buộc)',
            hintText: 'https://example.com/image.jpg',
          ),
          validator: (v) => (v == null || v.isEmpty) ? null : Validators.validateUrl(v, 'Ảnh'),
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white10),
        const SizedBox(height: 24),
        _buildSectionHeader('THÔNG TIN THANH TOÁN', Icons.account_balance),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bankNameController,
          enabled: canEdit || isOwner,
          decoration: const InputDecoration(labelText: 'Tên ngân hàng'),
          validator: (v) => Validators.validateNotEmpty(v, 'Tên ngân hàng'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bankCardNumberController,
          enabled: canEdit || isOwner,
          decoration: const InputDecoration(
            labelText: 'Số tài khoản ngân hàng',
          ),
          keyboardType: TextInputType.number,
          validator: (v) => Validators.validateNumber(v, 'Số tài khoản'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bankAccountNameController,
          enabled: canEdit || isOwner,
          decoration: const InputDecoration(
            labelText: 'Tên chủ tài khoản',
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (v) => Validators.validateNotEmpty(v, 'Tên chủ tài khoản'),
        ),
        const SizedBox(height: 24),
        if (isAdmin || widget.gym == null) ...[
          Text(
            'Màu chủ đạo (Hiển thị trên thẻ Dashboard)',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppColors.cardGradients.length - 1,
              itemBuilder: (context, index) {
                final realIndex = index + 1; // Skip red (0)
                final colors = AppColors.cardGradients[realIndex];
                final isSelected = _colorIndex == realIndex;
                return GestureDetector(
                  onTap: () => setState(() => _colorIndex = realIndex),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _openTimeController,
                enabled: canEdit,
                decoration: const InputDecoration(
                  labelText: 'Giờ mở cửa',
                  hintText: '06:00',
                ),
                validator: (v) => Validators.validateTimeFormat(v),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _closeTimeController,
                enabled: canEdit,
                decoration: const InputDecoration(
                  labelText: 'Giờ đóng cửa',
                  hintText: '22:00',
                ),
                validator: (v) => Validators.validateTimeFormat(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _priceController,
          enabled: canEdit,
          decoration: const InputDecoration(labelText: 'Giá gói tháng (VND)'),
          keyboardType: TextInputType.number,
          validator: (v) => Validators.validatePrice(v, 'Giá gói tháng'),
        ),
      ],
    );
  }

  Widget _buildAdminOnlyFields(bool isEdit, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('BẢNG ĐIỀU KHIỂN ADMIN', Icons.security),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _partnerEmailController,
                enabled: !isEdit,
                decoration: const InputDecoration(labelText: 'Email đối tác'),
                validator: (v) => Validators.validateEmail(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerNameController,
                enabled: !isEdit,
                decoration: const InputDecoration(labelText: 'Tên chủ sở hữu'),
                validator: (v) => Validators.validateNotEmpty(v, 'Tên chủ sở hữu'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _feeRateController,
                enabled:
                    !isEdit || (isAdmin && (widget.gym?.feeRate ?? 0) <= 0),
                decoration: InputDecoration(
                  labelText: 'Tỷ lệ phí (0.0 - 1.0)',
                  helperText: isEdit && (widget.gym?.feeRate ?? 0) > 0
                      ? 'Tỷ lệ phí được khóa sau khi tạo'
                      : 'Thiết lập tỷ lệ phí cho đối tác này',
                  helperStyle: isEdit && (widget.gym?.feeRate ?? 0) > 0
                      ? const TextStyle(color: AppColors.textSecondary)
                      : null,
                ),
                keyboardType: TextInputType.number,
                validator: (v) => Validators.validateNumber(v, 'Tỷ lệ phí'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái phê duyệt'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('Chờ duyệt/Xem xét'),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Ngừng hoạt động/Đóng cửa'),
                  ),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              if (_status == 'rejected' || _status == 'inactive') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rejectionReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Lý do từ chối',
                    hintText: 'Nhập lý do từ chối...',
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
