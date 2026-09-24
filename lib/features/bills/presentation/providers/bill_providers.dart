import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/repositories/bill_repository_impl.dart';
import '../../domain/entities/bill.dart';
import '../../domain/repositories/bill_repository.dart';

part 'bill_providers.g.dart';

@Riverpod(keepAlive: true)
BillRepository billRepository(BillRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return BillRepositoryImpl(db);
}

@riverpod
Stream<List<Bill>> allBills(AllBillsRef ref) {
  final repo = ref.watch(billRepositoryProvider);
  return repo.watchAllBills();
}