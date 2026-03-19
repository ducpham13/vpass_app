
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  
  print('--- DIAGNOSING REVENUE LOGS ---');
  
  // 1. Get all gyms
  final gyms = await firestore.collection('gyms').get();
  print('Total Gyms: ${gyms.docs.length}');
  
  for (var gymDoc in gyms.docs) {
    print('Checking Gym: ${gymDoc.id} (${gymDoc.data()['info']?['name']})');
    
    // 2. Count logs
    final logs = await firestore.collection('revenue_logs')
        .where('gymId', isEqualTo: gymDoc.id)
        .get();
    
    print('  Revenue Logs found: ${logs.docs.length}');
    
    if (logs.docs.isNotEmpty) {
      final first = logs.docs.first.data();
      print('  Example Log Structure:');
      print('    partnerEarned: ${first['partnerEarned']} (Type: ${first['partnerEarned']?.runtimeType})');
      print('    gymId: ${first['gymId']}');
      print('    timestamp: ${first['timestamp']}');
    }
    
    // 3. Count withdrawals
    final withdrawals = await firestore.collection('withdrawals')
        .where('gymId', isEqualTo: gymDoc.id)
        .get();
    print('  Withdrawals found: ${withdrawals.docs.length}');
  }
  
  print('--- END DIAGNOSIS ---');
}
