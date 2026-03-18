import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin/gym_repository.dart';
import '../../models/gym_model.dart';
import '../auth/auth_provider.dart';

final gymRepositoryProvider = Provider((ref) => GymRepository());

final gymsProvider = StreamProvider<List<GymModel>>((ref) {
  return ref.read(gymRepositoryProvider).getAvailableGyms();
});

final allGymsProvider = StreamProvider<List<GymModel>>((ref) {
  return ref.read(gymRepositoryProvider).getAllGyms();
});

final partnerGymsProvider = StreamProvider<List<GymModel>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value([]);
  return ref.read(gymRepositoryProvider).getPartnerGyms(user.uid);
});

final gymDetailProvider = StreamProvider.family<GymModel?, String>((ref, gymId) {
  return FirebaseFirestore.instance
      .collection('gyms')
      .doc(gymId)
      .snapshots()
      .map((doc) => doc.exists ? GymModel.fromMap(doc.id, doc.data()!) : null);
});
