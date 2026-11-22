import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/calendar.dart';
import '../../../../core/design/app_preferences.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/category_style.dart';
import '../../../../core/design/components.dart';
import '../../../../core/money.dart';
import '../../../../core/widgets/record_actions.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../bills/presentation/providers/bill_providers.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../credit_cards/presentation/credit_card_providers.dart';
import '../../../credit_cards/presentation/credit_cards_screen.dart';
import '../../../reports/finance_summary.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_revision.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_tile.dart';

enum _EntryAction { edit, duplicate, delete, revisions }

enum _EntryPeriod { all, today, week, month, previous, custom }

enum _Order { date, description, category, account, value }

typedef _Filters = ({
  String? type,
  Set<int> accounts,
  Set<int?> categories,
  int? min,
  int? max,
});
const _emptyFilters = (
  type: null,
  accounts: <int>{},
  categories: <int?>{},
  min: null,
  max: null,
);

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _showTrash = false;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  _EntryPeriod _period = _EntryPeriod.all;
  Period? _custom;
  _Filters _filters = _emptyFilters;
  int? _selected;
  _Order _order = _Order.date;
  bool _ascending = false;
  bool _showInlineFilters = false;
  int? _highlighted;
  Timer? _highlightTimer;

  void highlight(int id) {
    _highlightTimer?.cancel();
    setState(() => _highlighted = id);
    _highlightTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _highlighted = null);
    });
  }

  void focusSearch() {
    if (_showTrash) setState(() => _showTrash = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void openCategory(Period period, int? category) {
    setState(() {
      _showTrash = false;
      _period = _EntryPeriod.custom;
      _custom = period;
      _search.clear();
      _filters = (
        type: 'expense',
        accounts: <int>{},
        categories: {category},
        min: null,
        max: null,
      );
      _selected = null;
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Period? get _range {
    final now = calendarDate(DateTime.now());
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return switch (_period) {
      _EntryPeriod.today => (start: now, end: tomorrow),
      _EntryPeriod.week => (
        start: DateTime(now.year, now.month, now.day - 6),
        end: tomorrow,
      ),
      _EntryPeriod.month => monthPeriod(now),
      _EntryPeriod.previous => monthPeriod(DateTime(now.year, now.month - 1)),
      _EntryPeriod.custom => _custom,
      _EntryPeriod.all => null,
    };
  }

  Future<void> _choosePeriod(_EntryPeriod period) async {
    if (period != _EntryPeriod.custom) {
      setState(() => _period = period);
      return;
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (!mounted || range == null) return;
    setState(() {
      _period = period;
      _custom = (
        start: range.start,
        end: DateTime(range.end.year, range.end.month, range.end.day + 1),
      );
    });
  }

  Future<void> _showActions(
    Transaction entry, {
    required bool isBillPayment,
  }) async {
    if (_showTrash) {
      await _changeTrashStatus(entry, restore: true);
      return;
    }
    final action = await showAppBottomSheet<_EntryAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (isBillPayment)
              ListTile(
                leading: const Icon(Symbols.receipt_long_rounded),
                title: Text(
                  entry.type == 'card_payment'
                      ? 'Pagamento de fatura'
                      : entry.isInvestmentMovement
                      ? 'Movimentação vinculada a um investimento'
                      : 'Pagamento vinculado a uma conta a pagar',
                ),
              ),
            if (!isBillPayment)
              ListTile(
                leading: const Icon(Symbols.edit_rounded),
                title: const Text('Editar'),
                onTap: () => Navigator.pop(context, _EntryAction.edit),
              ),
            if (entry.type != 'card_payment' && !entry.isInvestmentMovement)
              ListTile(
                leading: const Icon(Symbols.content_copy_rounded),
                title: const Text('Duplicar'),
                onTap: () => Navigator.pop(context, _EntryAction.duplicate),
              ),
            ListTile(
              leading: const Icon(Symbols.history_rounded),
              title: const Text('Histórico de alterações'),
              onTap: () => Navigator.pop(context, _EntryAction.revisions),
            ),
            if (!isBillPayment)
              ListTile(
                leading: const Icon(Symbols.delete_outline_rounded),
                title: const Text('Mover para a lixeira'),
                onTap: () => Navigator.pop(context, _EntryAction.delete),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _EntryAction.edit:
        await showTransactionForm(context, source: entry);
      case _EntryAction.duplicate:
        await showTransactionForm(context, source: entry, duplicate: true);
      case _EntryAction.delete:
        await _changeTrashStatus(entry, restore: false);
      case _EntryAction.revisions:
        await _showRevisions(entry.id!);
    }
  }

  Future<void> _showRevisions(int id) {
    final revisions = ref.read(transactionRepositoryProvider).listRevisions(id);
    final accounts = ref.read(allAccountsProvider).valueOrNull ?? [];
    final categories = ref.read(allCategoriesProvider()).valueOrNull ?? [];
    final accountNames = {
      for (final account in accounts) account.id: account.name,
    };
    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };
    final hidden = PreferencesScope.of(context)?.discreet ?? false;
    return showAppBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: FutureBuilder<List<TransactionRevision>>(
          future: revisions,
          builder: (context, snapshot) {
            final history = snapshot.data ?? [];
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Histórico de alterações',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  const Text('Não foi possível carregar as alterações.')
                else if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Nenhuma alteração registrada.'),
                  ),
                for (final revision in history)
                  ListTile(
                    title: Text(switch (revision.action) {
                      'edit' => 'Editado',
                      'delete' => 'Movido para a lixeira',
                      _ => 'Restaurado',
                    }),
                    subtitle: Text(
                      [
                        'Em ${_dateLabel(revision.recordedAt)}',
                        'Antes da alteração',
                        '${_entryType(revision.previous.type)} · ${hidden ? '••••' : formatBrl(revision.previous.amountCents)}',
                        'Data do lançamento: ${_dateLabel(revision.previous.date)}',
                        accountNames[revision.previous.accountId] ??
                            'Conta #${revision.previous.accountId}',
                        if (accountNames[revision.previous.destinationAccountId]
                            case final destination?)
                          'Destino: $destination',
                        if (categoryNames[revision.previous.categoryId]
                            case final category?)
                          category,
                        if (revision.previous.incomeSource case final source?)
                          source,
                        if (revision.previous.description
                            case final description?)
                          description,
                      ].join('\n'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) => DateFormat.yMd('pt_BR').format(date);

  String _entryType(String type) => switch (type) {
    'income' => 'Entrada',
    'transfer' => 'Transferência',
    _ => 'Saída',
  };

  Future<void> _changeTrashStatus(
    Transaction entry, {
    required bool restore,
    bool confirm = true,
  }) async {
    final scope = !restore && entry.recurrenceId != null
        ? await showAppBottomSheet<int>(
            context: context,
            builder: (context) => SafeArea(
              child: Wrap(
                children: [
                  const ListTile(title: Text('Excluir lançamento recorrente')),
                  for (final (index, option) in [
                    'Só este',
                    'Este e os próximos',
                    'Todos',
                  ].indexed)
                    ListTile(
                      title: Text(option),
                      onTap: () => Navigator.pop(context, index),
                    ),
                ],
              ),
            ),
          )
        : 0;
    if (!mounted || scope == null) return;
    final confirmed =
        (!confirm && scope == 0) ||
        await confirmRecordAction(
          context,
          title: restore
              ? 'Restaurar lançamento?'
              : 'Mover lançamento para a lixeira?',
          message: restore
              ? 'O lançamento volta ao histórico e seu efeito no saldo é reaplicado.'
              : scope == 0
              ? 'Você pode restaurar o lançamento pela lixeira. O efeito no saldo será estornado.'
              : 'A recorrência será encerrada. Os lançamentos selecionados vão para a lixeira.',
          action: restore ? 'Restaurar' : 'Mover para a lixeira',
        );
    if (!confirmed || !mounted) return;
    final repo = ref.read(transactionRepositoryProvider);
    try {
      if (restore) {
        await repo.restoreTransaction(entry.id!);
      } else if (scope == 0) {
        await repo.deleteTransaction(entry.id!);
      } else {
        await repo.deleteRecurrenceEntries(
          entry.recurrenceId!,
          from: scope == 1 ? entry.date : null,
        );
      }
      if (!mounted) return;
      if (!restore) {
        setState(() {
          if (_selected == entry.id) _selected = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scope == 0
                  ? 'Lançamento movido para a lixeira.'
                  : 'Recorrência encerrada.',
            ),
            duration: const Duration(seconds: 5),
            action: scope != 0
                ? null
                : SnackBarAction(
                    label: 'Desfazer',
                    onPressed: () async {
                      try {
                        await repo.restoreTransaction(entry.id!);
                      } catch (error) {
                        if (mounted)
                          showRecordError(
                            context,
                            error,
                            'Não foi possível restaurar o lançamento.',
                          );
                      }
                    },
                  ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        showRecordError(
          context,
          error,
          'Não foi possível atualizar o lançamento.',
        );
      }
    }
  }

  void _openDetail(
    Transaction entry,
    Map<int?, String> names,
    Category? category,
    bool linked,
    bool wide,
  ) {
    if (wide) {
      setState(() => _selected = entry.id);
      return;
    }
    showAppBottomSheet<void>(
      context: context,
      sidePanel: true,
      builder: (sheet) => _detail(
        entry,
        names,
        category,
        linked,
        onClose: () => Navigator.pop(sheet),
      ),
    );
  }

  Widget _detail(
    Transaction item,
    Map<int?, String> names,
    Category? category,
    bool linked, {
    VoidCallback? onClose,
  }) {
    void run(Future<void> Function() action) {
      onClose?.call();
      action();
    }

    final (icon, color) = categoryStyle(context, category);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              AppIcon(icon, color: color, size: 56),
              const Spacer(),
              IconButton(
                tooltip: 'Fechar detalhe',
                icon: const Icon(Symbols.close_rounded),
                onPressed: onClose ?? () => setState(() => _selected = null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MoneyText(
            item.amountCents,
            emphasis: true,
            signed: true,
            kind: transactionKind(item),
          ),
          Text(
            transactionTitle(item, category),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          AppSurface(
            child: Column(
              children: [
                for (final (label, value) in [
                  ('Tipo', transactionType(item.type)),
                  if (category != null) ('Categoria', category.name),
                  (
                    item.type == 'transfer' ? 'Conta de origem' : 'Conta',
                    names[item.accountId] ?? 'Conta',
                  ),
                  if (item.destinationAccountId != null)
                    (
                      'Conta de destino',
                      names[item.destinationAccountId] ?? 'Conta',
                    ),
                  ('Data', _dateLabel(item.date)),
                  (
                    'Situação',
                    switch (item.status) {
                      'pending' => 'Agendado',
                      'cancelled' => 'Cancelado',
                      _ => 'Pago',
                    },
                  ),
                  if (item.recurrenceId != null)
                    ('Repetição', 'Lançamento recorrente'),
                  if (item.incomeSource != null)
                    ('Fonte da receita', item.incomeSource!),
                  if (item.note != null) ('Observação', item.note!),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    subtitle: Text(value),
                  ),
              ],
            ),
          ),
          if (item.photo != null &&
              PreferencesScope.of(context)?.discreet != true) ...[
            const SizedBox(height: 12),
            _ReceiptPhoto(item.photo!),
          ],
          const SizedBox(height: 12),
          if (item.id!.isNegative)
            FilledButton(
              onPressed: () {
                onClose?.call();
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardDetailsScreen(cardId: -item.accountId),
                  ),
                );
              },
              child: const Text('Ver cartão'),
            )
          else if (_showTrash)
            FilledButton(
              onPressed: () =>
                  run(() => _changeTrashStatus(item, restore: true)),
              child: const Text('Restaurar'),
            )
          else ...[
            if (!linked)
              FilledButton(
                onPressed: () =>
                    run(() => showTransactionForm(context, source: item)),
                child: const Text('Editar'),
              ),
            if (item.type != 'card_payment' && !item.isInvestmentMovement)
              TextButton(
                onPressed: () => run(
                  () => showTransactionForm(
                    context,
                    source: item,
                    duplicate: true,
                  ),
                ),
                child: const Text('Duplicar'),
              ),
            TextButton(
              onPressed: () => run(() => _showRevisions(item.id!)),
              child: const Text('Histórico de alterações'),
            ),
            if (!linked)
              TextButton(
                onPressed: () =>
                    run(() => _changeTrashStatus(item, restore: false)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.of(context).expenseText,
                ),
                child: const Text('Excluir'),
              ),
          ],
        ],
      ),
    );
  }

  bool _matches(
    Transaction item,
    Map<int?, String> accounts,
    Map<int?, Category> categories,
  ) {
    if (_showTrash) return true;
    final range = _range;
    if (range != null &&
        (item.date.isBefore(range.start) || !item.date.isBefore(range.end)))
      return false;
    final filters = _filters;
    if (filters.type != null && item.type != filters.type) return false;
    if (filters.accounts.isNotEmpty &&
        !filters.accounts.contains(item.accountId) &&
        !filters.accounts.contains(item.destinationAccountId))
      return false;
    if (filters.categories.isNotEmpty &&
        !filters.categories.contains(item.categoryId))
      return false;
    if (filters.min != null && item.amountCents < filters.min! ||
        filters.max != null && item.amountCents > filters.max!)
      return false;
    final term = _search.text.trim().toLowerCase();
    return term.isEmpty ||
        [
          item.description,
          item.note,
          item.incomeSource,
          accounts[item.accountId],
          accounts[item.destinationAccountId],
          categories[item.categoryId]?.name,
          transactionType(item.type),
        ].nonNulls.any((text) => text.toLowerCase().contains(term));
  }

  void _clear() {
    setState(() {
      _filters = _emptyFilters;
      _period = _EntryPeriod.all;
      _search.clear();
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(
      _showTrash ? deletedTransactionsProvider : allTransactionsProvider,
    );
    final accounts = ref.watch(allAccountsProvider).valueOrNull ?? <Account>[];
    final categories =
        ref.watch(allCategoriesProvider()).valueOrNull ?? <Category>[];
    final bills = ref.watch(allBillsProvider).valueOrNull ?? [];
    final cards = ref.watch(creditCardsProvider).valueOrNull ?? [];
    final purchases = ref.watch(cardPurchasesProvider).valueOrNull ?? [];
    final accountNames = {
      for (final account in accounts) account.id: account.name,
      for (final card in cards) -card.id: card.name,
    };
    final byId = {for (final category in categories) category.id: category};
    final billPayments = {for (final bill in bills) bill.paidTransactionId};
    final size = WindowSizeClass.of(context);
    final wide = WindowSizeClass.wide(context);
    final table =
        size == WindowSizeClass.large &&
        MediaQuery.textScalerOf(context).scale(16) <= 21;
    final active = _filterCount(_filters);
    bool linked(Transaction item) =>
        item.id!.isNegative ||
        billPayments.contains(item.id) ||
        item.type == 'card_payment' ||
        item.isInvestmentMovement;
    void filters() async {
      final value = await showAppBottomSheet<_Filters>(
        context: context,
        builder: (_) => _FilterForm(
          initial: _filters,
          accounts: accounts,
          categories: categories,
        ),
      );
      if (value != null && mounted) setState(() => _filters = value);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_showTrash ? 'Lixeira' : 'Lançamentos'),
        actions: [
          IconButton(
            tooltip: _showTrash ? 'Voltar ao histórico' : 'Abrir lixeira',
            icon: Icon(
              _showTrash
                  ? Symbols.history_rounded
                  : Symbols.delete_outline_rounded,
            ),
            onPressed: () => setState(() {
              _showTrash = !_showTrash;
              _selected = null;
            }),
          ),
        ],
      ),
      body: AppContent(
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            title: 'Erro ao carregar lançamentos.',
            actionLabel: 'Tentar novamente',
            onAction: () => ref.invalidate(
              _showTrash
                  ? deletedTransactionsProvider
                  : allTransactionsProvider,
            ),
          ),
          data: (entries) {
            final transactions = [
              ...entries,
              if (!_showTrash)
                for (final purchase in purchases)
                  Transaction(
                    id: -purchase.id,
                    type: 'expense',
                    amountCents: purchase.amountCents,
                    date: purchase.purchaseDate,
                    accountId: -purchase.cardId,
                    description: purchase.description,
                    categoryId: purchase.categoryId,
                    createdAt: purchase.purchaseDate,
                  ),
            ];
            final items = transactions
                .where((item) => _matches(item, accountNames, byId))
                .toList();
            if (!_showTrash) {
              String categoryName(Transaction item) =>
                  byId[item.categoryId]?.name ?? '';
              String accountName(Transaction item) =>
                  accountNames[item.accountId] ?? 'Conta';
              items.sort((a, b) {
                final order = switch (_order) {
                  _Order.date => a.date.compareTo(b.date),
                  _Order.description =>
                    transactionTitle(
                      a,
                      byId[a.categoryId],
                    ).toLowerCase().compareTo(
                      transactionTitle(b, byId[b.categoryId]).toLowerCase(),
                    ),
                  _Order.category => categoryName(a).compareTo(categoryName(b)),
                  _Order.account => accountName(a).compareTo(accountName(b)),
                  _Order.value =>
                    (a.type == 'expense' ? -a.amountCents : a.amountCents)
                        .compareTo(
                          b.type == 'expense' ? -b.amountCents : b.amountCents,
                        ),
                };
                if (order == 0) return b.id!.compareTo(a.id!);
                return _ascending ? order : -order;
              });
            }
            final summary = FinanceSummary();
            final dayTotals = <DateTime, BigInt>{};
            for (final item in items) {
              if (item.status != 'paid') continue;
              summary.add(item.type, item.amountCents, item.categoryId);
              if (item.type != 'income' && item.type != 'expense') continue;
              final value = BigInt.from(
                item.type == 'income' ? item.amountCents : -item.amountCents,
              );
              dayTotals.update(
                calendarDate(item.date),
                (total) => total + value,
                ifAbsent: () => value,
              );
            }
            final selected = items
                .where((item) => item.id == _selected)
                .firstOrNull;
            final filterBar = Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    focusNode: _searchFocus,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar lançamentos',
                      prefixIcon: const Icon(Symbols.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () => setState(_search.clear),
                              icon: const Icon(Symbols.close_rounded),
                            ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppLayout.pill),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppLayout.pill),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: active == 0 ? 'Filtros' : 'Filtros ($active ativos)',
                  icon: Badge(
                    isLabelVisible: active != 0,
                    label: Text('$active'),
                    child: const Icon(Symbols.tune_rounded),
                  ),
                  onPressed: wide
                      ? () => setState(
                          () => _showInlineFilters = !_showInlineFilters,
                        )
                      : filters,
                ),
              ],
            );
            Widget list() => LayoutBuilder(
              builder: (context, limits) => Column(
                children: [
                  if (!_showTrash)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: limits.maxHeight < 440
                            ? limits.maxHeight * .56
                            : double.infinity,
                      ),
                      child: SingleChildScrollView(
                        primary: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              filterBar,
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final (value, label) in const [
                                      (_EntryPeriod.all, 'Todos'),
                                      (_EntryPeriod.today, 'Hoje'),
                                      (_EntryPeriod.week, '7 dias'),
                                      (_EntryPeriod.month, 'Este mês'),
                                      (_EntryPeriod.previous, 'Mês anterior'),
                                      (_EntryPeriod.custom, 'Personalizado'),
                                    ])
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(label),
                                          selected: _period == value,
                                          onSelected: (_) =>
                                              _choosePeriod(value),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (_period == _EntryPeriod.custom &&
                                  _custom != null)
                                Text(
                                  '${_dateLabel(_custom!.start)} a ${_dateLabel(DateTime(_custom!.end.year, _custom!.end.month, _custom!.end.day - 1))}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              AppSurface(
                                padding: const EdgeInsets.all(12),
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    for (final (label, value, kind) in [
                                      (
                                        'Receitas',
                                        summary.income,
                                        MoneyKind.income,
                                      ),
                                      (
                                        'Despesas',
                                        summary.expense,
                                        MoneyKind.expense,
                                      ),
                                      (
                                        'Saldo',
                                        summary.result,
                                        MoneyKind.neutral,
                                      ),
                                    ])
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium,
                                          ),
                                          MoneyText.total(
                                            value,
                                            kind: kind,
                                            signed: true,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (wide && _showInlineFilters && !_showTrash)
                    Flexible(
                      child: _FilterForm(
                        initial: _filters,
                        accounts: accounts,
                        categories: categories,
                        onApply: (value) => setState(() {
                          _filters = value;
                          _showInlineFilters = false;
                        }),
                      ),
                    ),
                  if (table && items.isNotEmpty && !_showTrash)
                    _TableCells(
                      children: [
                        for (final (order, title) in const [
                          (_Order.date, 'Data'),
                          (_Order.description, 'Descrição'),
                          (_Order.category, 'Categoria'),
                          (_Order.account, 'Conta'),
                          (_Order.value, 'Valor'),
                        ])
                          InkWell(
                            onTap: () => setState(() {
                              _ascending = _order == order ? !_ascending : true;
                              _order = order;
                            }),
                            child: Tooltip(
                              message: 'Ordenar por $title',
                              child: Text(
                                '$title${_order == order
                                    ? _ascending
                                          ? ' ↑'
                                          : ' ↓'
                                    : ''}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                      ],
                    ),
                  Expanded(
                    child: items.isEmpty
                        ? SingleChildScrollView(
                            child: EmptyState(
                              title: _showTrash
                                  ? 'Lixeira vazia'
                                  : transactions.isEmpty
                                  ? 'Nenhum lançamento registrado'
                                  : 'Nada encontrado',
                              message: transactions.isEmpty || _showTrash
                                  ? null
                                  : 'Tente outro termo ou limpe os filtros.',
                              icon: _showTrash
                                  ? Symbols.delete_rounded
                                  : Symbols.receipt_long_rounded,
                              compact: wide,
                              actionLabel: _showTrash
                                  ? null
                                  : transactions.isEmpty
                                  ? 'Novo lançamento'
                                  : 'Limpar filtros',
                              onAction: _showTrash
                                  ? null
                                  : transactions.isEmpty
                                  ? () => showTransactionForm(context)
                                  : _clear,
                            ),
                          )
                        : ListView.builder(
                            key: PageStorageKey(
                              _showTrash ? 'lixeira' : 'lançamentos',
                            ),
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final item = items[i];
                              final day = calendarDate(item.date);
                              final grouped =
                                  !_showTrash &&
                                  !table &&
                                  (i == 0 ||
                                      !DateUtils.isSameDay(
                                        items[i - 1].date,
                                        item.date,
                                      ));
                              final category = byId[item.categoryId];
                              void open() => _openDetail(
                                item,
                                accountNames,
                                category,
                                linked(item),
                                wide,
                              );
                              Widget row = table && !_showTrash
                                  ? InkWell(
                                      onTap: open,
                                      child: _TableCells(
                                        children: [
                                          Text(_dateLabel(item.date)),
                                          Text(
                                            transactionTitle(item, category),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(category?.name ?? '—'),
                                          Text(
                                            accountNames[item.accountId] ??
                                                'Conta',
                                          ),
                                          MoneyText(
                                            item.amountCents,
                                            kind: transactionKind(item),
                                            signed: true,
                                            alignment: Alignment.centerRight,
                                          ),
                                        ],
                                      ),
                                    )
                                  : TransactionTile(
                                      transaction: item,
                                      accountName:
                                          accountNames[item.accountId] ??
                                          'Conta',
                                      category: category,
                                      destinationAccountName:
                                          accountNames[item
                                              .destinationAccountId],
                                      onTap: open,
                                      onActions: item.id!.isNegative
                                          ? null
                                          : () => _showActions(
                                              item,
                                              isBillPayment: linked(item),
                                            ),
                                    );
                              if (!table && !_showTrash && !linked(item)) {
                                row = Dismissible(
                                  key: ValueKey('gesto-${item.id}'),
                                  background: const _SwipeBackground(
                                    icon: Symbols.content_copy_rounded,
                                    label: 'Duplicar',
                                    end: false,
                                  ),
                                  secondaryBackground: const _SwipeBackground(
                                    icon: Symbols.delete_rounded,
                                    label: 'Excluir',
                                    end: true,
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction ==
                                        DismissDirection.startToEnd) {
                                      await showTransactionForm(
                                        context,
                                        source: item,
                                        duplicate: true,
                                      );
                                    } else {
                                      await _changeTrashStatus(
                                        item,
                                        restore: false,
                                        confirm: false,
                                      );
                                    }
                                    return false;
                                  },
                                  child: row,
                                );
                              }
                              final theme = Theme.of(context);
                              final selectedColor =
                                  item.id == _selected ||
                                      item.id == _highlighted
                                  ? theme.colorScheme.primaryContainer
                                  : null;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (grouped)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        12,
                                        8,
                                        4,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _groupLabel(day),
                                              style: theme.textTheme.titleSmall,
                                            ),
                                          ),
                                          Flexible(
                                            child: MoneyText.total(
                                              dayTotals[day] ?? BigInt.zero,
                                              alignment: Alignment.centerRight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  AnimatedContainer(
                                    duration:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 250),
                                    decoration: BoxDecoration(
                                      color:
                                          selectedColor ??
                                          theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppLayout.controlRadius,
                                      ),
                                    ),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    child: row,
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? AppLayout.margin(context) : 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    key: const ValueKey('lista'),
                    flex: 5,
                    child: list(),
                  ),
                  if (wide) ...[
                    const VerticalDivider(width: 16),
                    Expanded(
                      flex: 7,
                      child: selected == null
                          ? const EmptyState(
                              title: 'Selecione um lançamento',
                              icon: Symbols.receipt_long_rounded,
                              compact: true,
                            )
                          : _detail(
                              selected,
                              accountNames,
                              byId[selected.categoryId],
                              linked(selected),
                            ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _groupLabel(DateTime day) {
    final now = calendarDate(DateTime.now());
    if (now == day) return 'Hoje';
    if (DateTime(now.year, now.month, now.day - 1) == day) return 'Ontem';
    return DateFormat("d 'de' MMMM", 'pt_BR').format(day);
  }
}

int _filterCount(_Filters filters) =>
    (filters.type == null ? 0 : 1) +
    filters.accounts.length +
    filters.categories.length +
    (filters.min == null && filters.max == null ? 0 : 1);

class _TableCells extends StatelessWidget {
  const _TableCells({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 52),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final (i, cell) in children.indexed)
            Expanded(
              flex: i == 1 ? 3 : 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: cell,
              ),
            ),
        ],
      ),
    ),
  );
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.icon,
    required this.label,
    required this.end,
  });
  final IconData icon;
  final String label;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: end ? scheme.errorContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppLayout.controlRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon), const SizedBox(width: 8), Text(label)],
          ),
        ),
      ),
    );
  }
}

class _ReceiptPhoto extends StatelessWidget {
  const _ReceiptPhoto(this.photo);
  final String photo;

  @override
  Widget build(BuildContext context) {
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppLayout.controlRadius),
        child: Image.memory(
          base64Decode(photo),
          height: 240,
          cacheWidth: 800,
          fit: BoxFit.contain,
          semanticLabel: 'Foto do lançamento',
          errorBuilder: (_, _, _) => const Text('Foto indisponível.'),
        ),
      );
    } on FormatException {
      return const Text('Foto indisponível.');
    }
  }
}

class _FilterForm extends StatefulWidget {
  const _FilterForm({
    required this.initial,
    required this.accounts,
    required this.categories,
    this.onApply,
  });
  final _Filters initial;
  final List<Account> accounts;
  final List<Category> categories;
  final ValueChanged<_Filters>? onApply;

  @override
  State<_FilterForm> createState() => _FilterFormState();
}

class _FilterFormState extends State<_FilterForm> {
  late String? _type = widget.initial.type;
  late final _accounts = {...widget.initial.accounts};
  late final _categories = {...widget.initial.categories};
  late final _min = TextEditingController(
    text: widget.initial.min == null ? '' : brlInput(widget.initial.min!),
  );
  late final _max = TextEditingController(
    text: widget.initial.max == null ? '' : brlInput(widget.initial.max!),
  );
  String? _error;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = (
      type: _type,
      accounts: _accounts,
      categories: _categories,
      min: parseBrlCents(_min.text),
      max: parseBrlCents(_max.text),
    );
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtrar lançamentos', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Tipo', style: theme.textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                for (final (type, label) in const [
                  (null, 'Todos'),
                  ('expense', 'Despesa'),
                  ('income', 'Receita'),
                  ('transfer', 'Transferência'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Contas', style: theme.textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                for (final account in widget.accounts)
                  FilterChip(
                    label: Text(account.name),
                    selected: _accounts.contains(account.id),
                    onSelected: (active) => setState(
                      () => active
                          ? _accounts.add(account.id!)
                          : _accounts.remove(account.id),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Categorias', style: theme.textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Sem categoria'),
                  selected: _categories.contains(null),
                  onSelected: (active) => setState(
                    () => active
                        ? _categories.add(null)
                        : _categories.remove(null),
                  ),
                ),
                for (final category in widget.categories)
                  CategoryChip(
                    category: category,
                    selected: _categories.contains(category.id),
                    onSelected: (active) => setState(
                      () => active
                          ? _categories.add(category.id)
                          : _categories.remove(category.id),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Faixa de valor', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final (label, controller) in [
              ('Mínimo (R\$)', _min),
              ('Máximo (R\$)', _max),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: label),
                  onChanged: (_) => setState(() => _error = null),
                ),
              ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            FilledButton(
              onPressed: () {
                if ((_min.text.trim().isNotEmpty &&
                        (filter.min == null || filter.min! < 0)) ||
                    (_max.text.trim().isNotEmpty &&
                        (filter.max == null ||
                            filter.max! < (filter.min ?? 0)))) {
                  setState(
                    () => _error = 'Informe uma faixa de valores válida.',
                  );
                  return;
                }
                if (widget.onApply case final onApply?) {
                  onApply(filter);
                } else {
                  Navigator.pop(context, filter);
                }
              },
              child: Text('Aplicar (${_filterCount(filter)})'),
            ),
            TextButton(
              onPressed: () => setState(() {
                _type = null;
                _accounts.clear();
                _categories.clear();
                _min.clear();
                _max.clear();
                _error = null;
              }),
              child: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
