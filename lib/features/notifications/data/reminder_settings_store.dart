import 'package:drift/drift.dart';

import '../../../data/local/database.dart';
import '../domain/reminder_settings.dart';

class ReminderSettingsStore {
  ReminderSettingsStore(this._db);

  final AppDatabase _db;
  static const _id = 1;

  Stream<ReminderSettings> watch() =>
      (_db.select(
        _db.billReminderSettings,
      )..where((row) => row.id.equals(_id))).watchSingleOrNull().map(
        (row) => row == null
            ? const ReminderSettings()
            : ReminderSettings(
                enabled: row.enabled,
                daysBefore: row.daysBefore,
                minuteOfDay: row.minuteOfDay,
                configuredAt: row.configuredAt,
              ),
      );

  Future<void> save(ReminderSettings settings) async {
    if (settings.daysBefore < 0 ||
        settings.daysBefore > 30 ||
        settings.minuteOfDay < 0 ||
        settings.minuteOfDay >= 24 * 60) {
      throw ArgumentError('Informe uma antecedência e um horário válidos.');
    }
    await _db.transaction(() async {
      final previous = await (_db.select(
        _db.billReminderSettings,
      )..where((row) => row.id.equals(_id))).getSingleOrNull();
      if (previous?.enabled == settings.enabled &&
          previous?.daysBefore == settings.daysBefore &&
          previous?.minuteOfDay == settings.minuteOfDay) {
        return;
      }
      await _db
          .into(_db.billReminderSettings)
          .insertOnConflictUpdate(
            BillReminderSettingsCompanion(
              id: const Value(_id),
              enabled: Value(settings.enabled),
              daysBefore: Value(settings.daysBefore),
              minuteOfDay: Value(settings.minuteOfDay),
              configuredAt: Value(DateTime.now()),
            ),
          );
    });
  }
}
