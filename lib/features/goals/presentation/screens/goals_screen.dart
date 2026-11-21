import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money.dart';
import '../../../../core/widgets/record_actions.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_providers.dart';
import '../widgets/goal_form.dart';
import '../widgets/goal_progress.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(allGoalsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Metas financeiras'), centerTitle: true),
      body: goals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Não foi possível carregar as metas.')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Nenhuma meta cadastrada.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final goal = items[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _GoalDetailsScreen(goalId: goal.id!),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                goal.name,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GoalProgress(goal: goal),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGoalForm(context),
        icon: const Icon(Icons.add),
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
    final goal = result.valueOrNull;
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
              icon: const Icon(Icons.edit_outlined),
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
                      GoalProgress(goal: goal),
                      if (!goal.isReached) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Faltam ${formatBrl(goal.remainingCents)}',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (linkedAccount != null)
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Conta de referência'),
                  subtitle: Text(linkedAccount.name),
                ),
              const SizedBox(height: 16),
              Text('Reserva manual', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'Registre aqui o dinheiro que você já separou para esta meta.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _adjust(context, ref, withdraw: false),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar à reserva'),
                  ),
                  OutlinedButton.icon(
                    onPressed: goal.savedCents == 0
                        ? null
                        : () => _adjust(context, ref, withdraw: true),
                    icon: const Icon(Icons.remove),
                    label: const Text('Retirar da reserva'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _delete(context, ref, goal),
                  icon: Icon(
                    Icons.delete_outline,
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
