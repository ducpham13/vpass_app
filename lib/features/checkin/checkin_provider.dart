import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'checkin_repository.dart';

final checkinRepositoryProvider = Provider((ref) => CheckinRepository());

class CheckinState {
  final bool isProcessing;
  final CheckinResult? lastResult;

  CheckinState({this.isProcessing = false, this.lastResult});

  CheckinState copyWith({bool? isProcessing, CheckinResult? lastResult}) {
    return CheckinState(
      isProcessing: isProcessing ?? this.isProcessing,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

final checkinProvider = NotifierProvider<CheckinNotifier, CheckinState>(CheckinNotifier.new);

class CheckinNotifier extends Notifier<CheckinState> {
  DateTime? _lastScanTime;

  @override
  CheckinState build() => CheckinState();

  Future<CheckinResult> scanCard(String cardId, String gymId) async {
    // Debounce: reject scans within 5 seconds of last scan
    final now = DateTime.now();
    if (_lastScanTime != null && now.difference(_lastScanTime!).inSeconds < 5) {
      return CheckinResult(
        resultType: CheckinResultType.fail,
        message: "Vui lòng chờ vài giây trước khi quét lại.",
      );
    }
    _lastScanTime = now;

    state = state.copyWith(isProcessing: true);
    
    final result = await ref.read(checkinRepositoryProvider).processCheckIn(
      cardId, 
      gymId,
    );
    
    state = state.copyWith(isProcessing: false, lastResult: result);
    return result;
  }
  
  void reset() {
    _lastScanTime = null;
    state = CheckinState();
  }
}

final checkinHistoryProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, gymId) {
  return ref.read(checkinRepositoryProvider).getCheckinHistory(gymId);
});
