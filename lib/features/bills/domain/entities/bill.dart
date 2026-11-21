import '../../../../core/calendar.dart';

/// Domain entity for a bill to pay (fixed, recurring or one-off).
/// "overdue" is never persisted — it's derived from [dueDate] + [status].
class Bill {
  final int? id;
  final String name;
  final int? categoryId;
  final int amountCents;
  final DateTime dueDate;
  final String billType; // 'fixed', 'recurring', 'eventual'
  final String status; // 'pending', 'paid', 'cancelled'
  final int? paymentAccountId;
  final int? paidTransactionId;
  final int? repeatDay;
  final int? previousBillId;
  final String? notes;
  final DateTime createdAt;

  const Bill({
    this.id,
    required this.name,
    this.categoryId,
    required this.amountCents,
    required this.dueDate,
    required this.billType,
    this.status = 'pending',
    this.paymentAccountId,
    this.paidTransactionId,
    this.repeatDay,
    this.previousBillId,
    this.notes,
    required this.createdAt,
  });

  /// Effective status, computing "overdue" on the fly.
  String get effectiveStatus {
    if (status == 'pending' &&
        calendarDate(dueDate).isBefore(calendarDate(DateTime.now()))) {
      return 'overdue';
    }
    return status;
  }

  Bill copyWith({
    int? id,
    String? name,
    int? categoryId,
    int? amountCents,
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
      amountCents: amountCents ?? this.amountCents,
      dueDate: dueDate ?? this.dueDate,
      billType: billType ?? this.billType,
      status: status ?? this.status,
      paymentAccountId: paymentAccountId ?? this.paymentAccountId,
      paidTransactionId: paidTransactionId ?? this.paidTransactionId,
      repeatDay: repeatDay,
      previousBillId: previousBillId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
