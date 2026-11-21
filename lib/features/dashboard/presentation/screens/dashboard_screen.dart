import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calendar.dart';
import '../../../../core/money.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../bills/presentation/providers/bill_providers.dart';
import '../../domain/dashboard_overview.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.onOpenBills});

  final VoidCallback onOpenBills;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  late final AppLifecycleListener _lifecycle;
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => setState(() {}));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _changeMonth(DateTime month, int offset, DateTime current) {
    final selected = DateTime(month.year, month.month + offset);
    setState(() => _selectedMonth = selected == current ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final month = _selectedMonth ?? current;
    final accounts = ref.watch(allAccountsProvider);
    final bills = ref.watch(allBillsProvider);
    final transactions = ref.watch(dashboardTransactionsProvider(month));
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasError =
        accounts.hasError || bills.hasError || transactions.hasError;
    final isReady =
        accounts.hasValue && bills.hasValue && transactions.hasValue;
    final overview = isReady
        ? DashboardOverview.calculate(
            accounts: accounts.requireValue,
            transactions: transactions.requireValue,
            bills: bills.requireValue,
            today: now,
          )
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Início'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo atual',
                  style: text.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  overview == null
                      ? '—'
                      : formatBrlSum(overview.activeBalanceCents),
                  style: text.headlineMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contas ativas',
                  style: text.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton.outlined(
                tooltip: 'Mês anterior',
                onPressed: () => _changeMonth(month, -1, current),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_months[month.month - 1]} de ${month.year}',
                  textAlign: TextAlign.center,
                  style: text.titleMedium,
                ),
              ),
              IconButton.outlined(
                tooltip: 'Próximo mês',
                onPressed: month.isBefore(current)
                    ? () => _changeMonth(month, 1, current)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasError)
            Column(
              children: [
                const Text('Não foi possível carregar o resumo financeiro.'),
                TextButton(
                  onPressed: () {
                    ref.invalidate(allAccountsProvider);
                    ref.invalidate(allBillsProvider);
                    ref.invalidate(dashboardTransactionsProvider(month));
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            )
          else if (overview == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            _MetricPair(
              first: _Metric(
                title: 'Entradas',
                value: formatBrlSum(overview.incomeCents),
                icon: Icons.south_west,
                color: colors.primary,
              ),
              second: _Metric(
                title: 'Saídas',
                value: formatBrlSum(overview.expenseCents),
                icon: Icons.north_east,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 8),
            _Metric(
              title: 'Resultado do mês',
              value: formatBrlSum(overview.resultCents),
              icon: Icons.equalizer,
              color: overview.resultCents.isNegative
                  ? colors.error
                  : colors.primary,
            ),
            const SizedBox(height: 24),
            Text('Contas a pagar', style: text.titleLarge),
            const SizedBox(height: 8),
            _MetricPair(
              first: _Metric(
                title: 'Vencidas (${overview.overdueCount})',
                value: formatBrlSum(overview.overdueCents),
                icon: Icons.event_busy_outlined,
                color: colors.error,
              ),
              second: _Metric(
                title: 'A vencer (${overview.upcomingCount})',
                value: formatBrlSum(overview.upcomingCents),
                icon: Icons.event_outlined,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (overview.pendingBills.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Nenhuma conta pendente.'),
              )
            else
              for (final bill in overview.pendingBills.take(3))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(bill.name),
                  subtitle: Text(
                    '${calendarDate(bill.dueDate).isBefore(calendarDate(now)) ? 'Vencida em' : 'Vence em'} '
                    '${bill.dueDate.day}/${bill.dueDate.month}/${bill.dueDate.year}',
                  ),
                  trailing: Text(
                    formatBrl(bill.amountCents),
                    style: text.titleSmall,
                  ),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onOpenBills,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ver contas a pagar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPair extends StatelessWidget {
  const _MetricPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 310 ||
            MediaQuery.textScalerOf(context).scale(16) > 23) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 8), second],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 8),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
