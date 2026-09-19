/// Domain entity for a financial account (wallet, bank account, etc.).
/// Independent from any persistence detail (Drift, SQL, etc.).
class Account {
  final int? id;
  final String name;
  final String type;
  final double initialBalance;
  final double currentBalance;
  final String? color;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;
  final String? notes;

  const Account({
    this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.currentBalance,
    this.color,
    this.icon,
    this.isActive = true,
    required this.createdAt,
    this.notes,
  });

  Account copyWith({
    int? id,
    String? name,
    String? type,
    double? initialBalance,
    double? currentBalance,
    String? color,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
    String? notes,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}