import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/app_preferences.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/balance_card.dart';
import '../../../../core/design/components.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../bills/presentation/providers/bill_providers.dart';
import '../../../budgets/budget_data.dart';
import '../../../budgets/budgets_screen.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../reports/category_chart.dart';
import '../../../reports/finance_summary.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenBills,
    required this.onSettings,
    required this.onNew,
    required this.onReports,
    required this.onPlanning,
    required this.onTransactions,
  });

  final VoidCallback onOpenBills,
      onSettings,
      onReports,
      onPlanning,
      onTransactions;
  final ValueChanged<String> onNew;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = _selectedMonth ?? firstOfMonth(now);
    final accounts = ref.watch(allAccountsProvider);
    final bills = ref.watch(allBillsProvider);
    final transactions = ref.watch(allTransactionsProvider);
    final history = ref.watch(financeHistoryProvider);
    final budgets = ref.watch(budgetsProvider);
    final categoryList = ref.watch(allCategoriesProvider());
    final theme = Theme.of(context);
    final size = WindowSizeClass.of(context);
    final wide = WindowSizeClass.wide(context);
    final name = PreferencesScope.of(context)?.name ?? '';
    final categories = {
      for (final item in categoryList.valueOrNull ?? <Category>[])
        item.id: item,
    };
    final names = {
      for (final item in accounts.valueOrNull ?? []) item.id: item.name,
    };
    final overview = history.valueOrNull?.months[month] ?? FinanceSummary();
    final balance = accounts.valueOrNull
        ?.where((item) => item.isActive)
        .fold(
          BigInt.zero,
          (sum, item) => sum + BigInt.from(item.currentBalanceCents),
        );
    final upcoming =
        (bills.valueOrNull ?? [])
            .where((item) => item.status == 'pending')
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final pending = (transactions.valueOrNull ?? [])
        .where((item) => item.status == 'pending')
        .toList();
    final recent = (transactions.valueOrNull ?? [])
        .where((item) => firstOfMonth(item.date) == month)
        .take(5);
    final planned = BudgetProgress.forMonth(
      budgets.valueOrNull ?? [],
      month,
      history.valueOrNull ?? FinanceHistory(),
    );
    final failed =
        accounts.hasError ||
        bills.hasError ||
        transactions.hasError ||
        history.hasError ||
        budgets.hasError ||
        categoryList.hasError;
    final loading =
        !accounts.hasValue ||
        !bills.hasValue ||
        !transactions.hasValue ||
        !history.hasValue ||
        !budgets.hasValue ||
        !categoryList.hasValue;
    final shortcuts = _QuickActions(
      onNew: widget.onNew,
      insideCard: size == WindowSizeClass.medium,
    );
    final essentials = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthPicker(
          month: month,
          limitFuture: true,
          onChanged: (value) => setState(() => _selectedMonth = value),
        ),
        const SizedBox(height: 4),
        BalanceCard(
          balance: balance,
          income: overview.income,
          expense: overview.expense,
          shortcuts: size == WindowSizeClass.medium ? shortcuts : null,
        ),
        if (size != WindowSizeClass.medium) ...[
          const SizedBox(height: 16),
          shortcuts,
        ],
        if (history.hasValue && !failed) ...[
          const SizedBox(height: 16),
          AppSurface(child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text('Resultado do mês', style: theme.textTheme.titleSmall),
              MoneyText.total(overview.result),
            ],
          )),
        ],
      ],
    );
    final cleared = _Section(
      title: 'Para onde foi seu dinheiro',
      action: 'Ver tudo',
      onAction: widget.onReports,
      child: AppSurface(
        child: CategoryChart(
          summary: overview,
          categories: categories,
          limit: 5,
        ),
      ),
    );
    final plannedSection = _Section(
      title: 'Orçamentos em andamento',
      action: 'Planejar',
      onAction: widget.onPlanning,
      child: planned.isEmpty
          ? AppSurface(
              child: Text(
                'Defina limites para acompanhar seus gastos neste mês.',
                style: theme.textTheme.bodySmall,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                Widget card(BudgetProgress item) => BudgetCard(
                  progress: item,
                  category: categories[item.row.categoryId],
                  compact: true,
                  onTap: widget.onPlanning,
                );
                if (size == WindowSizeClass.compact) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final item in planned)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(width: 160, child: card(item)),
                          ),
                      ],
                    ),
                  );
                }
                final columns = constraints.maxWidth >= 530
                    ? 3
                    : constraints.maxWidth >= 340
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final item in planned)
                      SizedBox(width: width, child: card(item)),
                  ],
                );
              },
            ),
    );
    final scheduled = [
      for (final item in upcoming)
        (
          title: item.name,
          date: item.dueDate,
          cents: item.amountCents,
          open: widget.onOpenBills,
        ),
      for (final item in pending)
        (
          title: item.description ?? 'Lançamento agendado',
          date: item.date,
          cents: item.amountCents,
          open: widget.onTransactions,
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final due = _Section(
      title: 'Próximos vencimentos',
      child: AppSurface(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            if (scheduled.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Nenhum vencimento pendente.'),
              ),
            for (final item in scheduled.take(3))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AppIcon(Symbols.event_rounded),
                title: Text(item.title),
                subtitle: Text(DateFormat.yMd('pt_BR').format(item.date)),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: MoneyText(
                    item.cents,
                    alignment: Alignment.centerRight,
                  ),
                ),
                onTap: item.open,
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: widget.onOpenBills,
                child: const Text('Ver contas a pagar'),
              ),
            ),
          ],
        ),
      ),
    );
    final latest = _Section(
      title: 'Últimos lançamentos',
      action: 'Ver todos',
      onAction: widget.onTransactions,
      child: AppSurface(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: recent.isEmpty
            ? EmptyState(
                title: 'Sem lançamentos no mês',
                icon: Symbols.receipt_long_rounded,
                compact: true,
                actionLabel: transactions.valueOrNull?.isEmpty == true
                    ? 'Adicionar primeiro lançamento'
                    : 'Novo lançamento',
                onAction: () => widget.onNew('expense'),
              )
            : Column(
                children: [
                  for (final entry in recent)
                    TransactionTile(
                      transaction: entry,
                      accountName: names[entry.accountId] ?? 'Conta',
                      category: categories[entry.categoryId],
                      destinationAccountName: names[entry.destinationAccountId],
                      onTap: widget.onTransactions,
                    ),
                ],
              ),
      ),
    );

    Widget loadState() => failed
        ? EmptyState(
            title: 'Não foi possível carregar o resumo.',
            compact: true,
            actionLabel: 'Tentar novamente',
            onAction: () {
              ref.invalidate(allAccountsProvider);
              ref.invalidate(allBillsProvider);
              ref.invalidate(allTransactionsProvider);
              ref.invalidate(financeHistoryProvider);
              ref.invalidate(budgetsProvider);
              ref.invalidate(allCategoriesProvider());
            },
          )
        : const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );

    if (wide) {
      return Scaffold(
        appBar: AppBar(title: Text(name.isEmpty ? 'Início' : 'Olá, $name')),
        body: AppContent(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.margin(context),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: ListView(
                    key: const PageStorageKey('início-principal'),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      essentials,
                      const SizedBox(height: 20),
                      if (failed || loading)
                        loadState()
                      else ...[
                        cleared,
                        plannedSection,
                      ],
                    ],
                  ),
                ),
                SizedBox(width: size.gutter),
                Expanded(
                  flex: 4,
                  child: ListView(
                    key: const PageStorageKey('início-lateral'),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (!failed && !loading) ...[due, latest],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: AppContent(
        child: CustomScrollView(
          key: const PageStorageKey('início-principal'),
          slivers: [
            SliverAppBar(
            pinned: MediaQuery.sizeOf(context).height < 480,
            floating: true,
              title: Text(
                name.isEmpty ? 'Início' : 'Olá, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: 'Ajustes',
                  onPressed: widget.onSettings,
                  icon: const Icon(Symbols.settings_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: AppLayout.pagePadding(context),
              sliver: SliverList.list(
                children: [
                  essentials,
                  const SizedBox(height: 20),
                  if (failed || loading)
                    loadState()
                  else if (size == WindowSizeClass.medium)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = (constraints.maxWidth - 16) / 2;
                        if (width < 230)
                          return Column(
                            children: [cleared, plannedSection, due, latest],
                          );
                        return Wrap(
                          spacing: 16,
                          children: [
                            for (final section in [
                              cleared,
                              plannedSection,
                              due,
                              latest,
                            ])
                              SizedBox(width: width, child: section),
                          ],
                        );
                      },
                    )
                  else ...[
                    cleared,
                    plannedSection,
                    due,
                    latest,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.action,
    this.onAction,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (action != null)
              TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNew, required this.insideCard});
  final ValueChanged<String> onNew;
  final bool insideCard;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(12) > 16
            ? 2
            : 3;
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, type, icon, color) in [
              (
                'Despesa',
                'expense',
                Symbols.arrow_downward_rounded,
                tokens.expenseText,
              ),
              (
                'Receita',
                'income',
                Symbols.arrow_upward_rounded,
                tokens.incomeText,
              ),
              (
                'Transferir',
                'transfer',
                Symbols.swap_horiz_rounded,
                theme.colorScheme.primary,
              ),
            ])
              SizedBox(
                width: width,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      AppLayout.controlRadius,
                    ),
                    onTap: () => onNew(type),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: insideCard
                                ? AppColors.inkOnGradient
                                : color.withValues(alpha: .14),
                            child: Icon(icon, color: color, weight: 500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: insideCard
                                  ? AppColors.inkOnGradient
                                  : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
