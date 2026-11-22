import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/category_style.dart';
import '../../../../core/design/components.dart';
import '../../domain/entities/category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    this.parentName,
    this.onTap,
    this.onArchive,
    this.total,
    this.drag,
  });
  final Category category;
  final String? parentName;
  final VoidCallback? onTap, onArchive;
  final BigInt? total;
  final Widget? drag;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = categoryStyle(context, category);
    final income = category.type == 'income';
    final text = Theme.of(context).textTheme;
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      onTap: onTap,
      child: Row(
        children: [
          AppIcon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: text.titleSmall),
                Text(
                  [
                    income ? 'Receita' : 'Despesa',
                    if (parentName != null) parentName!,
                    if (!category.isActive) 'Arquivada',
                  ].join(' · '),
                  style: text.bodySmall,
                ),
                if (total != null)
                  MoneyText.total(
                    total!,
                    kind: income ? MoneyKind.income : MoneyKind.expense,
                    signed: true,
                  ),
              ],
            ),
          ),
          if (onArchive != null)
            PopupMenuButton<String>(
              tooltip: 'Ações da categoria',
              icon: const Icon(Symbols.more_vert_rounded),
              onSelected: (_) => onArchive!(),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'archive',
                  child: Text('Arquivar categoria'),
                ),
              ],
            ),
          if (drag != null) drag!,
        ],
      ),
    );
  }
}
