import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../bills/domain/entities/bill.dart';
import '../../../bills/presentation/providers/bill_providers.dart';
import '../../data/android_reminder_notifications.dart';
import '../../data/reminder_settings_store.dart';
import '../../domain/bill_reminder_coordinator.dart';
import '../../domain/reminder_notifications.dart';
import '../../domain/reminder_settings.dart';

final reminderSettingsStoreProvider = Provider<ReminderSettingsStore>(
  (ref) => ReminderSettingsStore(ref.watch(databaseProvider)),
);

final reminderSettingsProvider = StreamProvider.autoDispose<ReminderSettings>(
  (ref) => ref.watch(reminderSettingsStoreProvider).watch(),
);

final reminderNotificationsProvider = Provider<ReminderNotifications>(
  (ref) => AndroidReminderNotifications(),
);

final _billReminderCoordinatorProvider = Provider<BillReminderCoordinator>(
  (ref) => BillReminderCoordinator(ref.watch(reminderNotificationsProvider)),
);

final billReminderSyncProvider = FutureProvider<void>((ref) async {
  final gateway = ref.watch(reminderNotificationsProvider);
  if (!gateway.isSupported) return;
  final settings = ref.watch(reminderSettingsProvider).valueOrNull;
  if (settings == null) return;
  final bills = settings.enabled
      ? ref.watch(allBillsProvider).valueOrNull
      : const <Bill>[];
  if (bills == null) return;
  await ref
      .watch(_billReminderCoordinatorProvider)
      .synchronize(settings, bills);
});
