/// Domain entity for a financial transaction: income, expense or transfer.
class Transaction {
  final int? id;
  final String type; // 'income', 'expense', 'transfer'
  final double amount;
  final DateTime date;
  final int accountId;
  final int? destinationAccountId; // only for transfers
  final int? categoryId; // not used for transfers
  final String? description;
  final String status; // 'pending', 'paid', 'cancelled'
  final DateTime createdAt;
  final DateTime? deletedAt;

  const Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.accountId,
    this.destinationAccountId,
    this.categoryId,
    this.description,
    this.status = 'paid',
    required this.createdAt,
    this.deletedAt,
  });

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    DateTime? date,
    int? accountId,
    int? destinationAccountId,
    int? categoryId,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}