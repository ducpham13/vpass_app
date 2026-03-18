import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/card_model.dart';
import '../../models/user_model.dart';
import '../../core/utils/qr_utils.dart';

/// Result type for 3-color display on scanner
enum CheckinResultType {
  success,         // 🟢 GREEN — Check-in thành công
  alreadyToday,    // 🟡 YELLOW — Cho vào, không tính buổi (thẻ thường)
  fail,            // 🔴 RED — Từ chối
}

class CheckinResult {
  final CheckinResultType resultType;
  final bool success; // true for GREEN and YELLOW
  final String message;
  final String? userName;
  final String? cardType;
  final String? gymName;
  final DateTime? timestamp;
  final String? extraInfo; // "Lần X hôm nay" or "Còn ~Y buổi"

  CheckinResult({
    required this.resultType,
    required this.message,
    this.userName,
    this.cardType,
    this.gymName,
    this.timestamp,
    this.extraInfo,
  }) : success = resultType != CheckinResultType.fail;
}

class CheckinRepository {
  final FirebaseFirestore _firestore;

  CheckinRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getCheckinHistory(String gymId) {
    return _firestore
        .collection('checkins')
        .where('gymId', isEqualTo: gymId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getUserCheckinHistory(String userId) {
    return _firestore
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<CheckinResult> processCheckIn(String qrData, String partnerGymId) async {
    try {
      // ══════════════════════════════════════════
      // BƯỚC 1 — Verify QR (1-4)
      // ══════════════════════════════════════════

      // 1. HMAC signature
      final payload = QrUtils.decodeAndVerify(qrData);
      if (payload == null) {
        return CheckinResult(
          resultType: CheckinResultType.fail,
          message: "QR không hợp lệ hoặc sai chữ ký số",
        );
      }

      // 2. timestamp < 60s (already checked inside decodeAndVerify via qrValidDurationMs)
      // If we get here, timestamp is valid.

      final String cardId = payload['cardId'];
      final String qrGymId = payload['gymId'];
      final String nonce = payload['nonce'];
      final int qrTimestamp = payload['timestamp'];
      final String qrUniqueId = '${qrTimestamp}_$nonce';

      // 3. Nonce chưa dùng
      final nonceDoc = await _firestore.collection('used_qr_nonces').doc(qrUniqueId).get();
      if (nonceDoc.exists) {
        return CheckinResult(
          resultType: CheckinResultType.fail,
          message: "QR đã được sử dụng. Vui lòng tạo mã mới.",
        );
      }

      // 4. gymId trong QR == gymId staff
      if (qrGymId != partnerGymId) {
        return CheckinResult(
          resultType: CheckinResultType.fail,
          message: "QR không đúng phòng này. Khách cần tạo mã mới tại đây.",
        );
      }

      // ══════════════════════════════════════════
      // BƯỚC 2-4: Card verify + Logic → Atomic Transaction
      // ══════════════════════════════════════════

      return await _firestore.runTransaction((transaction) async {
        final cardDoc = await _firestore.collection('cards').doc(cardId).get();
        if (!cardDoc.exists) {
          return CheckinResult(
            resultType: CheckinResultType.fail,
            message: "Không tìm thấy thông tin thẻ",
          );
        }

        final card = CardModel.fromMap(cardId, cardDoc.data()!);

        // ─── BƯỚC 2: Verify thẻ (5-6) ───

        // 5. card.status == "active"
        if (card.status != 'active') {
          return CheckinResult(
            resultType: CheckinResultType.fail,
            message: "Thẻ không còn hiệu lực",
          );
        }

        // 6. now < card.endDate
        if (DateTime.now().isAfter(card.endDate)) {
          return CheckinResult(
            resultType: CheckinResultType.fail,
            message: "Thẻ đã hết hạn",
          );
        }

        // Fetch user & gym info
        final userDoc = await _firestore.collection('users').doc(card.userId).get();
        final userName = userDoc.exists
            ? UserModel.fromMap(card.userId, userDoc.data()!).name
            : "Hội viên ẩn danh";

        final gymDoc = await _firestore.collection('gyms').doc(partnerGymId).get();
        final gymName = gymDoc.exists
            ? (gymDoc.data()?['info']?['name'] ?? "Phòng tập Vpass")
            : "Phòng tập Vpass";
        final nowTime = DateTime.now();
        final todayStr = DateFormat('yyyy-MM-dd').format(nowTime);

        // ─── BƯỚC 3: Logic riêng từng loại thẻ (7-8) ───

        final bool isRegularCard = card.gymId != null; // Thẻ thường
        final bool isVipCard = card.gymId == null;     // Thẻ VIP

        if (isRegularCard) {
          // ═══ THẺ THƯỜNG ═══

          // 7. card.gymId == gymId staff
          if (card.gymId != partnerGymId) {
            return CheckinResult(
              resultType: CheckinResultType.fail,
              message: "Thẻ không đúng phòng",
            );
          }

          // 8. Đã có session hôm nay?
          final todaySessions = await _firestore
              .collection('sessions')
              .where('cardId', isEqualTo: cardId)
              .where('date', isEqualTo: todayStr)
              .get();

          if (todaySessions.docs.isNotEmpty) {
            // CÓ → Cho vào, KHÔNG ghi session mới

            // Mark QR as used (still prevent replay)
            transaction.set(
              _firestore.collection('used_qr_nonces').doc(qrUniqueId),
              {'usedAt': FieldValue.serverTimestamp(), 'cardId': cardId},
            );

            return CheckinResult(
              resultType: CheckinResultType.alreadyToday,
              message: "Đã check-in hôm nay",
              userName: userName,
              cardType: 'Thẻ thường',
              gymName: gymName,
              timestamp: nowTime,
              extraInfo: "Thẻ được chấp nhận trong hôm nay",
            );
          }

          // KHÔNG → Ghi session, valueCharged = 0

          // Mark QR as used
          transaction.set(
            _firestore.collection('used_qr_nonces').doc(qrUniqueId),
            {'usedAt': FieldValue.serverTimestamp(), 'cardId': cardId},
          );

          // Ghi session
          final sessionRef = _firestore.collection('sessions').doc();
          transaction.set(sessionRef, {
            'cardId': cardId,
            'userId': card.userId,
            'gymId': partnerGymId,
            'date': todayStr,
            'timestamp': FieldValue.serverTimestamp(),
            'valueCharged': 0,
            'checkedInBy': partnerGymId,
          });

          // Ghi checkin log
          final checkinRef = _firestore.collection('checkins').doc();
          transaction.set(checkinRef, {
            'cardId': cardId,
            'userId': card.userId,
            'userName': userName,
            'gymId': partnerGymId,
            'gymName': gymName,
            'timestamp': FieldValue.serverTimestamp(),
            'cardType': 'single',
            'qrNonce': qrUniqueId,
          });

          return CheckinResult(
            resultType: CheckinResultType.success,
            message: "Check-in thành công",
            userName: userName,
            cardType: 'Thẻ thường',
            gymName: gymName,
            timestamp: nowTime,
            extraInfo: "Lần 1 hôm nay",
          );

        } else if (isVipCard) {
          // ═══ THẺ VIP ═══

          final gymMonthlyPrice = (gymDoc.data()?['pricing']?['pricePerMonth'] ?? 0).toDouble();
          final sessionPrice = gymMonthlyPrice / 30;
          final vipLimit = (card.membershipPrice ?? 0) * 0.95;

          // 7. usedValue + sessionPrice > vipPrice × 0.95
          if (card.usedValue + sessionPrice > vipLimit) {
            return CheckinResult(
              resultType: CheckinResultType.fail,
              message: "Đã hết hạn mức tháng này",
            );
          }

          // 8. Ghi session (atomic)
          final newUsedValue = card.usedValue + sessionPrice;
          final isNowExpired = newUsedValue >= vipLimit;

          // Update card usedValue
          transaction.update(cardDoc.reference, {
            'usedValue': newUsedValue,
            if (isNowExpired) 'status': 'expired',
          });

          // Mark QR as used
          transaction.set(
            _firestore.collection('used_qr_nonces').doc(qrUniqueId),
            {'usedAt': FieldValue.serverTimestamp(), 'cardId': cardId},
          );

          // Create session
          final sessionRef = _firestore.collection('sessions').doc();
          transaction.set(sessionRef, {
            'cardId': cardId,
            'userId': card.userId,
            'gymId': partnerGymId,
            'date': todayStr,
            'timestamp': FieldValue.serverTimestamp(),
            'valueCharged': sessionPrice,
            'checkedInBy': partnerGymId,
          });

          // Revenue log for partner (100% sessionPrice for VIP global)
          final revenueLogRef = _firestore.collection('revenue_logs').doc();
          transaction.set(revenueLogRef, {
            'partnerUid': gymDoc.data()?['owner']?['uid'] ?? '',
            'gymId': partnerGymId,
            'gymName': gymName,
            'cardId': cardId,
            'buyerUid': card.userId,
            'partnerEarned': sessionPrice,
            'feeRate': 0.0,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'global_checkin',
          });

          // Checkin log
          final checkinRef = _firestore.collection('checkins').doc();
          transaction.set(checkinRef, {
            'cardId': cardId,
            'userId': card.userId,
            'userName': userName,
            'gymId': partnerGymId,
            'gymName': gymName,
            'timestamp': FieldValue.serverTimestamp(),
            'cardType': 'membership',
            'qrNonce': qrUniqueId,
          });

          // Quota Notifications (70% & 90%)
          final oldProgress = card.usedValue / vipLimit;
          final newProgress = newUsedValue / vipLimit;
          if ((oldProgress < 0.7 && newProgress >= 0.7) ||
              (oldProgress < 0.9 && newProgress >= 0.9)) {
            final notifyRef = _firestore.collection('notifications').doc();
            final percent = newProgress >= 0.9 ? 90 : 70;
            transaction.set(notifyRef, {
              'userId': card.userId,
              'title': 'Cảnh báo hạn mức thẻ',
              'body': 'Thẻ của bạn đã sử dụng hết $percent% hạn mức. Vui lòng lưu ý!',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
              'type': 'quota_alert',
            });
          }

          // Calculate remaining sessions for extraInfo
          final remainingValue = vipLimit - newUsedValue;
          final remainingSessions = sessionPrice > 0 && remainingValue >= sessionPrice
              ? (remainingValue / sessionPrice).floor()
              : 0;

          return CheckinResult(
            resultType: CheckinResultType.success,
            message: "Check-in thành công",
            userName: userName,
            cardType: 'VIP Global',
            gymName: gymName,
            timestamp: nowTime,
            extraInfo: "Còn ~$remainingSessions buổi tại phòng này",
          );
        }

        // Fallback (should not reach here)
        return CheckinResult(
          resultType: CheckinResultType.fail,
          message: "Loại thẻ không xác định",
        );
      });
    } catch (e) {
      return CheckinResult(
        resultType: CheckinResultType.fail,
        message: "Lỗi xử lý: $e",
      );
    }
  }
}
