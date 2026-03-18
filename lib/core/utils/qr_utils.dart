import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';

class QrUtils {
  static String generatePayload({
    required String cardId,
    required String userId,
    required String gymId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = _randomString(4);

    final dataString = '$cardId$userId$timestamp$nonce';
    final bytes = utf8.encode(dataString);
    final hmacSha256 = Hmac(sha256, utf8.encode(AppConstants.qrSecret));
    final fullDigest = hmacSha256.convert(bytes).toString();
    final sig = fullDigest.substring(0, 16);

    return '$cardId|$userId|$gymId|$timestamp|$nonce|$sig';
  }

  static String _randomString(int length) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final rnd = DateTime.now().microsecondsSinceEpoch % 1000000;
    // Simple deterministic-ish random for the nonce
    return List.generate(length, (i) => chars[(rnd + i) % chars.length]).join();
  }

  static Map<String, dynamic>? decodeAndVerify(String compactPayload) {
    try {
      // New compact format: cardId|userId|gymId|timestamp|nonce|sig
      final parts = compactPayload.split('|');
      if (parts.length != 6) {
        return null;
      }

      final cardId = parts[0];
      final userId = parts[1];
      final gymId = parts[2];
      final timestampStr = parts[3];
      final nonce = parts[4];
      final sig = parts[5];

      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) return null;

      // Verify HMAC (truncated to 16 chars)
      final dataString = '$cardId$userId$timestamp$nonce';
      final bytes = utf8.encode(dataString);
      final hmacSha256 = Hmac(sha256, utf8.encode(AppConstants.qrSecret));
      final fullDigest = hmacSha256.convert(bytes).toString();
      final truncatedDigest = fullDigest.substring(0, 16);

      if (truncatedDigest != sig) {
        return null; // Invalid signature
      }

      // Check expiration with generous allowance for clock drift
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = (now - timestamp).abs();
      
      if (diff > AppConstants.qrValidDurationMs) {
        return null; 
      }

      return {
        'cardId': cardId,
        'userId': userId,
        'gymId': gymId,
        'timestamp': timestamp,
        'nonce': nonce,
        'sig': sig,
      };
    } catch (e) {
      return null;
    }
  }
}
