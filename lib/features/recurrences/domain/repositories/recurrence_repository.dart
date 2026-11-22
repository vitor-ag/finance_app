import '../entities/recurrence.dart';
import '../../../transactions/domain/entities/transaction.dart';

abstract class RecurrenceRepository {
  Stream<List<Recurrence>> watchAllRecurrences();
  Future<int> createRecurrence(Recurrence recurrence, {Transaction? first});
  Future<void> updateRecurrence(Recurrence recurrence);
  Future<void> pauseRecurrence(int id);
  Future<void> resumeRecurrence(int id);
  Future<void> cancelRecurrence(int id);

  /// Generates every due Transaction for all active recurrences,
  /// advancing each one's nextOccurrenceDate. Safe to call every
  /// app startup — it's idempotent for dates already generated.
  Future<void> generateDueOccurrences();
}
