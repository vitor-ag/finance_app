import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/design/category_style.dart';
import '../../../../core/design/components.dart';
import '../../../../core/money.dart';
import '../../../../core/widgets/record_actions.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_providers.dart';
import '../widgets/goal_form.dart';
import '../widgets/goal_progress.dart';
import '../widgets/goal_cash_card.dart';
import '../widgets/goal_review_switch.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(allGoalsProvider);
    final theme = Theme.of(context);
    void addGoal() => showGoalForm(context);
    final wide = WindowSizeClass.of(context) != WindowSizeClass.compact;
    return Scaffold(
      appBar: embedded ? null : AppBar(title: const Text('Metas financeiras')),
      body: AppContent(
        child: goals.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            title: 'Não foi possível carregar as metas.',
            actionLabel: 'Tentar novamente',
            onAction: () => ref.invalidate(allGoalsProvider),
          ),
          data: (items) => ListView(
            key: const PageStorageKey('metas'),
            padding: AppLayout.pagePadding(context).copyWith(bottom: 88),
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (embedded)
                    Text('Metas', style: theme.textTheme.titleLarge),
                  if (wide && items.isNotEmpty)
                    TextButton.icon(
                      onPressed: addGoal,
                      icon: const Icon(Symbols.add_rounded),
                      label: const Text('Nova meta'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const GoalCashCard(),
              if (items.isNotEmpty) const GoalReviewSwitch(),
              if (items.isEmpty)
                EmptyState(
                  title: 'Nenhuma meta cadastrada.',
                  message: 'Escolha um objetivo e acompanhe o quanto você já guardou.',
                  icon: Symbols.flag_rounded,
                  actionLabel: wide ? 'Nova meta' : null,
                  onAction: wide ? addGoal : null,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 470
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final goal in items)
                          SizedBox(
                            width: width,
                            child: AppSurface(
                              onTap: () {
                                final details = _GoalDetailsScreen(
                                  goalId: goal.id!,
                                );
                                if (wide) {
                                  showAppBottomSheet<void>(
                                    context: context,
                                    sidePanel: true,
                                    builder: (_) => details,
                                  );
                                } else {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(builder: (_) => details),
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      AppIcon(
                                        financialIcons[goal.icon]?.$1 ??
                                            Symbols.flag_rounded,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          goal.name,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                      const Icon(Symbols.chevron_right_rounded),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  GoalProgress(goal: goal),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              heroTag: 'nova-meta',
              onPressed: addGoal,
              icon: const Icon(Symbols.add_rounded),
              label: const Text('Nova meta'),
            ),
    );
  }
}

class _GoalDetailsScreen extends ConsumerWidget {
  const _GoalDetailsScreen({required this.goalId});

  final int goalId;

  Future<void> _adjust(
    BuildContext context,
    WidgetRef ref, {
    required bool withdraw,
  }) async {
    final repository = ref.read(goalRepositoryProvider);
    var value = '';
    var saving = false;
    String? error;
    final title = withdraw ? 'Retirar da reserva' : 'Adicionar à reserva';
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (input) => value = input,
            decoration: InputDecoration(
              labelText: 'Valor (R\$)',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final cents = parseBrlCents(value);
                      if (cents == null || cents <= 0) {
                        setState(
                          () => error = 'Informe um valor maior que zero.',
                        );
                        return;
                      }
                      setState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await repository.adjustReserve(
                          goalId,
                          withdraw ? -cents : cents,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (failure) {
                        if (!context.mounted) return;
                        setState(() {
                          saving = false;
                          error = failure is StateError
                              ? failure.message
                              : 'Não foi possível ajustar a reserva.';
                        });
                      }
                    },
              child: Text(withdraw ? 'Retirar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Goal goal) async {
    final repository = ref.read(goalRepositoryProvider);
    final confirmed = await confirmRecordAction(
      context,
      title: 'Excluir meta?',
      message: 'A meta “${goal.name}” e seu progresso serão removidos.',
      action: 'Excluir',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await repository.deleteGoal(goalId);
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (context.mounted) {
        showRecordError(context, error, 'Não foi possível excluir a meta.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(goalByIdProvider(goalId));
    final movements = ref.watch(goalMovementsProvider(goalId));
    ref.listen(goalByIdProvider(goalId), (before, after) {
      if (before?.valueOrNull?.isReached == false &&
          after.valueOrNull?.isReached == true) {
        HapticFeedback.lightImpact();
      }
    });
    final goal = result.valueOrNull;
    final plan = ref
        .watch(goalPlansProvider)
        .valueOrNull
        ?.where((item) => item.goal.id == goalId)
        .firstOrNull;
    final theme = Theme.of(context);
    final accounts = ref.watch(allAccountsProvider).valueOrNull ?? [];
    final linkedAccount = accounts
        .where((account) => account.id == goal?.accountId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal?.name ?? 'Meta financeira'),
        actions: [
          if (goal != null)
            IconButton(
              onPressed: () => showGoalForm(context, goal: goal),
              tooltip: 'Editar meta',
              icon: const Icon(Symbols.edit_rounded),
            ),
        ],
      ),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Não foi possível carregar a meta.')),
        data: (goal) {
          if (goal == null) {
            return const Center(child: Text('Meta indisponível.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _GoalRing(goal: goal)),
                      const SizedBox(height: 12),
                      GoalProgress(goal: goal),
                      if (!goal.isReached) ...[
                        const SizedBox(height: 12),
                        const Text('Falta guardar'),
                        MoneyText(goal.remainingCents),
                        if (plan != null && plan.monthsLeft > 0) ...[
                          const SizedBox(height: 8),
                          const Text('Valor a separar por mês'),
                          MoneyText.total(plan.monthlyTarget),
                          const Text('Falta separar neste mês'),
                          MoneyText.total(plan.leftThisMonth),
                          if (plan.leftThisMonth == BigInt.zero)
                            const Text('Meta de economia do mês em dia'),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              if (linkedAccount != null)
                ListTile(
                  leading: const AppIcon(
                    Symbols.account_balance_wallet_rounded,
                  ),
                  title: const Text('Conta de referência'),
                  subtitle: Text(linkedAccount.name),
                ),
              const SizedBox(height: 16),
              Text('Reserva manual', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                linkedAccount?.isAvailableCash == true
                    ? 'O valor registrado reduz o saldo livre da conta vinculada.'
                    : 'Registre o que já separou. Para considerar esta reserva no saldo livre, vincule uma conta disponível.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _adjust(context, ref, withdraw: false),
                    icon: const Icon(Symbols.add_rounded),
                    label: const Text('Adicionar à reserva'),
                  ),
                  OutlinedButton.icon(
                    onPressed: goal.savedCents == 0
                        ? null
                        : () => _adjust(context, ref, withdraw: true),
                    icon: const Icon(Symbols.remove_rounded),
                    label: const Text('Retirar da reserva'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Histórico de aportes', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              movements.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) =>
                    const Text('Não foi possível carregar o histórico.'),
                data: (items) => items.isEmpty
                    ? const Text('Nenhum aporte registrado.')
                    : AppSurface(
                        child: Column(
                          children: [
                            for (final item in items)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  item.deltaCents < 0 ? 'Retirada' : 'Aporte',
                                ),
                                subtitle: Text(
                                  DateFormat.yMd('pt_BR').format(item.date),
                                ),
                                trailing: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 132,
                                  ),
                                  child: MoneyText(
                                    item.deltaCents,
                                    signed: true,
                                    kind: item.deltaCents < 0
                                        ? MoneyKind.expense
                                        : MoneyKind.income,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _delete(context, ref, goal),
                  icon: Icon(
                    Symbols.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Excluir meta',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: (goal.savedCents / goal.targetCents).clamp(0.0, 1.0),
            ),
            duration: reduce ? Duration.zero : AppLayout.progressMotion,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                color: goal.isReached
                    ? AppColors.of(context).income
                    : theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                semanticsLabel: 'Progresso da meta',
                semanticsValue: '${goal.progressPercent}%',
              ),
            ),
          ),
          Text(
            '${goal.progressPercent}%',
            style: theme.textTheme.headlineLarge,
          ),
          if (goal.isReached && !reduce)
            IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1200),
                builder: (context, value, _) => SizedBox.expand(
                  child: CustomPaint(
                    painter: _GoalConfetti(
                      value,
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalConfetti extends CustomPainter {
  const _GoalConfetti(this.progress, this.primary, this.secondary);
  final double progress;
  final Color primary, secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 18; i++) {
      final angle = i * math.pi / 9;
      final distance = 60 + progress * (40 + i % 5 * 6);
      final offset = Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance + 20 * progress * progress,
      );
      paint.color = (i.isEven ? primary : secondary).withValues(
        alpha: 1 - progress,
      );
      canvas.drawCircle(
        size.center(Offset.zero) + offset,
        i.isEven ? 3 : 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GoalConfetti oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
}
