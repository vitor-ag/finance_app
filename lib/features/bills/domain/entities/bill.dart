/// Domain entity for a bill to pay (fixed, recurring or one-off).
/// "overdue" is never persisted — it's derived from [dueDate] + [status].
class Bill {
  final int? id;
  final String name;
  final int? categoryId;
  final double amount;
  final DateTime dueDate;
  final String billType; // 'fixed', 'recurring', 'eventual'
  final String status; // 'pending', 'paid', 'cancelled'
  final int? paymentAccountId;
  final int? paidTransactionId;
  final String? notes;
  final DateTime createdAt;

  const Bill({
    this.id,
    required this.name,
    this.categoryId,
    required this.amount,
    required this.dueDate,
    required this.billType,
    this.status = 'pending',
    this.paymentAccountId,
    this.paidTransactionId,
    this.notes,
    required this.createdAt,
  });

  /// Effective status, computing "overdue" on the fly.
  String get effectiveStatus {
    if (status == 'pending' && dueDate.isBefore(DateTime.now())) {
      return 'overdue';
    }
    return status;
  }

  Bill copyWith({
    int? id,
    String? name,
    int? categoryId,
    double? amount,
    DateTime? dueDate,
    String? billType,
    String? status,
    int? paymentAccountId,
    int? paidTransactionId,
    String? notes,
    DateTime? createdAt,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      billType: billType ?? this.billType,
      status: status ?? this.status,
      paymentAccountId: paymentAccountId ?? this.paymentAccountId,
      paidTransactionId: paidTransactionId ?? this.paidTransactionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}