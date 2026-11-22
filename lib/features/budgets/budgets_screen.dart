import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/category_style.dart';
import '../../core/design/components.dart';
import '../../core/money.dart';
import '../../core/widgets/record_actions.dart';
import '../../data/local/database.dart';
import '../categories/domain/entities/category.dart';
import '../categories/presentation/providers/category_providers.dart';
import '../reports/finance_summary.dart';
import 'budget_data.dart';

class MonthPicker extends StatelessWidget {
  const MonthPicker({
    super.key,
    required this.month,
    required this.onChanged,
    this.limitFuture = false,
  });
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final bool limitFuture;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Mês anterior',
        onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
        icon: const Icon(Symbols.chevron_left_rounded),
      ),
      Expanded(
        child: Text(
          DateFormat.yMMMM('pt_BR').format(month),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      IconButton(
        tooltip: 'Próximo mês',
        onPressed: limitFuture && !month.isBefore(firstOfMonth(DateTime.now()))
            ? null
            : () => onChanged(DateTime(month.year, month.month + 1)),
        icon: const Icon(Symbols.chevron_right_rounded),
      ),
    ],
  );
}

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  DateTime _month = firstOfMonth(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(financeHistoryProvider);
    final records = ref.watch(budgetsProvider);
    final categories = ref.watch(allCategoriesProvider(type: 'expense'));
    final text = Theme.of(context).textTheme;
    final byId = {
      for (final item in categories.valueOrNull ?? <Category>[]) item.id: item,
    };
    final progress = BudgetProgress.forMonth(
      records.valueOrNull ?? [],
      _month,
      history.valueOrNull ?? FinanceHistory(),
    );
    final planned = progress.fold(BigInt.zero, (sum, item) => sum + item.limit);
    final spent = progress.fold(BigInt.zero, (sum, item) => sum + item.spent);
    final ratio = planned == BigInt.zero ? 0.0 : spent / planned;
    void add() => showBudgetForm(
      context,
      month: _month,
      categories: byId.values.toList(),
    );
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final now = DateTime.now();
    final daysLeft = _month == firstOfMonth(now)
        ? days - now.day
        : _month.isAfter(now)
        ? days
        : 0;
    final failed = history.hasError || records.hasError || categories.hasError;
    final loading =
        !history.hasValue || !records.hasValue || !categories.hasValue;
    return Scaffold(
      floatingActionButton:
          WindowSizeClass.of(context) == WindowSizeClass.compact &&
              progress.isNotEmpty &&
              !loading
          ? FloatingActionButton.extended(
              heroTag: 'novo-orcamento',
              onPressed: add,
              icon: const Icon(Symbols.add_rounded),
              label: const Text('Novo orçamento'),
            )
          : null,
      body: ListView(
        key: const PageStorageKey('orçamentos'),
        padding: AppLayout.pagePadding(context).copyWith(bottom: 88),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Orçamentos', style: text.titleLarge),
              if (WindowSizeClass.of(context) != WindowSizeClass.compact &&
                  !loading)
                TextButton.icon(
                  onPressed: add,
                  icon: const Icon(Symbols.add_rounded),
                  label: const Text('Novo orçamento'),
                ),
            ],
          ),
          MonthPicker(
            month: _month,
            onChanged: (month) => setState(() => _month = month),
          ),
          const SizedBox(height: 12),
          if (failed)
            EmptyState(
              title: 'Não foi possível carregar os orçamentos.',
              compact: true,
              actionLabel: 'Tentar novamente',
              onAction: () {
                ref.invalidate(budgetsProvider);
                ref.invalidate(financeHistoryProvider);
                ref.invalidate(allCategoriesProvider(type: 'expense'));
              },
            )
          else if (loading)
            const Center(child: CircularProgressIndicator())
          else if (progress.isEmpty)
            EmptyState(
              title: 'Planeje seus gastos',
              icon: Symbols.pie_chart_rounded,
              message: 'Defina quanto quer gastar em cada categoria e acompanhe aqui.',
              actionLabel: 'Novo orçamento',
              onAction: add,
            )
          else ...[
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Resumo do mês', style: text.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      _BudgetAmount('Planejado', planned),
                      _BudgetAmount('Já usado', spent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BudgetProgressBar(
                    progress: ratio,
                    color: budgetColor(context, ratio),
                    label: 'Orçamento geral',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _month == firstOfMonth(now) && ratio < 1
                        ? (ratio * days / now.day <= 1
                              ? 'No ritmo atual, você fecha o mês dentro do orçamento.'
                              : 'No ritmo atual, seus gastos podem superar o planejado.')
                        : '${(ratio * 100).round()}% do orçamento usado',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final two = constraints.maxWidth >= 480;
                final width = two
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (final item in progress)
                      SizedBox(
                        width: width,
                        child: BudgetCard(
                          progress: item,
                          category: byId[item.row.categoryId],
                          daysLeft: daysLeft,
                          onTap: () => showBudgetForm(
                            context,
                            month: _month,
                            categories: byId.values.toList(),
                            existing: item.row,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

Color budgetColor(BuildContext context, double ratio, [Color? category]) {
  final palette = AppColors.of(context);
  return ratio >= 1
      ? palette.expense
      : ratio >= .8
      ? palette.warning
      : category ?? Theme.of(context).colorScheme.primary;
}

class _BudgetAmount extends StatelessWidget {
  const _BudgetAmount(this.label, this.amount);
  final String label;
  final BigInt amount;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      MoneyText.total(amount),
    ],
  );
}

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.progress,
    this.category,
    this.daysLeft,
    this.onTap,
    this.compact = false,
  });
  final BudgetProgress progress;
  final Category? category;
  final int? daysLeft;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = categoryStyle(context, category);
    final name = category?.name ?? 'Categoria arquivada';
    final theme = Theme.of(context).textTheme;
    final remaining = progress.remaining;
    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (compact) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: AppIcon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: theme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ] else
            Row(
              children: [
                AppIcon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: theme.titleSmall)),
              ],
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _BudgetAmount(
                remaining.isNegative ? 'Acima do limite' : 'Restante',
                remaining.abs(),
              ),
              if (!compact) _BudgetAmount('Limite mensal', progress.limit),
            ],
          ),
          const SizedBox(height: 8),
          BudgetProgressBar(
            progress: progress.ratio,
            color: budgetColor(context, progress.ratio, color),
            label: 'Orçamento de $name',
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress.ratio * 100).round()}% usado${daysLeft == null ? '' : ' · $daysLeft dias restantes'}',
            style: theme.bodySmall,
          ),
        ],
      ),
    );
  }
}

Future<void> showBudgetForm(
  BuildContext context, {
  required DateTime month,
  required List<Category> categories,
  BudgetRow? existing,
}) => showAppBottomSheet<void>(
  context: context,
  builder: (_) =>
      _BudgetForm(month: month, categories: categories, existing: existing),
);

class _BudgetForm extends ConsumerStatefulWidget {
  const _BudgetForm({
    required this.month,
    required this.categories,
    this.existing,
  });
  final DateTime month;
  final List<Category> categories;
  final BudgetRow? existing;

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  final _form = GlobalKey<FormState>();
  late int? _category = widget.existing?.categoryId;
  late bool _carryOver = widget.existing?.carryOver ?? false;
  int _amount = 0;
  bool _busy = false;

  Future<void> _apply({bool remove = false}) async {
    if (!remove && !_form.currentState!.validate()) return;
    if (remove &&
        !await confirmRecordAction(
          context,
          title: 'Excluir orçamento?',
          message: 'O limite desta categoria será removido deste mês.',
          action: 'Excluir',
        ))
      return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final repository = ref.read(budgetRepositoryProvider);
      if (remove) {
        await repository.remove(widget.existing!);
      } else {
        await repository.save(
          category: _category!,
          month: widget.month,
          limit: _amount,
          carryOver: _carryOver,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showRecordError(
        context,
        error,
        'Não foi possível atualizar o orçamento.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories.where(
      (item) => item.isActive || item.id == _category,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'Novo orçamento' : 'Editar orçamento',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (categories.isEmpty)
                const Text(
                  'Cadastre uma categoria de despesa em Ajustes para definir um limite.',
                )
              else ...[
                DropdownButtonFormField<int>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: [
                    for (final item in categories)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: widget.existing == null && !_busy
                      ? (value) => setState(() => _category = value)
                      : null,
                  validator: (value) =>
                      value == null ? 'Selecione uma categoria.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: widget.existing == null
                      ? null
                      : brlInput(widget.existing!.limitCents),
                  decoration: const InputDecoration(
                    labelText: 'Limite mensal (R\$)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (text) {
                    _amount = parseBrlCents(text) ?? 0;
                    return _amount > 0
                        ? null
                        : 'Informe um limite maior que zero.';
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Acumular saldo restante'),
                  subtitle: const Text(
                    'Adiciona o saldo ao orçamento da mesma categoria no próximo mês.',
                  ),
                  value: _carryOver,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _carryOver = value),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : () => _apply(),
                  child: const Text('Salvar orçamento'),
                ),
                if (widget.existing != null)
                  TextButton(
                    onPressed: _busy ? null : () => _apply(remove: true),
                    child: const Text('Excluir orçamento'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
