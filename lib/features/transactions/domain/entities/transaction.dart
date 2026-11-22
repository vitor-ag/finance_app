/// Domain entity for a financial transaction: income, expense or transfer.
class Transaction {
  final int? id;
  final String type; // 'income', 'expense', 'transfer'
  final int amountCents;
  final DateTime date;
  final int accountId;
  final int? destinationAccountId; // only for transfers
  final int? categoryId; // not used for transfers
  final String? description;
  final String? note;
  final String? photo;
  final String? incomeSource;
  final String status; // 'pending', 'paid', 'cancelled'
  final int? recurrenceId;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const Transaction({
    this.id,
    required this.type,
    required this.amountCents,
    required this.date,
    required this.accountId,
    this.destinationAccountId,
    this.categoryId,
    this.description,
    this.note,
    this.photo,
    this.incomeSource,
    this.status = 'paid',
    this.recurrenceId,
    required this.createdAt,
    this.deletedAt,
  });

  Transaction copyWith({
    int? id,
    String? type,
    int? amountCents,
    DateTime? date,
    int? accountId,
    int? destinationAccountId,
    int? categoryId,
    String? description,
    String? note,
    String? photo,
    String? incomeSource,
    String? status,
    int? recurrenceId,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amountCents: amountCents ?? this.amountCents,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      note: note ?? this.note,
      photo: photo ?? this.photo,
      incomeSource: incomeSource ?? this.incomeSource,
      status: status ?? this.status,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
