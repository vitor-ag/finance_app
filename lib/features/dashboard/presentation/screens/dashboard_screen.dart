import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/app_preferences.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/balance_card.dart';
import '../../../../core/design/category_style.dart';
import '../../../../core/design/components.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../budgets/budget_data.dart';
import '../../../budgets/budgets_screen.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../credit_cards/presentation/credit_card_providers.dart';
import '../../../forecast/domain/cash_forecast.dart';
import '../../../forecast/presentation/cash_event_tile.dart';
import '../../../forecast/presentation/cash_forecast_provider.dart';
import '../../../reports/category_chart.dart';
import '../../../reports/finance_summary.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenBills,
    required this.onOpenCards,
    required this.onOpenCard,
    required this.onOpenRecurrences,
    required this.onOpenForecast,
    required this.onOpenCategory,
    required this.onSettings,
    required this.onNew,
    required this.onReports,
    required this.onPlanning,
    required this.onTransactions,
  });

  final VoidCallback onOpenBills,
      onOpenCards,
      onOpenRecurrences,
      onOpenForecast,
      onSettings,
      onReports,
      onPlanning,
      onTransactions;
  final ValueChanged<String> onNew;
  final ValueChanged<int> onOpenCard;
  final void Function(Period, int?) onOpenCategory;

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
    final forecast = ref.watch(cashForecastProvider);
    final transactions = ref.watch(allTransactionsProvider);
    final purchases = ref.watch(cardPurchasesProvider).valueOrNull ?? [];
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
    final recent = (transactions.valueOrNull ?? [])
        .where((item) => firstOfMonth(item.date) == month)
        .take(5);
    final expenses =
        [
          for (final item in transactions.valueOrNull ?? [])
            if (item.type == 'expense' &&
                item.status == 'paid' &&
                firstOfMonth(item.date) == month)
              (
                title: transactionTitle(item, categories[item.categoryId]),
                cents: item.amountCents,
                date: item.date,
                categoryId: item.categoryId,
                cardId: null as int?,
              ),
          for (final item in purchases)
            if (firstOfMonth(item.purchaseDate) == month)
              (
                title: item.description,
                cents: item.amountCents,
                date: item.purchaseDate,
                categoryId: item.categoryId,
                cardId: item.cardId,
              ),
        ]..sort((a, b) {
          final byAmount = b.cents.compareTo(a.cents);
          return byAmount == 0 ? b.date.compareTo(a.date) : byAmount;
        });
    final planned = BudgetProgress.forMonth(
      budgets.valueOrNull ?? [],
      month,
      history.valueOrNull ?? FinanceHistory(),
    );
    final failed =
        accounts.hasError ||
        transactions.hasError ||
        history.hasError ||
        budgets.hasError ||
        categoryList.hasError;
    final loading =
        !accounts.hasValue ||
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (label, icon, open) in [
              ('Previsão', Symbols.timeline_rounded, widget.onOpenForecast),
              ('Contas a pagar', Symbols.event_rounded, widget.onOpenBills),
              ('Cartões', Symbols.credit_card_rounded, widget.onOpenCards),
              (
                'Recorrências',
                Symbols.repeat_rounded,
                widget.onOpenRecurrences,
              ),
            ])
              ActionChip(
                avatar: Icon(icon, size: 18),
                label: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                backgroundColor: label == 'Previsão'
                    ? theme.colorScheme.primaryContainer
                    : null,
                onPressed: open,
              ),
          ],
        ),
        if (history.hasValue && !failed) ...[
          const SizedBox(height: 16),
          AppSurface(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text('Resultado do mês', style: theme.textTheme.titleSmall),
                MoneyText.total(overview.result),
              ],
            ),
          ),
        ],
      ],
    );
    final cleared = _Section(
      title: 'Gastos por categoria',
      action: 'Ver relatórios',
      onAction: widget.onReports,
      child: AppSurface(
        child: CategoryChart(
          summary: overview,
          categories: categories,
          limit: 5,
          onCategory: (id) => widget.onOpenCategory(monthPeriod(month), id),
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
    final forecastPreview = _Section(
      title: 'Previsão de 30 dias',
      child: forecast.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => AppSurface(
          child: TextButton(
            onPressed: () => ref.invalidate(cashForecastProvider),
            child: const Text('Recarregar previsão'),
          ),
        ),
        data: (data) => _ForecastPreview(
          projection: data.total,
          onOpen: widget.onOpenForecast,
        ),
      ),
    );
    final due = _Section(
      title: 'Próximos vencimentos',
      action: 'Ver contas a pagar',
      onAction: widget.onOpenBills,
      child: forecast.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) =>
            const AppSurface(child: Text('Vencimentos indisponíveis.')),
        data: (data) {
          final upcoming = data.total.days
              .expand((day) => day.movements)
              .where((item) => !item.event.isTransfer && item.delta.isNegative)
              .map((item) => item.event)
              .take(3)
              .toList();
          return AppSurface(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: upcoming.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Nenhum vencimento nos próximos 30 dias.'),
                  )
                : Column(
                    children: [
                      for (final item in upcoming)
                        CashEventTile(
                          event: item,
                          delta: item.delta,
                          today: data.today,
                          showDate: true,
                          onTap: switch (item.source) {
                            CashEventSource.bill ||
                            CashEventSource.repeatingBill => widget.onOpenBills,
                            CashEventSource.statement =>
                              () => widget.onOpenCard(item.cardId!),
                            CashEventSource.scheduled => widget.onTransactions,
                            CashEventSource.recurrence =>
                              widget.onOpenRecurrences,
                          },
                        ),
                    ],
                  ),
          );
        },
      ),
    );
    final biggestExpenses = _Section(
      title: 'Maiores gastos',
      action: 'Ver lançamentos',
      onAction: widget.onTransactions,
      child: AppSurface(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: expenses.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Nenhum gasto no mês selecionado.'),
              )
            : Column(
                children: [
                  for (final expense in expenses.take(3))
                    _ExpenseRow(
                      title: expense.title,
                      cents: expense.cents,
                      category: categories[expense.categoryId],
                      onTap: expense.cardId == null
                          ? () => widget.onOpenCategory(
                              monthPeriod(month),
                              expense.categoryId,
                            )
                          : () => widget.onOpenCard(expense.cardId!),
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
              ref.invalidate(cashForecastProvider);
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
                      forecastPreview,
                      due,
                      if (!failed && !loading) ...[biggestExpenses, latest],
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
                  forecastPreview,
                  due,
                  if (failed || loading)
                    loadState()
                  else if (size == WindowSizeClass.medium)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = (constraints.maxWidth - 16) / 2;
                        if (width < 230) {
                          return Column(
                            children: [
                              biggestExpenses,
                              cleared,
                              plannedSection,
                              latest,
                            ],
                          );
                        }
                        return Wrap(
                          spacing: 16,
                          children: [
                            for (final section in [
                              biggestExpenses,
                              cleared,
                              plannedSection,
                              latest,
                            ])
                              SizedBox(width: width, child: section),
                          ],
                        );
                      },
                    )
                  else ...[
                    biggestExpenses,
                    cleared,
                    plannedSection,
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

class _ForecastPreview extends StatelessWidget {
  const _ForecastPreview({required this.projection, required this.onOpen});

  final CashProjection projection;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hidden = PreferencesScope.of(context)?.discreet ?? false;
    final dates = DateFormat.Md('pt_BR');
    final last = projection.days.last;
    return AppSurface(
      onTap: onOpen,
      child: Row(
        children: [
          const AppIcon(Symbols.timeline_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo previsto em ${dates.format(last.date)}',
                  style: theme.textTheme.bodySmall,
                ),
                MoneyText.total(
                  last.closing,
                  style: theme.textTheme.headlineSmall,
                  kind: last.closing.isNegative
                      ? MoneyKind.expense
                      : MoneyKind.neutral,
                ),
                if (projection.firstNegativeDay case final day? when !hidden)
                  Text(
                    'Saldo negativo previsto em ${dates.format(day.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.of(context).expenseText,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Symbols.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.title,
    required this.cents,
    required this.category,
    required this.onTap,
  });

  final String title;
  final int cents;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = categoryStyle(context, category);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final amount = MoneyText(
      cents,
      kind: MoneyKind.expense,
      alignment: largeText ? Alignment.centerLeft : Alignment.centerRight,
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppIcon(icon, color: color),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category?.name ?? 'Sem categoria'),
          if (largeText) amount,
        ],
      ),
      trailing: largeText
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 112),
              child: amount,
            ),
      onTap: onTap,
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
