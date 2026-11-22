import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/components.dart';
import '../../domain/entities/recurrence.dart';

class RecurrenceTile extends StatelessWidget {
  const RecurrenceTile({
    super.key,
    required this.recurrence,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onEdit,
  });
  final Recurrence recurrence;
  final VoidCallback? onPause, onResume, onCancel, onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final frequency = switch (recurrence.frequency) {
      'weekly' => 'Semanal',
      'yearly' => 'Anual',
      _ => 'Mensal',
    };
    final status = switch (recurrence.status) {
      'cancelled' => 'Encerrada',
      'finished' => 'Concluída',
      'paused' => 'Pausada',
      _ => 'Ativa',
    };
    final kind = switch (recurrence.type) {
      'income' => MoneyKind.income,
      'expense' => MoneyKind.expense,
      _ => MoneyKind.neutral,
    };
    return AppSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(Symbols.event_repeat_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recurrence.name, style: theme.textTheme.titleSmall),
                Text('$frequency · $status', style: theme.textTheme.bodySmall),
                if (recurrence.status == 'active')
                  Text(
                    'Próxima em ${DateFormat.yMd('pt_BR').format(recurrence.nextOccurrenceDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 4),
                MoneyText(recurrence.amountCents, signed: true, kind: kind),
              ],
            ),
          ),
          if ([onPause, onResume, onEdit, onCancel].any((item) => item != null))
            PopupMenuButton<VoidCallback>(
              tooltip: 'Ações da recorrência',
              icon: const Icon(Symbols.more_vert_rounded),
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                if (onPause != null)
                  PopupMenuItem(value: onPause, child: const Text('Pausar')),
                if (onResume != null)
                  PopupMenuItem(value: onResume, child: const Text('Retomar')),
                if (onEdit != null)
                  PopupMenuItem(
                    value: onEdit,
                    child: const Text('Editar recorrência'),
                  ),
                if (onCancel != null)
                  PopupMenuItem(
                    value: onCancel,
                    child: const Text('Encerrar recorrência'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
