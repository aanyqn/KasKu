import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../providers/isar_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../categories/category_list_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── App info ──────────────────────────────────────────────────────
          _AppInfoCard(),
          const SizedBox(height: 20),

          // ── Data section ──────────────────────────────────────────────────
          _SectionLabel(label: 'Data & Kategori'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.category_outlined,
            iconColor: AppColors.teal,
            title: 'Kelola Kategori',
            subtitle: 'Tambah, edit, atau hapus kategori',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CategoryListScreen()),
            ),
          ),

          const SizedBox(height: 16),

          // ── Backup section ────────────────────────────────────────────────
          _SectionLabel(label: 'Backup & Restore'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.upload_rounded,
            iconColor: AppColors.emerald,
            title: 'Export Data (Backup)',
            subtitle: 'Simpan data ke file JSON',
            onTap: () => _exportData(context, ref),
          ),

          _SettingsTile(
            icon: Icons.download_rounded,
            iconColor: AppColors.teal,
            title: 'Import Data (Restore)',
            subtitle: 'Pulihkan data dari file JSON',
            onTap: () => _importData(context, ref),
          ),

          const SizedBox(height: 16),

          // ── Danger section ────────────────────────────────────────────────
          _SectionLabel(label: 'Zona Bahaya'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: AppColors.expense,
            title: 'Hapus Semua Data',
            subtitle: 'Hapus seluruh transaksi (tidak bisa dibatalkan)',
            onTap: () => _confirmClearAll(context, ref),
            titleColor: AppColors.expense,
          ),
        ],
      ),
    );
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final isar = await ref.read(isarProvider.future);
      final txRepo = TransactionRepository(isar);
      final catRepo = CategoryRepository(isar);

      final transactions = await txRepo.getAll();
      final categories = await catRepo.getAll();

      final data = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'transactions': transactions
            .map((t) => {
                  'id': t.id,
                  'amount': t.amount,
                  'type': t.type.name,
                  'categoryName': t.categoryName,
                  'categoryIcon': t.categoryIcon,
                  'date': t.date.toIso8601String(),
                  'note': t.note,
                })
            .toList(),
        'categories': categories
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'icon': c.icon,
                  'isDefault': c.isDefault,
                  'type': c.type.name,
                })
            .toList(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${dir.path}/kasku_backup_$dateStr.json');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Kasku Backup $dateStr',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export gagal: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.first.path;
      if (path == null) return;

      final file = File(path);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validate schema
      if (!data.containsKey('transactions') ||
          !data.containsKey('categories')) {
        throw FormatException('Format file tidak valid');
      }

      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Data?'),
          content: Text(
            'Data yang ada akan ditimpa dengan ${(data['transactions'] as List).length} transaksi '
            'dan ${(data['categories'] as List).length} kategori dari file backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final isar = await ref.read(isarProvider.future);
      final txRepo = TransactionRepository(isar);
      final catRepo = CategoryRepository(isar);

      // Clear existing
      await txRepo.clearAll();
      await catRepo.clearCustom();

      // Import transactions
      final txList = (data['transactions'] as List).map((json) {
        final t = Transaction()
          ..amount = (json['amount'] as num).toDouble()
          ..type = TransactionType.values.byName(json['type'] as String)
          ..categoryName = json['categoryName'] as String
          ..categoryIcon = json['categoryIcon'] as String? ?? '📦'
          ..date = DateTime.parse(json['date'] as String)
          ..note = json['note'] as String?;
        return t;
      }).toList();
      await txRepo.importAll(txList);

      // Import categories (only custom ones)
      final catList = (data['categories'] as List)
          .where((json) => !(json['isDefault'] as bool))
          .map((json) {
        final c = Category()
          ..name = json['name'] as String
          ..icon = json['icon'] as String
          ..isDefault = false
          ..type = TransactionType.values.byName(json['type'] as String);
        return c;
      }).toList();
      await catRepo.importAll(catList);

      // Invalidate all providers
      ref.invalidate(transactionListProvider);
      ref.invalidate(netBalanceProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(categorySpendingProvider);
      ref.invalidate(categoryProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Import berhasil! ${txList.length} transaksi dipulihkan.'),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import gagal: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  // ── Clear all ─────────────────────────────────────────────────────────────

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text(
          'Seluruh transaksi akan dihapus secara permanen. '
          'Pastikan sudah backup terlebih dahulu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final isar = await ref.read(isarProvider.future);
      await TransactionRepository(isar).clearAll();
      ref.invalidate(transactionListProvider);
      ref.invalidate(netBalanceProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(categorySpendingProvider);
    }
  }
}

// ── App info card ─────────────────────────────────────────────────────────────

class _AppInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('💰', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kasku',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Versi 1.0.0 · Data tersimpan lokal',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
        ),
        subtitle: Text(subtitle,
            style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
