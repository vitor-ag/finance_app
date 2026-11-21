import 'package:flutter/material.dart';
import '../../domain/entities/recurrence.dart';

class RecurrenceTile extends StatelessWidget {
  final Recurrence recurrence;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const RecurrenceTile({
    super.key,
    required this.recurrence,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _frequencyLabel(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'Semanal';
      case 'yearly':
        return 'Anual';
      case 'monthly':
      default:
        return 'Mensal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = recurrence.type == 'income';
    final color = recurrence.status == 'cancelled' ||
            recurrence.status == 'finished'
        ? theme.colorScheme.outline
        : (isIncome ? Colors.green : Colors.red);

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
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.autorenew, color: color, size: 20),
        ),
        title: Text(
          recurrence.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          '${_frequencyLabel(recurrence.frequency)} · Próxima: '
          '${recurrence.nextOccurrenceDate.day}/${recurrence.nextOccurrenceDate.month}/${recurrence.nextOccurrenceDate.year}',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'pause') onPause?.call();
            if (value == 'resume') onResume?.call();
            if (value == 'cancel') onCancel?.call();
          },
          itemBuilder: (context) => [
            if (recurrence.status == 'active')
              const PopupMenuItem(value: 'pause', child: Text('Pausar')),
            if (recurrence.status == 'paused')
              const PopupMenuItem(value: 'resume', child: Text('Retomar')),
            if (recurrence.status == 'active' || recurrence.status == 'paused')
              const PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
          ],
          child: Text(
            _formatCurrency(recurrence.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }
}