import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/local/database.dart';
import 'features/accounts/presentation/screens/accounts_screen.dart';
import 'features/backup/data/android_drive_backup.dart';
import 'features/backup/data/backup_snapshot.dart';
import 'features/backup/data/drive_sync.dart';
import 'features/bills/data/repositories/bill_repository_impl.dart';
import 'features/bills/presentation/providers/bill_providers.dart';
import 'features/bills/presentation/screens/bills_screen.dart';
import 'features/categories/presentation/screens/categories_screen.dart';
import 'features/credit_cards/presentation/credit_cards_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/goals/presentation/screens/goals_screen.dart';
import 'features/notifications/data/android_reminder_notifications.dart';
import 'features/notifications/data/reminder_settings_store.dart';
import 'features/notifications/domain/bill_reminder_coordinator.dart';
import 'features/notifications/presentation/providers/reminder_providers.dart';
import 'features/notifications/presentation/screens/reminder_settings_screen.dart';
import 'features/recurrences/presentation/providers/recurrence_providers.dart';
import 'features/recurrences/presentation/screens/recurrences_screen.dart';
import 'features/security/data/android_access.dart';
import 'features/security/presentation/app_access_gate.dart';
import 'features/security/presentation/security_settings_screen.dart';
import 'features/transactions/presentation/screens/transactions_screen.dart';
import 'features/transactions/presentation/widgets/transaction_form.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

@pragma('vm:entry-point')
Future<void> driveSyncWorker() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  var retry = false;
  try {
    final outcome = await AndroidDriveBackup(BackupDatabase(database))
        .automaticSync();
    if (outcome == SyncOutcome.downloaded) {
      final settings = await ReminderSettingsStore(database).watch().first;
      final bills = await BillRepositoryImpl(database).watchAllBills().first;
      await BillReminderCoordinator(AndroidReminderNotifications())
          .synchronize(settings, bills);
    }
  } on BackupProblem catch (error) {
    retry = error.retry;
  } catch (_) {
    retry = true;
  } finally {
    try {
      await database.close();
    } catch (_) {
      retry = true;
    }
    await AndroidDriveBackup.completeWorker(retry: retry);
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<Set<TableUpdate>>? _databaseChanges;
  Timer? _backupPoll;
  Timer? _afterEdit;
  bool _syncing = false;
  bool _foreground = false;
  int? _externalDataVersion;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: _resume,
      onPause: _pause,
      onHide: _pause,
    );
    Future.microtask(_resume);
  }

  Future<void> _resume() async {
    if (!mounted || _foreground) return;
    _foreground = true;
    final backup = ref.read(driveBackupProvider);
    if (backup != null) {
      // The WorkManager engine may have committed changes while this engine
      // was paused, so refresh its Drift streams before showing saved data.
      backup.database.refresh();
      ref.invalidate(driveStatusProvider);
      _databaseChanges ??= backup.database.db.tableUpdates().listen((_) {
        if (!_foreground ||
            _syncing ||
            ref.read(driveStatusProvider).valueOrNull?.automatic != true) {
          return;
        }
        _afterEdit?.cancel();
        _afterEdit = Timer(const Duration(seconds: 3), _pollDrive);
      });
      _backupPoll = Timer.periodic(
        const Duration(seconds: 45),
        (_) => _pollDrive(),
      );
      await _pollDrive();
    }
    await _syncSchedules();
  }

  void _pause() {
    _foreground = false;
    _backupPoll?.cancel();
    _afterEdit?.cancel();
  }

  Future<void> _pollDrive() async {
    if (!mounted || !_foreground || _syncing) return;
    _syncing = true;
    final backup = ref.read(driveBackupProvider);
    try {
      await backup?.automaticSync();
    } on BackupProblem {
      // Drive and authorization errors are available in the backup settings.
    } catch (_) {
      // Keep local use available if Android's secure storage is unavailable.
    } finally {
      if (backup != null && mounted) {
        try {
          final version = await backup.database.dataVersion();
          if (_externalDataVersion != null && version != _externalDataVersion) {
            backup.database.refresh();
          }
          _externalDataVersion = version;
        } catch (_) {
          // The next poll or resume can refresh the views after a busy database.
        }
      }
      _syncing = false;
      if (mounted) ref.invalidate(driveStatusProvider);
    }
  }

  Future<void> _syncSchedules() async {
    if (!mounted) return;
    ref.invalidate(billReminderSyncProvider);
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
    _pause();
    _databaseChanges?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(billReminderSyncProvider);
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
      builder: (context, child) => AppAccessGate(child: child!),
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

class _MoreScreen extends ConsumerWidget {
  const _MoreScreen({required this.onOpenPage});

  final ValueChanged<Widget> onOpenPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Cartões de crédito'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenPage(const CreditCardsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Metas financeiras'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenPage(const GoalsScreen()),
          ),
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
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenPage(const ReminderSettingsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categorias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenPage(const CategoriesScreen()),
          ),
          if (ref.watch(localAccessProvider) != null)
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configurações'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpenPage(const SettingsScreen()),
            ),
        ],
      ),
    );
  }
}
