import 'transaction.dart';

class TransactionRevision {
  const TransactionRevision(this.action, this.recordedAt, this.previous);

  final String action;
  final DateTime recordedAt;
  final Transaction previous;
}
