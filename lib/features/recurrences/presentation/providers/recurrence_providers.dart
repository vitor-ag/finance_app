import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/repositories/recurrence_repository_impl.dart';
import '../../domain/entities/recurrence.dart';
import '../../domain/repositories/recurrence_repository.dart';

part 'recurrence_providers.g.dart';

@Riverpod(keepAlive: true)
RecurrenceRepository recurrenceRepository(RecurrenceRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return RecurrenceRepositoryImpl(db);
}

@riverpod
Stream<List<Recurrence>> allRecurrences(AllRecurrencesRef ref) {
  final repo = ref.watch(recurrenceRepositoryProvider);
  return repo.watchAllRecurrences();
}