import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    try {
      String host = '127.0.0.1';
      if (!kIsWeb && Platform.isAndroid) {
        host = '10.0.2.2';
      }
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      print('Connected to Firebase Emulators on $host');
    } catch (e) {
      print('Failed to connect to emulators: $e');
    }
  }

  runApp(const ProviderScope(child: VpassApp()));
}
