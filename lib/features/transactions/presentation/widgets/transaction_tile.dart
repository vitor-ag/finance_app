import 'package:flutter/material.dart';

import '../../../../core/money.dart';
import '../../domain/entities/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String accountName;
  final String? categoryName;
  final String? destinationAccountName;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.accountName,
    this.categoryName,
    this.destinationAccountName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';

    final color = isTransfer
        ? theme.colorScheme.tertiary
        : (isIncome ? Colors.green : Colors.red);

    final icon = isTransfer
        ? Icons.swap_horiz
        : (isIncome ? Icons.arrow_downward : Icons.arrow_upward);

    final subtitle = isTransfer
        ? '$accountName → ${destinationAccountName ?? '-'}'
        : '$accountName${categoryName != null ? ' · $categoryName' : ''}';

    final sign = isIncome ? '+' : (isTransfer ? '' : '-');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          transaction.description?.isNotEmpty == true
              ? transaction.description!
              : (isTransfer ? 'Transferência' : (categoryName ?? '-')),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: DefaultTextStyle(
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(subtitle),
              if (transaction.incomeSource case final source?) Text(source),
              Text(
                '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$sign${formatBrl(transaction.amountCents)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
            if (onTap != null)
              IconButton(
                tooltip: transaction.deletedAt == null
                    ? 'Ações do lançamento'
                    : 'Restaurar lançamento',
                icon: Icon(
                  transaction.deletedAt == null
                      ? Icons.more_vert
                      : Icons.restore,
                ),
                onPressed: onTap,
              ),
          ],
        ),
      ),
    );
  }
}
