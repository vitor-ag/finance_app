import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:share_plus/share_plus.dart';

import '../../core/design/app_preferences.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/components.dart';
import '../../core/money.dart';
import '../../core/widgets/record_actions.dart';
import '../budgets/budgets_screen.dart';
import '../categories/domain/entities/category.dart';
import '../categories/presentation/providers/category_providers.dart';
import 'category_chart.dart';
import 'finance_summary.dart';

enum _ReportPeriod { month, quarter, year, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, required this.onCategory});
  final void Function(Period period, int? category) onCategory;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _ReportPeriod _type = _ReportPeriod.month;
  DateTime _month = firstOfMonth(DateTime.now());
  Period? _custom;
  int _tab = 0;

  Period _period() => switch (_type) {
    _ReportPeriod.month => monthPeriod(_month),
    _ReportPeriod.quarter => (
      start: DateTime(_month.year, _month.month - 2),
      end: monthPeriod(_month).end,
    ),
    _ReportPeriod.year => (
      start: DateTime(_month.year),
      end: DateTime(_month.year + 1),
    ),
    _ReportPeriod.custom => _custom ?? monthPeriod(_month),
  };

  Period _prior(Period period) {
    if (_type == _ReportPeriod.custom) {
      final days =
          DateTime.utc(period.end.year, period.end.month, period.end.day)
              .difference(
                DateTime.utc(
                  period.start.year,
                  period.start.month,
                  period.start.day,
                ),
              )
              .inDays;
      return (
        start: DateTime(
          period.start.year,
          period.start.month,
          period.start.day - days,
        ),
        end: period.start,
      );
    }
    final months = switch (_type) {
      _ReportPeriod.quarter => 3,
      _ReportPeriod.year => 12,
      _ => 1,
    };
    return (
      start: DateTime(period.start.year, period.start.month - months),
      end: period.start,
    );
  }

  Future<void> _choosePeriod(_ReportPeriod type) async {
    if (type != _ReportPeriod.custom) {
      setState(() => _type = type);
      return;
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (!mounted || range == null) return;
    setState(() {
      _custom = (
        start: range.start,
        end: DateTime(range.end.year, range.end.month, range.end.day + 1),
      );
      _type = type;
    });
  }

  String _periodLabel(Period period) {
    final dates = DateFormat.yMd('pt_BR');
    final last = DateTime(
      period.end.year,
      period.end.month,
      period.end.day - 1,
    );
    return '${dates.format(period.start)} a ${dates.format(last)}';
  }

  Future<void> _export(
    String format,
    FinanceSummary data,
    Period period,
    Map<int?, Category> categories,
  ) async {
    final lines = <List<String>>[
      ['Período', _periodLabel(period)],
      ['Receitas', formatBrlSum(data.income)],
      ['Despesas', formatBrlSum(data.expense)],
      ['Resultado', formatBrlSum(data.result)],
      [],
      ['Categoria', 'Despesas'],
      for (final category in data.byCategory.entries)
        [
          categories[category.key]?.name ?? 'Sem categoria',
          formatBrlSum(category.value),
        ],
    ];
    try {
      final renderBox = context.findRenderObject() as RenderBox?;
      final shareOrigin = renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size;
      late Uint8List bytes;
      if (format == 'csv') {
        // Quote every cell and neutralize spreadsheet formulas in user text.
        String escape(String cell) {
          final formula = RegExp(r'^\s*[=+\-@]').hasMatch(cell);
          return '"${(formula ? "'$cell" : cell).replaceAll('"', '""')}"';
        }

        bytes = Uint8List.fromList(
          utf8.encode(
            '\uFEFF${lines.map((line) => line.map(escape).join(';')).join('\r\n')}',
          ),
        );
      } else {
        final document = pdf.Document();
        document.addPage(
          pdf.MultiPage(
            maxPages: 100,
            build: (context) => [
              pdf.Header(level: 0, text: 'Relatório financeiro'),
              for (final line in lines) pdf.Paragraph(text: line.join('  •  ')),
            ],
          ),
        );
        bytes = await document.save();
      }
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: format == 'pdf' ? 'application/pdf' : 'text/csv',
          ),
        ],
        fileNameOverrides: ['relatorio-financeiro.$format'],
        subject: 'Relatório financeiro',
        sharePositionOrigin: shareOrigin,
      );
    } catch (error) {
      if (mounted)
        showRecordError(
          context,
          error,
          'Não foi possível exportar o relatório.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(financeHistoryProvider);
    final categories = {
      for (final item
          in ref.watch(allCategoriesProvider()).valueOrNull ?? <Category>[])
        item.id: item,
    };
    final period = _period();
    final prior = _prior(period);
    final summary = history.valueOrNull?.summarize(period);
    final expanded = WindowSizeClass.wide(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Exportar relatório',
            icon: const Icon(Symbols.ios_share_rounded),
            enabled: summary != null && summary.records > 0,
            onSelected: (format) =>
                _export(format, summary!, period, categories),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('Exportar CSV')),
              PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
            ],
          ),
        ],
      ),
      body: AppContent(
        child: ListView(
          key: const PageStorageKey('relatórios'),
          padding: AppLayout.pagePadding(context),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (value, label) in const [
                  (_ReportPeriod.month, 'Mês'),
                  (_ReportPeriod.quarter, 'Trimestre'),
                  (_ReportPeriod.year, 'Ano'),
                  (_ReportPeriod.custom, 'Personalizado'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _type == value,
                    onSelected: (_) => _choosePeriod(value),
                  ),
              ],
            ),
            if (_type == _ReportPeriod.month || _type == _ReportPeriod.quarter)
              MonthPicker(
                month: _month,
                onChanged: (month) => setState(() => _month = month),
              )
            else if (_type == _ReportPeriod.year)
              Row(
                children: [
                  IconButton(
                    tooltip: 'Ano anterior',
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year - 1, _month.month),
                    ),
                    icon: const Icon(Symbols.chevron_left_rounded),
                  ),
                  Text('${_month.year}', style: theme.textTheme.titleSmall),
                  IconButton(
                    tooltip: 'Próximo ano',
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year + 1, _month.month),
                    ),
                    icon: const Icon(Symbols.chevron_right_rounded),
                  ),
                ],
              ),
            Text(_periodLabel(period), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (!expanded &&
                WindowSizeClass.of(context) == WindowSizeClass.compact) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final (index, label) in [
                    'Visão geral',
                    'Categorias',
                    'Evolução',
                  ].indexed)
                    ChoiceChip(
                      label: Text(label),
                      selected: _tab == index,
                      onSelected: (_) => setState(() => _tab = index),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (history.hasError)
              EmptyState(
                title: 'Não foi possível carregar o relatório.',
                compact: true,
                actionLabel: 'Tentar novamente',
                onAction: () {
                  ref.invalidate(financeHistoryProvider);
                },
              )
            else if (summary == null)
              const Center(child: CircularProgressIndicator())
            else if (summary.records == 0)
              const EmptyState(
                title: 'Ainda não há dados neste período.',
                icon: Symbols.bar_chart_rounded,
              )
            else
              _reportContent(
                context,
                history.requireValue,
                period,
                prior,
                summary,
                categories,
              ),
          ],
        ),
      ),
    );
  }

  Widget _reportContent(
    BuildContext context,
    FinanceHistory history,
    Period period,
    Period prior,
    FinanceSummary current,
    Map<int?, Category> categories,
  ) {
    final earlier = history.summarize(prior);
    final comparison = _type == _ReportPeriod.month
        ? 'em ${DateFormat.MMMM('pt_BR').format(prior.start)}'
        : 'no período anterior';
    final overview = LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = constraints.maxWidth >= 540
            ? (constraints.maxWidth - 2 * gap) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, value, old, kind, icon) in [
              (
                'Receitas',
                current.income,
                earlier.income,
                MoneyKind.income,
                Symbols.arrow_upward_rounded,
              ),
              (
                'Despesas',
                current.expense,
                earlier.expense,
                MoneyKind.expense,
                Symbols.arrow_downward_rounded,
              ),
              (
                'Resultado',
                current.result,
                earlier.result,
                MoneyKind.neutral,
                Symbols.balance_rounded,
              ),
            ])
              SizedBox(
                width: width,
                child: _TotalCard(
                  label: label,
                  value: value,
                  previous: old,
                  kind: kind,
                  icon: icon,
                  comparison: comparison,
                ),
              ),
          ],
        );
      },
    );
    final byCategory = AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Despesas por categoria',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          CategoryChart(
            summary: current,
            categories: categories,
            showBars: true,
            onCategory: (id) => widget.onCategory(period, id),
          ),
        ],
      ),
    );
    final series = _series(history, period);
    final bars = _TrendsChart(points: series);
    final line = _TrendsChart(points: series, line: true);
    if (WindowSizeClass.of(context) == WindowSizeClass.compact) {
      return switch (_tab) {
        1 => byCategory,
        2 => Column(children: [bars, const SizedBox(height: 16), line]),
        _ => overview,
      };
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        overview,
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 650
              ? Column(children: [byCategory, const SizedBox(height: 16), bars])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: byCategory),
                    const SizedBox(width: 16),
                    Expanded(flex: 7, child: bars),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        line,
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.previous,
    required this.kind,
    required this.icon,
    required this.comparison,
  });
  final String label, comparison;
  final BigInt value, previous;
  final MoneyKind kind;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.of(context);
    final change = previous == BigInt.zero
        ? null
        : (value - previous) * BigInt.from(100) ~/ previous.abs();
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            icon,
            color: switch (kind) {
              MoneyKind.income => dark.income,
              MoneyKind.expense => dark.expense,
              _ => null,
            },
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          MoneyText.total(value, kind: kind, signed: true),
          const SizedBox(height: 4),
          Text(
            change == null
                ? 'Sem base para comparação'
                : change == BigInt.zero
                ? 'Mesmo valor que $comparison'
                : '${change.isNegative ? '↓' : '↑'} ${change.abs()}% a ${change.isNegative ? 'menos' : 'mais'} que $comparison',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

typedef _Point = ({DateTime date, FinanceSummary data});

List<_Point> _series(FinanceHistory history, Period period) {
  final months =
      (period.end.year - period.start.year) * 12 +
      period.end.month -
      period.start.month +
      1;
  final step = math.max(1, (months / 18).ceil());
  final series = <_Point>[];
  var start = period.start;
  while (start.isBefore(period.end)) {
    final next = DateTime(start.year, start.month + step);
    final end = next.isBefore(period.end) ? next : period.end;
    series.add((
      date: start,
      data: history.summarize((start: start, end: end)),
    ));
    start = end;
  }
  return series;
}

class _TrendsChart extends StatelessWidget {
  const _TrendsChart({required this.points, this.line = false});
  final List<_Point> points;
  final bool line;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final theme = Theme.of(context);
    final hidden = PreferencesScope.of(context)?.discreet ?? false;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    final labels = DateFormat.MMM('pt_BR');
    final chartLabels = FlTitlesData(
      leftTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      topTitles: const AxisTitles(),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: math.max(1, (points.length / 5).ceil()).toDouble(),
          reservedSize: 28,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            return i < 0 || i >= points.length
                ? const SizedBox.shrink()
                : Text(
                    labels.format(points[i].date),
                    style: theme.textTheme.labelSmall,
                  );
          },
        ),
      ),
    );
    final accumulated = <BigInt>[];
    var running = BigInt.zero;
    for (final point in points) {
      running += point.data.result;
      accumulated.add(running);
    }
    final grid = FlGridData(
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => FlLine(color: theme.colorScheme.outline),
    );
    String tooltip(BigInt total) => hidden ? '••••' : formatBrlSum(total);
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            line ? 'Saldo acumulado no período' : 'Receitas e despesas por mês',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Semantics(
            label: line
                ? 'Gráfico do saldo acumulado no período'
                : 'Gráfico de receitas e despesas por mês',
            child: SizedBox(
              height: 208,
              child: line
                  ? LineChart(
                      LineChartData(
                        titlesData: chartLabels,
                        gridData: grid,
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: math.max(1, points.length - 1).toDouble(),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItems: (spots) => [
                              for (final spot in spots)
                                LineTooltipItem(
                                  tooltip(accumulated[spot.x.toInt()]),
                                  TextStyle(color: theme.colorScheme.surface),
                                ),
                            ],
                            getTooltipColor: (_) => theme.colorScheme.onSurface,
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (final (index, value) in accumulated.indexed)
                                FlSpot(
                                  index.toDouble(),
                                  value.toDouble() / 100,
                                ),
                            ],
                            color: theme.colorScheme.primary,
                            barWidth: 3,
                            isCurved: true,
                            preventCurveOverShooting: true,
                            dotData: FlDotData(show: points.length <= 12),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.colorScheme.primary.withValues(
                                    alpha: .2,
                                  ),
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      duration: motion,
                    )
                  : BarChart(
                      BarChartData(
                        titlesData: chartLabels,
                        gridData: grid,
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipColor: (_) => theme.colorScheme.onSurface,
                            getTooltipItem:
                                (group, groupIndex, rod, rodIndex) =>
                                    BarTooltipItem(
                                      tooltip(
                                        rodIndex == 0
                                            ? points[group.x].data.income
                                            : points[group.x].data.expense,
                                      ),
                                      TextStyle(
                                        color: theme.colorScheme.surface,
                                      ),
                                    ),
                          ),
                        ),
                        barGroups: [
                          for (final (index, value) in points.indexed)
                            BarChartGroupData(
                              x: index,
                              barsSpace: 4,
                              barRods: [
                                for (final (amount, color) in [
                                  (value.data.income, tokens.income),
                                  (value.data.expense, tokens.expense),
                                ])
                                  BarChartRodData(
                                    toY: amount.toDouble() / 100,
                                    color: color,
                                    width: points.length > 8 ? 5 : 10,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      swapAnimationDuration: motion,
                    ),
            ),
          ),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: line
                ? [
                    Text('Saldo acumulado', style: theme.textTheme.bodySmall),
                    MoneyText.total(running),
                  ]
                : [
                    Text(
                      '↑ Receitas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.incomeText,
                      ),
                    ),
                    Text(
                      '↓ Despesas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.expenseText,
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}
