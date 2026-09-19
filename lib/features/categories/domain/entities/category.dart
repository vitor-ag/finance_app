/// Domain entity for an income or expense category.
/// A category can optionally have a parent (subcategory support).
class Category {
  final int? id;
  final String name;
  final String type; // 'income' or 'expense'
  final int? parentId;
  final String? color;
  final String? icon;
  final bool isActive;

  const Category({
    this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.color,
    this.icon,
    this.isActive = true,
  });

  Category copyWith({
    int? id,
    String? name,
    String? type,
    int? parentId,
    String? color,
    String? icon,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }
}