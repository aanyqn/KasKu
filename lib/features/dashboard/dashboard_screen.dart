import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import 'widgets/balance_card.dart';
import 'widgets/spending_chart.dart';
import '../shell/app_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final balanceAsync = ref.watch(netBalanceProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider(selectedMonth));
    final spendingAsync = ref.watch(categorySpendingProvider(selectedMonth));
    final recentAsync = ref.watch(
      transactionListProvider(const TransactionFilter()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasku'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _MonthSelector(
              selected: selectedMonth,
              onChanged: (m) =>
                  ref.read(selectedMonthProvider.notifier).state = m,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.emerald,
        onRefresh: () async {
          ref.invalidate(netBalanceProvider);
          ref.invalidate(monthlySummaryProvider);
          ref.invalidate(categorySpendingProvider);
          ref.invalidate(transactionListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Balance Card ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: summaryAsync.when(
                  data: (summary) => balanceAsync.when(
                    data: (balance) => BalanceCard(
                      balance: balance,
                      income: summary.totalIncome,
                      expense: summary.totalExpense,
                    ),
                    loading: () => const BalanceCard(
                      balance: 0,
                      income: 0,
                      expense: 0,
                      isLoading: true,
                    ),
                    error: (_, _) => const SizedBox(),
                  ),
                  loading: () => const BalanceCard(
                    balance: 0,
                    income: 0,
                    expense: 0,
                    isLoading: true,
                  ),
                  error: (_, _) => const SizedBox(),
                ),
              ),
            ),

            // ── Spending Chart ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengeluaran ${DateFormatter.monthYear(selectedMonth)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 0.5,
                        ),
                      ),
                      child: spendingAsync.when(
                        data: (spending) =>
                            SpendingChart(categorySpending: spending),
                        loading: () => const SizedBox(
                          height: 140,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.emerald,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        error: (_, _) => const SizedBox(height: 100),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Recent Transactions ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Terbaru',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(shellIndexProvider.notifier).state = 1;
                      },
                      child: Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            recentAsync.when(
              data: (transactions) {
                final recent = transactions.take(5).toList();
                if (recent.isEmpty) {
                  return SliverToBoxAdapter(child: _emptyTransactions(context));
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _TransactionTileCompact(
                          transaction: recent[i]),
                      childCount: recent.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: AppColors.emerald,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox()),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _emptyTransactions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada transaksi',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tekan tombol + untuk mencatat',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Month Selector ────────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  const _MonthSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMonthPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.emerald.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormatter.monthYear(selected),
              style: TextStyle(
                color: AppColors.emerald,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.emerald),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      builder: (_) => _MonthPickerSheet(
        selected: selected,
        onChanged: onChanged,
        referenceDate: now,
      ),
    );
  }
}

class _MonthPickerSheet extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  final DateTime referenceDate;

  const _MonthPickerSheet({
    required this.selected,
    required this.onChanged,
    required this.referenceDate,
  });

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) {
      return DateTime(referenceDate.year, referenceDate.month - i);
    });

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pilih Bulan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...months.map((m) {
            final isSelected =
                m.year == selected.year && m.month == selected.month;
            return ListTile(
              title: Text(DateFormatter.monthYear(m)),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded, color: AppColors.emerald)
                  : null,
              titleTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isSelected ? AppColors.emerald : null,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
              onTap: () {
                onChanged(m);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Compact transaction tile (used in dashboard) ──────────────────────────────

class _TransactionTileCompact extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTileCompact({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.income : AppColors.expense)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                transaction.categoryIcon,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Category & note
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.categoryName,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (transaction.note?.isNotEmpty == true)
                  Text(
                    transaction.note!,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Amount & date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                style: TextStyle(
                  color: isIncome ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                DateFormatter.dayMonth(transaction.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
