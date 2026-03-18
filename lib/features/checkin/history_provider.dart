import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_provider.dart';
import 'checkin_provider.dart';

enum HistoryFilter { all, regular, vip }

class HistoryState {
  final DateTime selectedMonth;
  final HistoryFilter filter;
  final int currentPage;

  HistoryState({
    required this.selectedMonth,
    this.filter = HistoryFilter.all,
    this.currentPage = 0,
  });

  HistoryState copyWith({
    DateTime? selectedMonth,
    HistoryFilter? filter,
    int? currentPage,
  }) {
    return HistoryState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    return HistoryState(selectedMonth: DateTime.now());
  }

  void changeMonth(int offset) {
    state = state.copyWith(
      selectedMonth: DateTime(
        state.selectedMonth.year,
        state.selectedMonth.month + offset,
      ),
      currentPage: 0, // Reset page on month change
    );
  }

  void setFilter(HistoryFilter filter) {
    state = state.copyWith(
      filter: filter,
      currentPage: 0,
    ); // Reset page on filter change
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }
}

final historyStateProvider = NotifierProvider<HistoryNotifier, HistoryState>(
  HistoryNotifier.new,
);

final userHistoryProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value([]);
  return ref.read(checkinRepositoryProvider).getUserCheckinHistory(user.uid);
});

final filteredHistoryProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final historyAsync = ref.watch(userHistoryProvider);
  final hState = ref.watch(historyStateProvider);

  return historyAsync.when(
    data: (logs) {
      return logs.where((log) {
        final timestamp = (log['timestamp'] as Timestamp).toDate();
        final sameMonth =
            timestamp.year == hState.selectedMonth.year &&
            timestamp.month == hState.selectedMonth.month;

        if (!sameMonth) return false;

        if (hState.filter == HistoryFilter.regular) {
          return log['cardType'] == 'single';
        } else if (hState.filter == HistoryFilter.vip) {
          return log['cardType'] == 'membership';
        }

        return true;
      }).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

final monthTotalSessionsProvider = Provider<int>((ref) {
  final filtered = ref.watch(filteredHistoryProvider);
  return filtered.length;
});

final pagedHistoryProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final allFiltered = ref.watch(filteredHistoryProvider);
  final hState = ref.watch(historyStateProvider);

  const pageSize = 10;
  final start = hState.currentPage * pageSize;
  if (start >= allFiltered.length) return [];

  final end = (start + pageSize).clamp(0, allFiltered.length);
  return allFiltered.sublist(start, end);
});

final totalPagesProvider = Provider<int>((ref) {
  final totalSessions = ref.watch(monthTotalSessionsProvider);
  if (totalSessions == 0) return 0;
  return (totalSessions / 10).ceil();
});
