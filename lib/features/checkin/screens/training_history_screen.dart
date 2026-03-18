import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/glass_container.dart';
import '../history_provider.dart';

class TrainingHistoryScreen extends ConsumerWidget {
  const TrainingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hState = ref.watch(historyStateProvider);
    final history = ref.watch(pagedHistoryProvider);
    final totalSessions = ref.watch(monthTotalSessionsProvider);
    final monthStr = DateFormat('M / yyyy').format(hState.selectedMonth);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundPrimary,
              AppColors.backgroundPrimary.withOpacity(0.8),
              AppColors.backgroundPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'LỊCH SỬ TẬP',
                      style: AppTextStyles.displayMedium.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Month Selector
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => ref
                            .read(historyStateProvider.notifier)
                            .changeMonth(-1),
                      ),
                      Text(
                        'Tháng $monthStr'.toUpperCase(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => ref
                            .read(historyStateProvider.notifier)
                            .changeMonth(1),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TỔNG BUỔI THÁNG NÀY',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$totalSessions',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.accentBlue,
                          fontSize: 45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Filters
              _buildFilters(ref, hState.filter),

              const SizedBox(height: AppSpacing.md),

              // List
              Expanded(
                child: history.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: history.length + 1,
                        itemBuilder: (context, index) {
                          if (index == history.length) {
                            return _buildPagination(ref);
                          }
                          return _buildHistoryItem(history[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(WidgetRef ref) {
    final hState = ref.watch(historyStateProvider);
    final totalPages = ref.watch(totalPagesProvider);

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: hState.currentPage > 0
                ? () => ref
                      .read(historyStateProvider.notifier)
                      .setPage(hState.currentPage - 1)
                : null,
            color: hState.currentPage > 0
                ? AppColors.accentBlue
                : AppColors.textMuted,
          ),
          const SizedBox(width: 16),
          Text(
            'Trang ${hState.currentPage + 1} / $totalPages',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: hState.currentPage < totalPages - 1
                ? () => ref
                      .read(historyStateProvider.notifier)
                      .setPage(hState.currentPage + 1)
                : null,
            color: hState.currentPage < totalPages - 1
                ? AppColors.accentBlue
                : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(WidgetRef ref, HistoryFilter currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _filterChip(ref, 'Tất cả', HistoryFilter.all, currentFilter),
          const SizedBox(width: AppSpacing.md),
          _filterChip(ref, 'Thẻ thường', HistoryFilter.regular, currentFilter),
          const SizedBox(width: AppSpacing.md),
          _filterChip(ref, 'Thẻ VIP', HistoryFilter.vip, currentFilter),
        ],
      ),
    );
  }

  Widget _filterChip(
    WidgetRef ref,
    String label,
    HistoryFilter filter,
    HistoryFilter currentFilter,
  ) {
    final isSelected = filter == currentFilter;
    return GestureDetector(
      onTap: () => ref.read(historyStateProvider.notifier).setFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentBlue.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.accentBlue
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> log) {
    final timestamp = (log['timestamp'] as Timestamp).toDate();
    final timeStr = DateFormat('HH:mm').format(timestamp);
    final dateStr = DateFormat('dd/MM/yyyy').format(timestamp);
    final isVip = log['cardType'] == 'membership';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['gymName'] ?? 'Vpass Gym',
                  style: AppTextStyles.displaySmall.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cầu Giấy, Hà Nội', // TODO: Get real address from gym model if needed
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                dateStr,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isVip ? AppColors.accentCyan : AppColors.accentBlue)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isVip ? 'VIP' : 'Thường',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isVip ? AppColors.accentCyan : AppColors.accentBlue,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            color: AppColors.textMuted.withOpacity(0.2),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có dữ liệu check-in',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
