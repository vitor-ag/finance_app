/// Domain entity for a financial account (wallet, bank account, etc.).
/// Independent from any persistence detail (Drift, SQL, etc.).
class Account {
  final int? id;
  final String name;
  final String type;
  final int initialBalanceCents;
  final int currentBalanceCents;
  final String? color;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;
  final String? notes;

  bool get isAvailableCash => isActive && type != investmentAccountType;

  const Account({
    this.id,
    required this.name,
    required this.type,
    required this.initialBalanceCents,
    required this.currentBalanceCents,
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
    int? initialBalanceCents,
    int? currentBalanceCents,
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
      initialBalanceCents: initialBalanceCents ?? this.initialBalanceCents,
      currentBalanceCents: currentBalanceCents ?? this.currentBalanceCents,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

const investmentAccountType = 'investment';
