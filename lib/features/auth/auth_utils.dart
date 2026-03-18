import 'package:firebase_auth/firebase_auth.dart';

class AuthUtils {
  static String cleanErrorMessage(dynamic e) {
    String message;
    
    if (e is FirebaseAuthException) {
      message = e.message ?? e.code;
    } else if (e is FirebaseException) {
      message = e.message ?? e.code;
    } else {
      message = e.toString();
    }

    // List of noise sentences to remove
    final noise = [
      'Running in emulator mode. Do not use with production credentials.',
      'firebase_auth/',
      '[firebase_auth/',
      'cloud_firestore/',
      '[cloud_firestore/',
      ']',
    ];

    for (var n in noise) {
      message = message.replaceAll(n, '');
    }

    // Clean up brackets or prefixes if they remain (e.g. "[error-code]")
    message = message.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    
    if (message.isEmpty) return 'An unexpected error occurred. Please try again.';
    
    return message;
  }

  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email cannot be empty';
    final emailRegex = RegExp(r'^[\w\.\+\-]+@([\w\-]+\.)+[a-z]{2,}$');
    if (!emailRegex.hasMatch(email)) return 'Invalid email address';
    return null;
  }

  static String? validatePhone(String phone) {
    if (phone.isEmpty) return 'Phone cannot be empty';
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'Invalid Vietnamese phone number (e.g. 0901234567)';
    }
    return null;
  }

  static String? validatePassword(String pass) {
    if (pass.isEmpty) return 'Password cannot be empty';
    if (pass.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
