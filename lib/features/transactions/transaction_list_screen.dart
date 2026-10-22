import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import 'add_transaction_sheet.dart';

// Filter state for the history screen
final _historyFilterProvider = StateProvider<TransactionType?>((ref) => null);
final _historyMonthProvider = StateProvider<DateTime?>((ref) => null);

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterType = ref.watch(_historyFilterProvider);
    final filterMonth = ref.watch(_historyMonthProvider);
    final now = DateTime.now();
    final effectiveMonth = filterMonth ?? DateTime(now.year, now.month);

    final filter = TransactionFilter(
      month: filterType == null ? null : effectiveMonth,
      type: filterType,
    );

    final transactionsAsync = ref.watch(transactionListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
      ),
      body: Column(
        children: [
          // ── Filter chips ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    selected: filterType == null,
                    onTap: () {
                      ref.read(_historyFilterProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '↑ Pemasukan',
                    selected: filterType == TransactionType.income,
                    color: AppColors.income,
                    onTap: () {
                      ref.read(_historyFilterProvider.notifier).state =
                          TransactionType.income;
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '↓ Pengeluaran',
                    selected: filterType == TransactionType.expense,
                    color: AppColors.expense,
                    onTap: () {
                      ref.read(_historyFilterProvider.notifier).state =
                          TransactionType.expense;
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Transactions list ─────────────────────────────────────────────
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return _EmptyState();
                }
                return _GroupedTransactionList(
                  transactions: transactions,
                  ref: ref,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.emerald,
                  strokeWidth: 2,
                ),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grouped by date list ──────────────────────────────────────────────────────

class _GroupedTransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final WidgetRef ref;

  const _GroupedTransactionList({
    required this.transactions,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // Group by date
    final Map<String, List<Transaction>> grouped = {};
    for (final t in transactions) {
      final key = DateFormatter.short(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        final group = grouped[key]!;
        final dailyTotal = group.fold(0.0, (sum, t) {
          return t.type == TransactionType.income
              ? sum + t.amount
              : sum - t.amount;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    key,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  Text(
                    CurrencyFormatter.formatSigned(dailyTotal),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dailyTotal >= 0
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
            // Tiles
            ...group.map((t) => TransactionTile(
                  transaction: t,
                  onTap: () => showAddTransactionSheet(
                      context, ref,
                      existing: t),
                  onDelete: () => _confirmDelete(context, ref, t),
                )),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Transaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          '${t.categoryIcon} ${t.categoryName} — ${CurrencyFormatter.format(t.amount)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref
          .read(transactionListProvider(const TransactionFilter()).notifier)
          .delete(t.id);
    }
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.expense.withValues(alpha: 0.3), width: 0.5),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.expense, size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    transaction.categoryIcon,
                    style: const TextStyle(fontSize: 20),
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

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                    style: TextStyle(
                      color: isIncome ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isIncome ? AppColors.income : AppColors.expense)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isIncome ? 'Masuk' : 'Keluar',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color = AppColors.emerald,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : isDark
                  ? AppColors.darkElevated
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color
                : isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? color
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada transaksi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Coba ubah filter atau tambah transaksi baru',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
