import 'package:flutter/material.dart';

import '../../../../core/money.dart';
import '../../domain/entities/goal.dart';

class GoalProgress extends StatelessWidget {
  const GoalProgress({super.key, required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = goal.isOverdue(DateTime.now());
    final status = goal.isReached
        ? 'Meta atingida'
        : overdue
        ? 'Prazo vencido'
        : 'Em andamento';
    final color = overdue ? theme.colorScheme.error : theme.colorScheme.primary;
    final due = goal.dueDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(status, style: theme.textTheme.labelLarge?.copyWith(color: color)),
        const SizedBox(height: 8),
        Text(
          '${formatBrl(goal.savedCents)} de ${formatBrl(goal.targetCents)}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: goal.isReached ? 1 : goal.savedCents / goal.targetCents,
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          semanticsLabel: 'Progresso da meta',
          semanticsValue: '${goal.progressPercent}%',
        ),
        const SizedBox(height: 8),
        Text(
          '${goal.progressPercent}% · Prazo ${due.day}/${due.month}/${due.year}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
