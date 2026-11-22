import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/components.dart';
import '../../../core/widgets/record_actions.dart';
import '../../../data/local/database.dart';
import '../domain/investment_portfolio.dart';
import 'investment_forms.dart';
import 'investment_providers.dart';
import 'investment_report_screen.dart';

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(investmentPortfolioProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Investimentos')),
      body: AppContent(
        maxWidth: AppLayout.maxReading,
        child: portfolio.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            title: 'Não foi possível carregar os investimentos.',
            actionLabel: 'Tentar novamente',
            onAction: () => ref.invalidate(investmentPortfolioProvider),
          ),
          data: (data) {
            final now = DateTime.now();
            final needsReview = data.positions
                .where((item) => item.needsReview(now))
                .length;
            final theme = Theme.of(context);
            return ListView(
              padding: AppLayout.pagePadding(context),
              children: [
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patrimônio investido',
                        style: theme.textTheme.titleMedium,
                      ),
                      MoneyText.total(
                        data.value + data.legacyValue,
                        emphasis: true,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _Value('Resgatável hoje', data.redeemable),
                          _Value('Saldo em conta', data.cash),
                          _Value(
                            'Saldo após resgates',
                            data.cash + data.redeemable,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'O valor resgatável é líquido e vem do último registro de cada posição.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Symbols.add_rounded),
                      label: const Text('Novo investimento'),
                      onPressed: () async {
                        final id = await showInvestmentForm(context);
                        if (context.mounted && id != null) {
                          _openDetails(context, id);
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Symbols.bar_chart_rounded),
                      label: const Text('Ver relatório'),
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InvestmentReportScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Carteira', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (needsReview > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      needsReview == 1
                          ? '1 posição aguarda atualização neste mês.'
                          : '$needsReview posições aguardam atualização neste mês.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                if (data.positions.isEmpty)
                  const EmptyState(
                    icon: Symbols.trending_up_rounded,
                    title: 'Nenhum investimento cadastrado.',
                    compact: true,
                  ),
                for (final position in data.positions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PositionCard(
                      position: position,
                      today: now,
                      onTap: () =>
                          _openDetails(context, position.investment.id),
                    ),
                  ),
                if (data.legacyAccounts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Contas de investimento',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'Saldos cadastrados em Contas. O relatório mensal usa as posições da carteira.',
                          style: theme.textTheme.bodySmall,
                        ),
                        for (final account in data.legacyAccounts)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(account.name),
                            trailing: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 115),
                              child: MoneyText(account.currentBalanceCents),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const _MonthlyReminder(),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _openDetails(BuildContext context, int id) => Navigator.push<void>(
  context,
  MaterialPageRoute(builder: (_) => _InvestmentDetails(id: id)),
);

class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.position,
    required this.today,
    required this.onTap,
  });

  final InvestmentPosition position;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final item = position.investment;
    final date = DateFormat.yMd('pt_BR').format(position.lastValuation.date);
    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(Symbols.trending_up_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      [
                        item.kind,
                        if (item.institution.isNotEmpty) item.institution,
                      ].join(' · '),
                    ),
                  ],
                ),
              ),
              const Icon(Symbols.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _Value(
                'Valor da posição',
                BigInt.from(position.latest.valueCents),
              ),
              _Value(
                'Resgatável hoje',
                BigInt.from(position.latest.redeemableCents),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            !item.isActive
                ? 'Arquivado'
                : position.needsReview(today)
                ? 'Atualização pendente · último registro em $date'
                : 'Posição informada em $date',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InvestmentDetails extends ConsumerWidget {
  const _InvestmentDetails({required this.id});

  final int id;

  Future<void> _changeArchive(
    BuildContext context,
    WidgetRef ref,
    bool archive,
  ) async {
    final repo = ref.read(investmentRepositoryProvider);
    if (archive &&
        !await confirmRecordAction(
          context,
          title: 'Arquivar este investimento?',
          message:
              'A posição sai da carteira ativa e o histórico fica disponível.',
          action: 'Arquivar',
        )) {
      return;
    }
    try {
      if (archive) {
        await repo.archive(id);
      } else {
        await repo.reactivate(id);
      }
    } catch (error) {
      if (context.mounted) {
        showRecordError(
          context,
          error,
          'Não foi possível atualizar o investimento.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(investmentPortfolioProvider);
    final data = portfolio.valueOrNull;
    final position = data?.positions
        .where((item) => item.investment.id == id)
        .firstOrNull;
    final item = position?.investment;
    return Scaffold(
      appBar: AppBar(
        title: Text(item?.name ?? 'Investimento'),
        actions: [
          if (item != null)
            PopupMenuButton<String>(
              tooltip: 'Ações do investimento',
              onSelected: (action) => switch (action) {
                'edit' => showInvestmentForm(context, investment: item),
                _ => _changeArchive(context, ref, item.isActive),
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar dados')),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(item.isActive ? 'Arquivar' : 'Reativar'),
                ),
              ],
            ),
        ],
      ),
      body: AppContent(
        maxWidth: AppLayout.maxReading,
        child: position == null || item == null || data == null
            ? Center(
                child: portfolio.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Investimento indisponível.'),
              )
            : ListView(
                padding: AppLayout.pagePadding(context),
                children: [
                  AppSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Value(
                          'Valor da posição',
                          BigInt.from(position.latest.valueCents),
                          emphasis: true,
                        ),
                        const SizedBox(height: 8),
                        _Value(
                          'Resgatável hoje (líquido informado)',
                          BigInt.from(position.latest.redeemableCents),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Posição informada em ${DateFormat.yMd('pt_BR').format(position.lastValuation.date)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.isActive) ...[
                        FilledButton(
                          onPressed: () => showInvestmentMovement(
                            context,
                            position,
                            InvestmentMovementKind.valuation,
                            data.cashAccounts,
                          ),
                          child: const Text('Atualizar posição'),
                        ),
                        for (final (label, type) in [
                          ('Aportar', InvestmentMovementKind.contribution),
                          ('Resgatar', InvestmentMovementKind.redemption),
                        ])
                          OutlinedButton(
                            onPressed:
                                data.cashAccounts.isEmpty ||
                                    (type ==
                                            InvestmentMovementKind.redemption &&
                                        position.latest.valueCents == 0)
                                ? null
                                : () => showInvestmentMovement(
                                    context,
                                    position,
                                    type,
                                    data.cashAccounts,
                                  ),
                            child: Text(label),
                          ),
                      ],
                      TextButton(
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InvestmentReportScreen(investmentId: id),
                          ),
                        ),
                        child: const Text('Relatório mensal'),
                      ),
                    ],
                  ),
                  if (item.isActive && data.cashAccounts.isEmpty)
                    const Text(
                      'Cadastre uma conta disponível para registrar aportes e resgates.',
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Histórico',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final movement in position.movements.reversed)
                    _MovementRow(movement: movement),
                ],
              ),
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final InvestmentMovementRow movement;

  @override
  Widget build(BuildContext context) {
    final kind = InvestmentMovementKind.values.byName(movement.kind);
    final (label, icon, value) = switch (kind) {
      InvestmentMovementKind.opening => (
        'Posição inicial',
        Symbols.flag_rounded,
        movement.valueCents,
      ),
      InvestmentMovementKind.contribution => (
        'Aporte',
        Symbols.arrow_downward_rounded,
        movement.amountCents,
      ),
      InvestmentMovementKind.redemption => (
        'Resgate',
        Symbols.arrow_upward_rounded,
        -movement.amountCents,
      ),
      InvestmentMovementKind.valuation => (
        'Variação de valor',
        Symbols.timeline_rounded,
        movement.amountCents,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIcon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label),
                      Text(DateFormat.yMd('pt_BR').format(movement.date)),
                    ],
                  ),
                ),
                Flexible(
                  child: MoneyText(value, alignment: Alignment.centerRight),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _Value(
                  'Posição após o registro',
                  BigInt.from(movement.valueCents),
                ),
                if (kind == InvestmentMovementKind.redemption)
                  _Value('Crédito na conta', BigInt.from(movement.cashCents)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value, {this.emphasis = false});

  final String label;
  final BigInt value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      MoneyText.total(value, emphasis: emphasis),
    ],
  );
}

class _MonthlyReminder extends ConsumerStatefulWidget {
  const _MonthlyReminder();

  @override
  ConsumerState<_MonthlyReminder> createState() => _MonthlyReminderState();
}

class _MonthlyReminderState extends ConsumerState<_MonthlyReminder> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final gateway = ref.watch(investmentReminderGatewayProvider);
    if (gateway == null) return const SizedBox.shrink();
    final enabled = ref.watch(investmentReminderProvider);
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: enabled.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => TextButton(
          onPressed: () => ref.invalidate(investmentReminderProvider),
          child: const Text('Recarregar lembrete mensal'),
        ),
        data: (value) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Lembrete mensal de revisão'),
          subtitle: const Text(
            'Receba um aviso no dia 1, às 9h, para conferir seus extratos.',
          ),
          value: value,
          onChanged: _saving
              ? null
              : (checked) async {
                  setState(() => _saving = true);
                  try {
                    final allowed = await gateway.setInvestmentReminder(
                      checked,
                    );
                    if (!mounted) return;
                    if (!allowed) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Autorize as notificações de revisão nos ajustes do Android.',
                          ),
                        ),
                      );
                    }
                    ref.invalidate(investmentReminderProvider);
                  } catch (error) {
                    if (mounted) {
                      showRecordError(
                        this.context,
                        error,
                        'Não foi possível salvar o lembrete.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
        ),
      ),
    );
  }
}
