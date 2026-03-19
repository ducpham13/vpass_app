import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import 'card_repository.dart';
import '../../models/card_model.dart';

final cardRepositoryProvider = Provider((ref) => CardRepository());

final cardProvider = StreamProvider<List<CardModel>>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;

  if (user == null) {
    return Stream.value([]);
  }

  return ref.read(cardRepositoryProvider).getUserCards(user.uid);
});

final cardDetailProvider = StreamProvider.family<CardModel?, String>((ref, cardId) {
  return ref.read(cardRepositoryProvider).getCardStream(cardId);
});
