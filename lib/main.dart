import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/adaptive_scaffold.dart';
import 'core/design/app_preferences.dart';
import 'core/design/app_theme.dart';
import 'core/providers/database_provider.dart';
import 'data/local/database.dart';
import 'features/budgets/planning_screen.dart';
import 'features/reports/finance_summary.dart';
import 'features/reports/reports_screen.dart';
import 'features/settings/app_settings_screen.dart';
import 'features/settings/onboarding_screen.dart';
import 'features/backup/data/android_drive_backup.dart';
import 'features/backup/data/backup_snapshot.dart';
import 'features/backup/data/drive_sync.dart';
import 'features/backup/data/local_backup.dart';
import 'features/bills/data/repositories/bill_repository_impl.dart';
import 'features/bills/presentation/providers/bill_providers.dart';
import 'features/bills/presentation/screens/bills_screen.dart';
import 'features/credit_cards/presentation/credit_cards_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/forecast/presentation/cash_forecast_screen.dart';
import 'features/notifications/data/android_reminder_notifications.dart';
import 'features/notifications/data/planning_reminders.dart';
import 'features/notifications/data/reminder_settings_store.dart';
import 'features/notifications/domain/bill_reminder_coordinator.dart';
import 'features/notifications/presentation/providers/reminder_providers.dart';
import 'features/recurrences/presentation/providers/recurrence_providers.dart';
import 'features/recurrences/presentation/screens/recurrences_screen.dart';
import 'features/security/presentation/app_access_gate.dart';
import 'features/transactions/presentation/screens/transactions_screen.dart';
import 'features/transactions/presentation/widgets/transaction_form.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeDateFormatting('pt_BR');
  final preferences = AppPreferences(store: SharedPreferencesAsync());
  await preferences.load();
  runApp(ProviderScope(child: MyApp(preferences: preferences)));
}

@pragma('vm:entry-point')
Future<void> localBackupWorker() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  var retry = false;
  try {
    await LocalBackup(BackupDatabase(db)).runAutomatic();
  } catch (_) {
    retry = true;
  } finally {
    try {
      await db.close();
    } finally {
      await LocalBackup.completeWorker(retry: retry);
    }
  }
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
  const MyApp({super.key, this.preferences});

  final AppPreferences? preferences;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLifecycleListener _lifecycle;
  late final _preferences = widget.preferences ?? AppPreferences();
  StreamSubscription<Set<TableUpdate>>? _databaseChanges;
  Timer? _backupPoll;
  Timer? _afterEdit;
  bool _syncing = false;
  bool _foreground = false;
  int? _externalDataVersion;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');
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
    if (_preferences.isPersistent) {
      unawaited(
        ref.read(localBackupProvider).runAutomatic().catchError((Object _) {
          // Backup settings display the error for the configured folder.
        }),
      );
    }
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
    if (widget.preferences == null) _preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(billReminderSyncProvider);
    ref.watch(planningAlertsProvider);
    return ListenableBuilder(
      listenable: _preferences,
      builder: (context, _) {
        final size = WindowSizeClass.of(context);
        return PreferencesScope(
          preferences: _preferences,
          child: MaterialApp(
            title: 'Finance App',
            debugShowCheckedModeBanner: false,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: appTheme(Brightness.light, size, _preferences.accent),
            darkTheme: appTheme(Brightness.dark, size, _preferences.accent),
            themeMode: _preferences.theme,
            builder: (context, child) =>
                DisplayFeatureSubScreen(child: AppAccessGate(child: child!)),
            home: const _AppHome(),
          ),
        );
      },
    );
  }
}

final _existingAccountsProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  return await (db.select(db.accounts)..limit(1)).getSingleOrNull() != null;
});

class _AppHome extends ConsumerWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = PreferencesScope.of(context)!;
    if (preferences.onboardingDone) return const RootScreen();
    return ref
        .watch(_existingAccountsProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(_existingAccountsProvider),
                child: const Text('Tentar abrir dados locais novamente'),
              ),
            ),
          ),
          data: (existing) => existing
              ? const RootScreen()
              : OnboardingScreen(preferences: preferences),
        );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen>
    with SingleTickerProviderStateMixin {
  final _transactions = GlobalKey<TransactionsScreenState>();
  final _visited = {0};
  late final _animation = AnimationController(
    vsync: this,
    duration: AppLayout.motion,
    value: 1,
  );
  int _index = 0;
  double _direction = 1;
  bool _creating = false;
  bool _settingsOpen = false;
  (Period, int?)? _pendingCategory;

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _direction = index > _index ? 1 : -1;
      _index = index;
      _visited.add(index);
    });
    _animation.forward(from: 0);
  }

  Future<void> _new([String type = 'expense']) async {
    if (_creating) return;
    setState(() => _creating = true);
    await showTransactionForm(
      context,
      type: type,
      onSaved: (id) => _transactions.currentState?.highlight(id),
    );
    if (mounted) setState(() => _creating = false);
  }

  Future<void> _settings() async {
    if (_settingsOpen) return;
    _settingsOpen = true;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
    );
    _settingsOpen = false;
  }

  void _search() {
    _select(1);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _transactions.currentState?.focusSearch(),
    );
  }

  void _openCategory(Period period, int? id) {
    _pendingCategory = (period, id);
    _select(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingCategory case final selection?) {
        _transactions.currentState?.openCategory(selection.$1, selection.$2);
        _pendingCategory = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final curved = _animation.drive(CurveTween(curve: Curves.easeOutCubic));
    final pages = [
      DashboardScreen(
        onOpenBills: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const BillsScreen()),
        ),
        onOpenCards: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const CreditCardsScreen()),
        ),
        onOpenCard: (id) => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => CardDetailsScreen(cardId: id)),
        ),
        onOpenRecurrences: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const RecurrencesScreen()),
        ),
        onOpenForecast: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const CashForecastScreen()),
        ),
        onOpenCategory: _openCategory,
        onSettings: _settings,
        onNew: _new,
        onReports: () => _select(3),
        onPlanning: () => _select(2),
        onTransactions: () => _select(1),
      ),
      TransactionsScreen(key: _transactions),
      const PlanningScreen(),
      ReportsScreen(onCategory: _openCategory),
    ];
    return AdaptiveScaffold(
      index: _index,
      onSelect: _select,
      onNew: _new,
      onSettings: _settings,
      onSearch: _search,
      creating: _creating,
      body: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: Offset(reduced ? 0 : .045 * _direction, 0),
            end: Offset.zero,
          ).animate(curved),
          child: IndexedStack(
            index: _index,
            children: [
              for (final (index, page) in pages.indexed)
                TickerMode(
                  enabled: _index == index,
                  child: _visited.contains(index)
                      ? page
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
