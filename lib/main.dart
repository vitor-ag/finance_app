import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/accounts/presentation/screens/accounts_screen.dart';
import 'features/bills/presentation/screens/bills_screen.dart';
import 'features/categories/presentation/screens/categories_screen.dart';
import 'features/recurrences/presentation/providers/recurrence_providers.dart';
import 'features/recurrences/presentation/screens/recurrences_screen.dart';
import 'features/transactions/presentation/screens/transactions_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Catch up on any recurrence occurrence due since the app was last opened.
    Future.microtask(
      () => ref.read(recurrenceRepositoryProvider).generateDueOccurrences(),
    );
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

  static const _screens = [
    AccountsScreen(),
    TransactionsScreen(),
    BillsScreen(),
    RecurrencesScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Contas',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert),
            selectedIcon: Icon(Icons.swap_vert),
            label: 'Lançamentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'A Pagar',
          ),
          NavigationDestination(
            icon: Icon(Icons.autorenew),
            selectedIcon: Icon(Icons.autorenew),
            label: 'Recorrências',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorias',
          ),
        ],
      ),
    );
  }
}