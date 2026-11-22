import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components.dart';
import '../../../forecast/presentation/cash_forecast_provider.dart';
import '../../domain/goal_plan.dart';
import '../providers/goal_providers.dart';

class GoalCashCard extends ConsumerWidget {
  const GoalCashCard({super.key, this.accountId});

  final int? accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(cashForecastProvider).valueOrNull;
    final plans = ref.watch(goalPlansProvider).valueOrNull;
    if (forecast == null ||
        plans == null ||
        !plans.any(
          (item) =>
              forecast.accounts.containsKey(item.goal.accountId) &&
              (accountId == null || accountId == item.goal.accountId),
        )) {
      return const SizedBox.shrink();
    }
    final limit = goalSpendingLimit(forecast, plans, accountId: accountId);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caixa com metas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                for (final (title, amount) in [
                  ('Reservado nas metas', limit.reserved),
                  ('Livre hoje', limit.freeNow),
                  (
                    'Pode gastar hoje',
                    limit.safeToSpend.isNegative
                        ? BigInt.zero
                        : limit.safeToSpend,
                  ),
                ])
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(title), MoneyText.total(amount)],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Considera as metas vinculadas a contas disponíveis e os compromissos previstos em 30 dias.',
            ),
            if (limit.safeToSpend.isNegative)
              const Text(
                'O caixa previsto já está abaixo do necessário para os compromissos e as metas.',
              ),
          ],
        ),
      ),
    );
  }
}
