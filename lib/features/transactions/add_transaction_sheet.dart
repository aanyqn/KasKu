import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';

/// Shows the Add/Edit transaction bottom sheet
void showAddTransactionSheet(
  BuildContext context,
  WidgetRef ref, {
  Transaction? existing,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: AddTransactionSheet(existing: existing),
    ),
  );
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  final Transaction? existing;
  const AddTransactionSheet({super.key, this.existing});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  late TransactionType _type;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _date;
  Category? _selectedCategory;
  bool _isSaving = false;

  late AnimationController _saveAnimController;
  late Animation<double> _saveScaleAnim;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _type = t?.type ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: t != null ? t.amount.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: t?.note ?? '');
    _date = t?.date ?? DateTime.now();

    _saveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _saveScaleAnim = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _saveAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _saveAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(_type));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          _buildHandle(context),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.existing != null
                            ? 'Edit Transaksi'
                            : 'Catat Transaksi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkElevated
                              : const Color(0xFFF1F5F9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Type toggle
                  _TypeToggle(
                    selected: _type,
                    onChanged: (t) {
                      setState(() {
                        _type = t;
                        _selectedCategory = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Amount field
                  _buildAmountField(context),
                  const SizedBox(height: 20),

                  // Category picker
                  Text(
                    'Kategori',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  categoriesAsync.when(
                    data: (cats) => _CategoryGrid(
                      categories: cats,
                      selected: _selectedCategory,
                      onSelected: (c) =>
                          setState(() => _selectedCategory = c),
                    ),
                    loading: () => const SizedBox(
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.emerald, strokeWidth: 2),
                      ),
                    ),
                    error: (_, _) => const SizedBox(),
                  ),
                  const SizedBox(height: 20),

                  // Date picker
                  _buildDatePicker(context),
                  const SizedBox(height: 16),

                  // Note field
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Catatan (opsional)',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  _buildSaveButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nominal', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: _type == TransactionType.income
                    ? AppColors.income
                    : AppColors.expense,
              ),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            hintText: '0',
          ),
          autofocus: widget.existing == null,
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18,
                color: AppColors.emerald),
            const SizedBox(width: 12),
            Text(
              DateFormatter.full(_date),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ScaleTransition(
      scale: _saveScaleAnim,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Simpan'),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.emerald),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang valid')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    _saveAnimController.forward().then((_) => _saveAnimController.reverse());
    setState(() => _isSaving = true);

    final transaction = widget.existing ?? Transaction();
    transaction
      ..amount = double.parse(amountText)
      ..type = _type
      ..categoryName = _selectedCategory!.name
      ..categoryIcon = _selectedCategory!.icon
      ..date = _date
      ..note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

    final notifier = ref.read(
      transactionListProvider(const TransactionFilter()).notifier,
    );

    if (widget.existing != null) {
      await notifier.edit(transaction);
    } else {
      await notifier.add(transaction);
    }

    HapticFeedback.mediumImpact();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existing != null
              ? 'Transaksi diperbarui!'
              : 'Transaksi berhasil disimpan!'),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// ── Type Toggle ───────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Pengeluaran',
            icon: Icons.arrow_upward_rounded,
            type: TransactionType.expense,
            selected: selected,
            color: AppColors.expense,
            onTap: () => onChanged(TransactionType.expense),
          ),
          _ToggleOption(
            label: 'Pemasukan',
            icon: Icons.arrow_downward_rounded,
            type: TransactionType.income,
            selected: selected,
            color: AppColors.income,
            onTap: () => onChanged(TransactionType.income),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final TransactionType type;
  final TransactionType selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.type,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = type == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Grid ─────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onSelected;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = selected?.id == cat.id;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.emerald.withValues(alpha: 0.15)
                  : isDark
                      ? AppColors.darkElevated
                      : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.emerald
                    : isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cat.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? AppColors.emerald
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
