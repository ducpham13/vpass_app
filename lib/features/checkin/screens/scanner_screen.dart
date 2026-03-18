import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../checkin_provider.dart';
import 'history_screen.dart';
import '../../auth/screens/profile_screen.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/auth_provider.dart';
import '../checkin_repository.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final String gymId;
  const ScannerScreen({super.key, required this.gymId});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = false; // Local guard — set synchronously

  void _handleBarcode(BarcodeCapture capture) {
    // Local guard (synchronous) — MobileScanner fires onDetect many times/sec
    if (_isScanning) return;
    final state = ref.read(checkinProvider);
    if (state.isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      _processCheckIn(code);
    }
  }

  Future<void> _processCheckIn(String cardId) async {
    _isScanning = true; // Block further scans immediately
    final result = await ref.read(checkinProvider.notifier).scanCard(cardId, widget.gymId);
    
    if (mounted) {
      _showResultOverlay(result);
    }
  }
  
  void _showResultOverlay(CheckinResult result) {
    final String timeStr = DateFormat('HH:mm:ss - dd/MM/yyyy').format(result.timestamp ?? DateTime.now());

    // 3-color logic
    Color resultColor;
    IconData resultIcon;
    String resultTitle;

    switch (result.resultType) {
      case CheckinResultType.success:
        resultColor = AppColors.success;
        resultIcon = Icons.check_circle;
        resultTitle = "Check-in thành công";
        break;
      case CheckinResultType.alreadyToday:
        resultColor = const Color(0xFFFBC02D); // Yellow
        resultIcon = Icons.info;
        resultTitle = "Đã check-in hôm nay";
        break;
      case CheckinResultType.fail:
        resultColor = AppColors.danger;
        resultIcon = Icons.error;
        resultTitle = "Từ chối";
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: resultColor.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: resultColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(resultIcon, color: resultColor, size: 80),
              ),
              const SizedBox(height: 24),
              Text(
                resultTitle,
                style: AppTextStyles.displayMedium.copyWith(color: resultColor),
              ),
              const SizedBox(height: 24),
              if (result.success) ...[
                _buildInfoRow("Thành viên", result.userName ?? "Ẩn danh"),
                _buildInfoRow("Loại thẻ", result.cardType ?? "Thành viên"),
                _buildInfoRow("Phòng", result.gymName ?? "Vpass Gym"),
                _buildInfoRow("Thời gian", timeStr),
                if (result.extraInfo != null)
                  _buildInfoRow("Ghi chú", result.extraInfo!, isSuccess: result.resultType == CheckinResultType.success),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  "Lý do: ${result.message}",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(checkinProvider.notifier).reset();
                    _isScanning = false; // Allow scanning again after confirm
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: resultColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "XÁC NHẬN",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool? isSuccess}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isSuccess == null 
                  ? Colors.white 
                  : (isSuccess ? AppColors.success : AppColors.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã hội viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CheckinHistoryScreen(gymId: widget.gymId)),
            ),
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flash_on, color: Colors.yellow),
            onPressed: () => cameraController.toggleTorch(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final user = ref.watch(authProvider).user;
                  
                  return UserAvatar(
                    name: user?.name ?? 'Đối tác',
                    radius: 16,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleBarcode,
          ),
          
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accentCyan, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          
          if (state.isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accentBlue),
              ),
            ),
            
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Căn chỉnh mã QR vào trong khung',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
