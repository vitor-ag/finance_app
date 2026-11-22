import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components.dart';
import '../../domain/entities/bill.dart';

class BillTile extends StatelessWidget {
  const BillTile({
    super.key,
    required this.bill,
    this.categoryName,
    this.onMarkAsPaid,
    this.onEdit,
    this.onCancel,
    this.onStopRepeat,
  });
  final Bill bill;
  final String? categoryName;
  final VoidCallback? onMarkAsPaid, onEdit, onCancel, onStopRepeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    final status = bill.effectiveStatus;
    final (label, color, symbol) = switch (status) {
      'paid' => ('Paga', tokens.incomeText, Symbols.check_circle_rounded),
      'overdue' => ('Atrasada', tokens.expenseText, Symbols.event_busy_rounded),
      'cancelled' => (
        'Cancelada',
        theme.colorScheme.onSurfaceVariant,
        Symbols.cancel_rounded,
      ),
      _ => ('Pendente', theme.colorScheme.primary, Symbols.schedule_rounded),
    };
    return AppSurface(
      onTap: status == 'pending' || status == 'overdue' ? onMarkAsPaid : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(symbol, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name, style: theme.textTheme.titleSmall),
                Text(
                  'Vence em ${DateFormat.yMd('pt_BR').format(bill.dueDate)}'
                  '${categoryName == null ? '' : ' · $categoryName'}'
                  '${bill.repeatDay == null ? '' : ' · Repetição mensal'}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MoneyText(bill.amountCents),
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null || onCancel != null || onStopRepeat != null)
            PopupMenuButton<VoidCallback>(
              tooltip: 'Ações da conta a pagar',
              icon: const Icon(Symbols.more_vert_rounded),
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                if (onEdit != null)
                  PopupMenuItem(
                    value: onEdit,
                    child: const Text('Editar conta'),
                  ),
                if (onCancel != null)
                  PopupMenuItem(
                    value: onCancel,
                    child: const Text('Cancelar conta'),
                  ),
                if (onStopRepeat != null)
                  PopupMenuItem(
                    value: onStopRepeat,
                    child: const Text('Parar repetição'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
