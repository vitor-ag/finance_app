import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/design/category_style.dart';
import '../../../../core/design/components.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';

MoneyKind transactionKind(Transaction item) => switch (item.type) {
  'expense' => MoneyKind.expense,
  'income' => MoneyKind.income,
  _ => MoneyKind.neutral,
};

String transactionType(String type) => switch (type) {
  'income' => 'Receita',
  'transfer' => 'Transferência',
  'card_payment' => 'Pagamento de fatura',
  _ => 'Despesa',
};

String transactionTitle(Transaction item, Category? category) =>
    item.description?.trim().isNotEmpty == true
    ? item.description!
    : category?.name ?? transactionType(item.type);

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.accountName,
    this.category,
    this.destinationAccountName,
    this.onTap,
    this.onActions,
  });

  final Transaction transaction;
  final String accountName;
  final Category? category;
  final String? destinationAccountName;
  final VoidCallback? onTap, onActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final kind = transactionKind(transaction);
    final (icon, color) = category == null
        ? switch (transaction.type) {
            'income' => (Symbols.arrow_upward_rounded, palette.incomeText),
            'expense' => (Symbols.arrow_downward_rounded, palette.expenseText),
            'card_payment' => (
              Symbols.credit_card_rounded,
              theme.colorScheme.primary,
            ),
            _ => (Symbols.swap_horiz_rounded, theme.colorScheme.primary),
          }
        : categoryStyle(context, category);
    final status = switch (transaction.status) {
      'pending' => 'Agendado',
      'cancelled' => 'Cancelado',
      _ => DateFormat.Hm('pt_BR').format(transaction.date),
    };
    final subtitle = transaction.type == 'transfer'
        ? '$accountName → ${destinationAccountName ?? 'Conta'}'
        : '${category?.name ?? transactionType(transaction.type)} · $accountName';
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 21;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.controlRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                AppIcon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transactionTitle(transaction, category),
                        maxLines: largeText ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall,
                        maxLines: largeText ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (largeText) ...[
                        MoneyText(
                          transaction.amountCents,
                          kind: kind,
                          signed: true,
                        ),
                        Text(status, style: theme.textTheme.labelMedium),
                      ],
                    ],
                  ),
                ),
                if (!largeText) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MoneyText(
                          transaction.amountCents,
                          kind: kind,
                          signed: true,
                          alignment: Alignment.centerRight,
                        ),
                        Text(
                          status,
                          style: theme.textTheme.labelMedium,
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
                if (onActions != null)
                  IconButton(
                    tooltip: transaction.deletedAt == null
                        ? 'Ações do lançamento'
                        : 'Restaurar lançamento',
                    icon: Icon(
                      transaction.deletedAt == null
                          ? Symbols.more_vert_rounded
                          : Symbols.restore_rounded,
                    ),
                    onPressed: onActions,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
