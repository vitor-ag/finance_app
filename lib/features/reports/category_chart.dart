import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/design/category_style.dart';
import '../../core/design/components.dart';
import '../categories/domain/entities/category.dart';
import 'finance_summary.dart';

class CategoryChart extends StatefulWidget {
  const CategoryChart({
    super.key,
    required this.summary,
    required this.categories,
    this.limit,
    this.onCategory,
    this.showBars = false,
  });

  final FinanceSummary summary;
  final Map<int?, Category> categories;
  final int? limit;
  final bool showBars;
  final ValueChanged<int?>? onCategory;

  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = widget.summary.byCategory.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    final visible = entries.take(widget.limit ?? entries.length).toList();
    if (visible.isEmpty)
      return const EmptyState(
        title: 'Sem despesas neste período',
        icon: Symbols.pie_chart_rounded,
        compact: true,
      );
    final rest = entries
        .skip(visible.length)
        .fold(BigInt.zero, (sum, entry) => sum + entry.value);
    final rows = [
      for (final entry in visible)
        (
          id: entry.key,
          value: entry.value,
          name: widget.categories[entry.key]?.name ?? 'Sem categoria',
          style: categoryStyle(context, widget.categories[entry.key]),
          isRest: false,
        ),
      if (rest > BigInt.zero)
        (
          id: null,
          value: rest,
          name: 'Demais categorias',
          style: (Symbols.more_horiz_rounded, theme.colorScheme.outline),
          isRest: true,
        ),
    ];
    final total = widget.summary.expense;
    final active = _touched != null && _touched! < rows.length
        ? rows[_touched!]
        : null;
    final chart = SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: PieChart(
              PieChartData(
                sectionsSpace: rows.length == 1 ? 0 : 3,
                centerSpaceRadius: 56,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    final index = response?.touchedSection?.touchedSectionIndex;
                    final selected =
                        event.isInterestedForInteractions &&
                            index != null &&
                            index >= 0
                        ? index
                        : null;
                    if (_touched != selected)
                      setState(() => _touched = selected);
                  },
                ),
                sections: [
                  for (final (index, entry) in rows.indexed)
                    PieChartSectionData(
                      color: entry.style.$2,
                      value: entry.value / total,
                      radius: index == _touched ? 26 : 22,
                      showTitle: false,
                    ),
                ],
              ),
              swapAnimationDuration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
            ),
          ),
          IgnorePointer(
            child: SizedBox(
              width: 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    active?.name ?? 'Total',
                    style: theme.textTheme.labelMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  MoneyText.total(
                    active?.value ?? total,
                    alignment: Alignment.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in rows)
          InkWell(
            onTap: widget.onCategory == null || entry.isRest
                ? null
                : () => widget.onCategory!(entry.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppIcon(entry.style.$1, color: entry.style.$2),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.name,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: MoneyText.total(
                          entry.value,
                          alignment: Alignment.centerRight,
                        ),
                      ),
                    ],
                  ),
                  if (widget.showBars) ...[
                    const SizedBox(height: 4),
                    BudgetProgressBar(
                      progress: entry.value / total,
                      color: entry.style.$2,
                      label: '${entry.name}, proporção dos gastos',
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 380
          ? Row(
              children: [
                chart,
                const SizedBox(width: 16),
                Expanded(child: legend),
              ],
            )
          : Column(children: [chart, const SizedBox(height: 12), legend]),
    );
  }
}
