/// Domain entity for a recurring transaction template
/// (e.g. salary every 5th, rent every 10th).
class Recurrence {
  final int? id;
  final String name;
  final String type; // 'income', 'expense', 'transfer'
  final int amountCents;
  final int accountId;
  final int? destinationAccountId;
  final int? categoryId;
  final String? description;
  final String frequency; // 'monthly', 'weekly', 'yearly'
  final int? dayOfMonth;
  final int? weekday;
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final int generatedCount;
  final DateTime nextOccurrenceDate;
  final String status; // 'active', 'paused', 'finished', 'cancelled'
  final DateTime createdAt;

  const Recurrence({
    this.id,
    required this.name,
    required this.type,
    required this.amountCents,
    required this.accountId,
    this.destinationAccountId,
    this.categoryId,
    this.description,
    required this.frequency,
    this.dayOfMonth,
    this.weekday,
    required this.startDate,
    this.endDate,
    this.maxOccurrences,
    this.generatedCount = 0,
    required this.nextOccurrenceDate,
    this.status = 'active',
    required this.createdAt,
  });

  Recurrence copyWith({
    int? id,
    String? name,
    String? type,
    int? amountCents,
    int? accountId,
    int? destinationAccountId,
    int? categoryId,
    String? description,
    String? frequency,
    int? dayOfMonth,
    int? weekday,
    DateTime? startDate,
    DateTime? endDate,
    int? maxOccurrences,
    int? generatedCount,
    DateTime? nextOccurrenceDate,
    String? status,
    DateTime? createdAt,
  }) {
    return Recurrence(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amountCents: amountCents ?? this.amountCents,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekday: weekday ?? this.weekday,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      generatedCount: generatedCount ?? this.generatedCount,
      nextOccurrenceDate: nextOccurrenceDate ?? this.nextOccurrenceDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
