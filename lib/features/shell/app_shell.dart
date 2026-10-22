import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/transaction_list_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import '../../core/theme/app_colors.dart';

final shellIndexProvider = StateProvider<int>((_) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static final _screens = const [
    DashboardScreen(),
    TransactionListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add',
        onPressed: () => showAddTransactionSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat'),
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(shellIndexProvider.notifier).state = i,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
