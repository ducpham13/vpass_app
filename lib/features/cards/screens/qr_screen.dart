import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../models/card_model.dart';
import '../../auth/auth_provider.dart';
import '../../cards/card_provider.dart';
import 'dart:async';
import '../../../core/utils/qr_utils.dart';

class QrScreen extends ConsumerStatefulWidget {
  final CardModel card;
  final String gymId; // For membership card choosing a gym

  const QrScreen({super.key, required this.card, required this.gymId});

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  late Timer _timer;
  int _secondsLeft = 60;
  String _qrPayload = '';
  StreamSubscription? _checkinSubscription;
  bool _notificationShown = false;

  @override
  void initState() {
    super.initState();
    _generatePayload();
    _startTimer();
    _listenForCheckin();
  }

  void _listenForCheckin() {
    _subscribeToCurrentNonce();
  }

  /// Extract the unique nonce ID from the current QR payload
  String? _getCurrentNonceId() {
    if (_qrPayload.isEmpty) return null;
    try {
      final parts = _qrPayload.split('|');
      if (parts.length != 6) return null;
      // qrUniqueId = timestamp_nonce (matches what checkin_repository stores)
      return '${parts[3]}_${parts[4]}';
    } catch (_) {
      return null;
    }
  }

  /// Listen for the specific nonce document in used_qr_nonces
  void _subscribeToCurrentNonce() {
    _checkinSubscription?.cancel();
    _notificationShown = false;

    final nonceId = _getCurrentNonceId();
    if (nonceId == null) return;

    _checkinSubscription = FirebaseFirestore.instance
        .collection('used_qr_nonces')
        .doc(nonceId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && !_notificationShown) {
            setState(() {
              _notificationShown = true;
            });
            // Fetch the matching checkin for details
            _fetchCheckinAndShowSuccess(snapshot.data()?['cardId'] ?? '');
          }
        });
  }

  void _fetchCheckinAndShowSuccess(String cardId) async {
    // Get the latest checkin for this card to show details
    final userId = ref.read(authProvider).user?.uid;
    if (userId == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('cardId', isEqualTo: widget.card.id)
        .get();

    if (snap.docs.isNotEmpty) {
      // Find latest checkin client-side
      final docs = [...snap.docs];
      docs.sort((a, b) {
        final tsA = a.data()['timestamp'] as Timestamp?;
        final tsB = b.data()['timestamp'] as Timestamp?;
        if (tsA == null) return 1;
        if (tsB == null) return -1;
        return tsB.compareTo(tsA);
      });
      
      // Invalidate card provider so quota/usedValue refreshes immediately
      ref.invalidate(cardProvider);
      _showSuccessDialog(docs.first.data());
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    final timeStr = DateFormat(
      'HH:mm:ss - dd/MM/yyyy',
    ).format((data['timestamp'] as Timestamp).toDate());

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
                color: AppColors.success.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: AppColors.success.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Check-in thành công",
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow("Thành viên", data['userName'] ?? "Ẩn danh"),
              _buildInfoRow("Loại thẻ", data['cardType'] ?? "Hội viên"),
              _buildInfoRow("Phòng", data['gymName'] ?? "Vpass Gym"),
              _buildInfoRow("Thời gian", timeStr),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Exit QR screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "XÁC NHẬN",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _checkinSubscription?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _generatePayload();
        setState(() {
          _secondsLeft = 60;
        });
      }
    });
  }

  void _generatePayload() {
    final userId = ref.read(authProvider).user?.uid ?? 'unknown_user';

    setState(() {
      _qrPayload = QrUtils.generatePayload(
        cardId: widget.card.id,
        userId: userId,
        gymId: widget.gymId,
      );
    });

    // Re-subscribe listener to track this new QR's nonce
    _subscribeToCurrentNonce();
  }

  @override
  Widget build(BuildContext context) {
    final presetColors = AppColors
        .cardGradients[widget.card.colorIndex % AppColors.cardGradients.length];

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in QR')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: presetColors[0].withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: QrImageView(
                data: _qrPayload,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.L, // Reduced density
                size: 250.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _secondsLeft / 60,
                    backgroundColor: Colors.white12,
                    color: presetColors[1],
                    strokeWidth: 6,
                  ),
                ),
                Text('$_secondsLeft', style: AppTextStyles.displayMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Mã sẽ tự động đổi sau $_secondsLeft giây',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Vui lòng xuất trình mã này\ntại quầy lễ tân',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
