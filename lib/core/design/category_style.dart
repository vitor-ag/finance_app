import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/categories/domain/entities/category.dart';
import 'app_theme.dart';
import 'components.dart';

const financialIcons = <String, (IconData, String)>{
  'home': (Symbols.home_rounded, 'Casa'),
  'restaurant': (Symbols.restaurant_rounded, 'Alimentação'),
  'directions_car': (Symbols.directions_car_rounded, 'Carro'),
  'directions_bus': (Symbols.directions_bus_rounded, 'Ônibus'),
  'sports_esports': (Symbols.sports_esports_rounded, 'Jogos'),
  'favorite': (Symbols.favorite_rounded, 'Saúde'),
  'school': (Symbols.school_rounded, 'Educação'),
  'shopping_bag': (Symbols.shopping_bag_rounded, 'Compras'),
  'receipt_long': (Symbols.receipt_long_rounded, 'Contas'),
  'category': (Symbols.category_rounded, 'Categoria'),
  'payments': (Symbols.payments_rounded, 'Dinheiro'),
  'work': (Symbols.work_rounded, 'Trabalho'),
  'savings': (Symbols.savings_rounded, 'Economias'),
  'account_balance': (Symbols.account_balance_rounded, 'Banco'),
  'wallet': (Symbols.account_balance_wallet_rounded, 'Carteira'),
  'credit_card': (Symbols.credit_card_rounded, 'Cartão'),
  'shopping_cart': (Symbols.shopping_cart_rounded, 'Mercado'),
  'flight': (Symbols.flight_rounded, 'Viagem'),
  'fitness_center': (Symbols.fitness_center_rounded, 'Esporte'),
  'pets': (Symbols.pets_rounded, 'Animais'),
  'redeem': (Symbols.redeem_rounded, 'Presente'),
  'bolt': (Symbols.bolt_rounded, 'Energia'),
  'checkroom': (Symbols.checkroom_rounded, 'Roupas'),
  'flag': (Symbols.flag_rounded, 'Meta'),
};

const defaultExpenseCategories = <(String, String)>[
  ('Moradia', 'home'),
  ('Alimentação', 'restaurant'),
  ('Transporte', 'directions_car'),
  ('Lazer', 'sports_esports'),
  ('Saúde', 'favorite'),
  ('Educação', 'school'),
  ('Compras', 'shopping_bag'),
  ('Contas e assinaturas', 'receipt_long'),
  ('Outros', 'category'),
];

Color? storedColor(String? value) {
  if (value == null) return null;
  final hex = value.replaceFirst('#', '');
  final number = int.tryParse(hex, radix: 16);
  if (number == null) return null;
  if (hex.length == 6) return Color(number | 0xff000000);
  if (hex.length == 8) return Color(number);
  return null;
}

String colorHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

(IconData, Color) categoryStyle(BuildContext context, Category? category) {
  final tokens = AppColors.of(context);
  final preset = defaultExpenseCategories.indexWhere(
    (item) => item.$1.toLowerCase() == category?.name.toLowerCase(),
  );
  final iconName =
      category?.icon ??
      (preset >= 0
          ? defaultExpenseCategories[preset].$2
          : category?.type == 'income'
          ? 'payments'
          : 'category');
  return (
    financialIcons[iconName]?.$1 ?? Symbols.category_rounded,
    storedColor(category?.color) ??
        (category?.type == 'income'
            ? tokens.income
            : AppColors.categoryPalette[preset < 0 ? 8 : preset]),
  );
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onSelected,
  });
  final Category category;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = categoryStyle(context, category);
    return FilterChip(
      avatar: Icon(icon, color: color, size: 20),
      label: Text(category.name),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class IconPalette extends StatelessWidget {
  const IconPalette({super.key, required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final item in financialIcons.entries)
        Semantics(
          selected: item.key == value,
          child: IconButton(
            tooltip: item.value.$2,
            style: item.key == value
                ? IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  )
                : null,
            icon: Icon(item.value.$1, weight: 500),
            onPressed: () => onChanged(item.key),
          ),
        ),
    ],
  );
}

class ColorPalette extends StatelessWidget {
  const ColorPalette({super.key, required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String> onChanged;

  static const _names = [
    'Violeta',
    'Laranja',
    'Azul',
    'Rosa',
    'Verde',
    'Amarelo',
    'Ciano',
    'Azul acinzentado',
    'Lilás',
    'Azul vivo',
    'Vermelho',
    'Roxo',
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (index, color) in AppColors.categoryPalette.indexed)
        Semantics(
          selected: storedColor(value) == color,
          child: IconButton(
            tooltip: _names[index],
            icon: AppIcon(
              storedColor(value) == color
                  ? Symbols.check_rounded
                  : Symbols.circle_rounded,
              color: color,
            ),
            onPressed: () => onChanged(colorHex(color)),
            padding: EdgeInsets.zero,
          ),
        ),
    ],
  );
}
