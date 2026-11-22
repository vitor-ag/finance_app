import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_preferences.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components.dart';
import '../../budgets/budgets_screen.dart';
import '../../reports/finance_summary.dart';
import '../domain/investment_portfolio.dart';
import 'investment_providers.dart';

class InvestmentReportScreen extends ConsumerStatefulWidget {
  const InvestmentReportScreen({super.key, this.investmentId});

  final int? investmentId;

  @override
  ConsumerState<InvestmentReportScreen> createState() =>
      _InvestmentReportScreenState();
}

class _InvestmentReportScreenState
    extends ConsumerState<InvestmentReportScreen> {
  DateTime _month = firstOfMonth(DateTime.now());
  late int _investmentId = widget.investmentId ?? 0;

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(investmentPortfolioProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Relatório mensal')),
      body: AppContent(
        maxWidth: AppLayout.maxReading,
        child: portfolio.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            title: 'Não foi possível calcular o relatório.',
            actionLabel: 'Tentar novamente',
            onAction: () => ref.invalidate(investmentPortfolioProvider),
          ),
          data: (data) {
            if (data.positions.isEmpty) {
              return const EmptyState(
                title: 'Cadastre um investimento para acompanhar a evolução.',
              );
            }
            final id =
                data.positions.any(
                  (item) => item.investment.id == _investmentId,
                )
                ? _investmentId
                : 0;
            final months = [
              for (var offset = 5; offset >= 0; offset--)
                DateTime(_month.year, _month.month - offset),
            ];
            final reports = [
              for (final month in months)
                data.summarize(month, investmentId: id == 0 ? null : id),
            ];
            final report = reports.last;
            return ListView(
              padding: AppLayout.pagePadding(context),
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey(id),
                  initialValue: id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Investimento'),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Carteira completa'),
                    ),
                    for (final item in data.positions)
                      DropdownMenuItem(
                        value: item.investment.id,
                        child: Text(
                          item.investment.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _investmentId = value ?? 0),
                ),
                const SizedBox(height: 8),
                MonthPicker(
                  month: _month,
                  limitFuture: true,
                  onChanged: (value) => setState(() => _month = value),
                ),
                const SizedBox(height: 8),
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Resultado líquido do mês',
                        style: theme.textTheme.titleMedium,
                      ),
                      MoneyText.total(
                        report.netResult,
                        kind: _resultKind(report.netResult),
                        emphasis: true,
                        signed: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Variação registrada nas atualizações da posição, descontadas as deduções dos resgates.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      _ReportValue(
                        'Variação de valor',
                        report.variation,
                        signed: true,
                      ),
                      _ReportValue(
                        'Deduções nos resgates',
                        report.redemptionDeductions,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Composição do patrimônio',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _ReportValue('Saldo de abertura', report.opening),
                      if (report.imported != BigInt.zero)
                        _ReportValue(
                          'Posições iniciais registradas',
                          report.imported,
                        ),
                      _ReportValue('Aportes', report.contributed),
                      _ReportValue('Resgates brutos', report.redeemed),
                      if (report.redeemed != BigInt.zero)
                        _ReportValue(
                          'Resgates creditados em conta',
                          report.credited,
                        ),
                      const Divider(),
                      _ReportValue('Saldo no fim do período', report.closing),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ResultHistory(months: months, reports: reports),
              ],
            );
          },
        ),
      ),
    );
  }
}

MoneyKind _resultKind(BigInt amount) => amount.isNegative
    ? MoneyKind.expense
    : amount == BigInt.zero
    ? MoneyKind.neutral
    : MoneyKind.income;

class _ReportValue extends StatelessWidget {
  const _ReportValue(this.label, this.value, {this.signed = false});

  final String label;
  final BigInt value;
  final bool signed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(flex: 3, child: Text(label)),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: MoneyText.total(
            value,
            kind: signed ? _resultKind(value) : MoneyKind.neutral,
            signed: signed,
            alignment: Alignment.centerRight,
          ),
        ),
      ],
    ),
  );
}

class _ResultHistory extends StatelessWidget {
  const _ResultHistory({required this.months, required this.reports});

  final List<DateTime> months;
  final List<InvestmentMonth> reports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hidden = PreferencesScope.of(context)?.discreet ?? false;
    final palette = AppColors.of(context);
    final maximum = reports.fold(
      BigInt.one,
      (maximum, month) =>
          month.netResult.abs() > maximum ? month.netResult.abs() : maximum,
    );
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resultado nos últimos 6 meses',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final (index, report) in reports.indexed) ...[
            _ReportValue(
              DateFormat.yMMM('pt_BR').format(months[index]),
              report.netResult,
              signed: true,
            ),
            if (!hidden && report.netResult != BigInt.zero)
              ExcludeSemantics(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: report.netResult.abs() / maximum,
                  child: Container(
                    height: 4,
                    color: report.netResult.isNegative
                        ? palette.expense
                        : palette.income,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
