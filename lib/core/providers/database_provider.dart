import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/database.dart';

part 'database_provider.g.dart';

// Keeps a single database instance alive for the whole app lifecycle.
@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}