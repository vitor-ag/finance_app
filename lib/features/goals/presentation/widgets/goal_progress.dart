import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components.dart';
import '../../domain/entities/goal.dart';

class GoalProgress extends StatelessWidget {
  const GoalProgress({super.key, required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final overdue = goal.isOverdue(DateTime.now());
    final due = goal.dueDate;
    final color = goal.isReached
        ? palette.incomeText
        : overdue
        ? palette.expenseText
        : theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (goal.isReached || overdue)
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                goal.isReached
                    ? Symbols.verified_rounded
                    : Symbols.schedule_rounded,
                size: 16,
                color: color,
              ),
              Text(
                goal.isReached ? 'Meta alcançada' : 'Prazo vencido',
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            for (final (label, amount) in [
              ('Guardado', goal.savedCents),
              ('Valor-alvo', goal.targetCents),
            ])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.labelMedium),
                  MoneyText(amount),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        BudgetProgressBar(
          progress: goal.savedCents / goal.targetCents,
          color: color,
          label: 'Progresso da meta',
        ),
        const SizedBox(height: 4),
        Text(
          '${goal.progressPercent}%${due == null ? '' : ' · Prazo ${DateFormat.yMd('pt_BR').format(due)}'}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
