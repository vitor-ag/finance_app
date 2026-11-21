import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/accounts/presentation/screens/accounts_screen.dart';
import 'features/bills/presentation/providers/bill_providers.dart';
import 'features/bills/presentation/screens/bills_screen.dart';
import 'features/categories/presentation/screens/categories_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/recurrences/presentation/providers/recurrence_providers.dart';
import 'features/recurrences/presentation/screens/recurrences_screen.dart';
import 'features/transactions/presentation/screens/transactions_screen.dart';
import 'features/transactions/presentation/widgets/transaction_form.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _syncSchedules);
    Future.microtask(_syncSchedules);
  }

  Future<void> _syncSchedules() async {
    if (!mounted) return;
    try {
      await Future.wait([
        ref.read(recurrenceRepositoryProvider).generateDueOccurrences(),
        ref.read(billRepositoryProvider).generateDueBills(),
      ]);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          context: ErrorDescription(
            'atualizando lançamentos e contas recorrentes',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;
  static const _quickActionIndex = 2;

  void _openPage(Widget page) {
    Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_index) {
        0 => DashboardScreen(onOpenBills: () => _openPage(const BillsScreen())),
        1 => const TransactionsScreen(),
        3 => const AccountsScreen(),
        _ => _MoreScreen(onOpenPage: _openPage),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          if (index == _quickActionIndex) {
            showTransactionForm(context);
          } else {
            setState(() => _index = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert),
            selectedIcon: Icon(Icons.swap_vert),
            label: 'Lançamentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle, size: 32),
            label: 'Novo',
            tooltip: 'Novo lançamento',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Contas',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen({required this.onOpenPage});

  final ValueChanged<Widget> onOpenPage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Contas a pagar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenPage(const BillsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.autorenew),
            title: const Text('Recorrências'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenPage(const RecurrencesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categorias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenPage(const CategoriesScreen()),
          ),
        ],
      ),
    );
  }
}
