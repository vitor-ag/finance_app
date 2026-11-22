import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../budgets/budget_data.dart';
import '../../reports/finance_summary.dart';
import '../presentation/providers/reminder_providers.dart';
import 'android_reminder_notifications.dart';

typedef PlanningPreferences = ({bool daily, bool budget, int minutes});

final planningReminderStoreProvider = Provider(
  (ref) => PlanningReminderStore(),
);
final planningPreferencesProvider = FutureProvider(
  (ref) => ref.watch(planningReminderStoreProvider).read(),
);

final planningAlertsProvider = FutureProvider<void>((ref) async {
  final gateway = ref.watch(reminderNotificationsProvider);
  if (gateway is! AndroidReminderNotifications || !gateway.isSupported) return;
  final preferences = ref.watch(planningPreferencesProvider).valueOrNull;
  if (preferences?.budget != true) return;
  final budgets = ref.watch(budgetsProvider).valueOrNull;
  final history = ref.watch(financeHistoryProvider).valueOrNull;
  final store = ref.watch(planningReminderStoreProvider);
  if (budgets == null || history == null) return;
  final month = firstOfMonth(DateTime.now());
  final progress = BudgetProgress.forMonth(budgets, month, history);
  await store.updateAlerts(month, progress, gateway);
});

class PlanningReminderStore {
  late final _prefs = SharedPreferencesAsync();
  Future<void> _queue = Future.value();

  Future<PlanningPreferences> read() async => (
    daily: await _prefs.getBool('dailyReminder') ?? false,
    budget: await _prefs.getBool('budgetAlerts') ?? false,
    minutes: await _prefs.getInt('dailyReminderMinutes') ?? 9 * 60,
  );

  Future<void> save(PlanningPreferences preferences) async {
    await _prefs.setBool('dailyReminder', preferences.daily);
    await _prefs.setBool('budgetAlerts', preferences.budget);
    await _prefs.setInt('dailyReminderMinutes', preferences.minutes);
  }

  Future<void> updateAlerts(
    DateTime month,
    List<BudgetProgress> progress,
    AndroidReminderNotifications gateway,
  ) {
    final next = _queue.then((_) async {
      if (!await gateway.isAllowed()) return;
      final token = DateFormat('yyyy-MM').format(month);
      final previousMonth = await _prefs.getString('budgetAlertMonth');
      final sent = previousMonth == token
          ? (await _prefs.getStringList('budgetAlertsSent') ?? []).toSet()
          : <String>{};
      final newAlerts = <String>{};
      var exceeded = false;
      for (final item in progress) {
        final id = item.row.categoryId;
        if (item.ratio >= 1 && !sent.contains('$id:100')) {
          newAlerts.addAll(['$id:80', '$id:100']);
          exceeded = true;
        } else if (item.ratio >= .8 && !sent.contains('$id:80')) {
          newAlerts.add('$id:80');
        }
      }
      if (newAlerts.isEmpty) return;
      await gateway.showBudgetAlert(exceeded);
      await _prefs.setStringList('budgetAlertsSent', [...sent, ...newAlerts]);
      await _prefs.setString('budgetAlertMonth', token);
    });
    _queue = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }
}
