import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/design/app_preferences.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components.dart';
import '../../../core/money.dart';
import '../domain/cash_forecast.dart';
import '../../goals/presentation/widgets/goal_cash_card.dart';
import 'cash_event_tile.dart';
import 'cash_forecast_provider.dart';

class CashForecastScreen extends ConsumerStatefulWidget {
  const CashForecastScreen({super.key});

  @override
  ConsumerState<CashForecastScreen> createState() => _CashForecastScreenState();
}

class _CashForecastScreenState extends ConsumerState<CashForecastScreen> {
  int? _accountId;

  @override
  Widget build(BuildContext context) {
    final forecast = ref.watch(cashForecastProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Previsão de saldo')),
      body: AppContent(
        maxWidth: AppLayout.maxReading,
        child: forecast.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            title: 'Não foi possível calcular a previsão.',
            actionLabel: 'Tentar novamente',
            onAction: () => ref.invalidate(cashForecastProvider),
          ),
          data: (data) {
            final account = data.accounts.containsKey(_accountId)
                ? _accountId
                : null;
            final projection = account == null
                ? data.total
                : data.forAccount(account);
            final movements = projection.days
                .where((day) => day.movements.isNotEmpty)
                .toList();
            final dates = DateFormat.Md('pt_BR');
            final last = projection.days.last;
            final hidden = PreferencesScope.of(context)?.discreet ?? false;
            final theme = Theme.of(context);
            return ListView(
              padding: AppLayout.pagePadding(context),
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey(account),
                  initialValue: account ?? 0,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Conta'),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Todas as contas disponíveis'),
                    ),
                    for (final MapEntry(key: id, value: item)
                        in data.accounts.entries)
                      DropdownMenuItem(
                        value: id,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: data.accounts.isEmpty
                      ? null
                      : (id) =>
                            setState(() => _accountId = id == 0 ? null : id),
                ),
                const SizedBox(height: 8),
                Text(
                  account == null
                      ? 'Inclui contas a pagar e faturas sem conta de pagamento definida.'
                      : 'Exibe movimentações vinculadas a esta conta. Faturas e contas sem vínculo aparecem no total geral.',
                  style: theme.textTheme.bodySmall,
                ),
                GoalCashCard(accountId: account),
                const SizedBox(height: 16),
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Saldo previsto em ${dates.format(last.date)}',
                        style: theme.textTheme.titleMedium,
                      ),
                      MoneyText.total(
                        last.closing,
                        emphasis: true,
                        kind: last.closing.isNegative
                            ? MoneyKind.expense
                            : MoneyKind.neutral,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 24,
                        runSpacing: 10,
                        children: [
                          _Metric('Saldo atual', projection.opening),
                          _Metric(
                            'Entradas previstas',
                            projection.income,
                            kind: MoneyKind.income,
                          ),
                          _Metric(
                            'Saídas previstas',
                            projection.expense,
                            kind: MoneyKind.expense,
                          ),
                          _Metric(
                            'Menor saldo em ${dates.format(projection.lowestDay.date)}',
                            projection.lowestDay.closing,
                            kind: projection.lowestDay.closing.isNegative
                                ? MoneyKind.expense
                                : MoneyKind.neutral,
                          ),
                        ],
                      ),
                      if (projection.firstNegativeDay case final day?
                          when !hidden) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Saldo fica negativo em ${dates.format(day.date)}.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.of(context).expenseText,
                          ),
                        ),
                      ],
                      if (!hidden && movements.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _ProjectionChart(days: projection.days),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Movimentações previstas',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'De ${dates.format(data.today)} a ${dates.format(last.date)}. Pendências vencidas entram no cálculo de hoje.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (movements.isEmpty)
                  const EmptyState(
                    title: 'Nenhuma movimentação prevista no período.',
                    icon: Symbols.event_rounded,
                    compact: true,
                  ),
                for (final day in movements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Text(
                                day.date == data.today
                                    ? 'Hoje'
                                    : DateFormat.MMMMd('pt_BR')
                                          .format(day.date),
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                'Saldo ao fim do dia',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: MoneyText.total(day.closing),
                          ),
                          const Divider(),
                          for (final movement in day.movements)
                            CashEventTile(
                              event: movement.event,
                              delta: movement.delta,
                              today: data.today,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.kind = MoneyKind.neutral});

  final String label;
  final BigInt value;
  final MoneyKind kind;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      MoneyText.total(value, kind: kind),
    ],
  );
}

class _ProjectionChart extends StatelessWidget {
  const _ProjectionChart({required this.days});

  final List<ForecastDay> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final points = [
      for (final (index, day) in days.indexed)
        FlSpot(index.toDouble(), day.closing.toDouble() / 100),
    ];
    final min = points.map((point) => point.y).fold(0.0, math.min);
    final max = points.map((point) => point.y).fold(0.0, math.max);
    final padding = math.max(1.0, (max - min) * .08);
    final dates = DateFormat.Md('pt_BR');
    return Column(
      children: [
        Semantics(
          label: 'Gráfico do saldo previsto por dia',
          child: SizedBox(
            height: 132,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (days.length - 1).toDouble(),
                minY: min - padding,
                maxY: max + padding,
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(y: 0, color: scheme.outline, strokeWidth: 1),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => scheme.onSurface,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${dates.format(days[spot.x.toInt()].date)}\n'
                          '${formatBrlSum(days[spot.x.toInt()].closing)}',
                          TextStyle(color: scheme.surface),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isStepLineChart: true,
                    lineChartStepData: const LineChartStepData(
                      stepDirection: LineChartStepData.stepDirectionForward,
                    ),
                    color: scheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
              duration: Duration.zero,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dates.format(days.first.date)),
            Text(dates.format(days.last.date)),
          ],
        ),
      ],
    );
  }
}
