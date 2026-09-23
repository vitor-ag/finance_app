import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
  });

  IconData _getCategoryIcon(String type) {
    // Placeholder icon logic — will be replaced by user-chosen icons later.
    return type == 'income' ? Icons.trending_up : Icons.trending_down;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = category.type == 'income';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: isIncome
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.15),
          child: Icon(
            _getCategoryIcon(category.type),
            color: isIncome ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          isIncome ? 'Receita' : 'Despesa',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}