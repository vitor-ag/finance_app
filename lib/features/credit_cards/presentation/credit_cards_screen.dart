import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../data/local/database.dart';
import '../../accounts/presentation/providers/account_providers.dart';
import '../../categories/presentation/providers/category_providers.dart';
import 'credit_card_providers.dart';

class CreditCardsScreen extends ConsumerWidget {
  const CreditCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(creditCardsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cartões de crédito')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _cardForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Cartão'),
      ),
      body: cards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Não foi possível carregar os cartões.')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Nenhum cartão cadastrado.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final card = items[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: Text(card.name),
                      subtitle: Text(
                        '${card.isActive ? 'Ativo' : 'Arquivado'} · limite ${formatBrl(card.limitCents)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => CardDetailsScreen(cardId: card.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

Future<void> _showError(BuildContext context, Object error) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(error.toString())));
}

Future<void> _cardForm(
  BuildContext context,
  WidgetRef ref, {
  CreditCardRow? card,
}) async {
  final name = TextEditingController(text: card?.name);
  final limit = TextEditingController(
    text: card == null ? '' : brlInput(card.limitCents),
  );
  final closing = TextEditingController(text: card?.closingDay.toString());
  final due = TextEditingController(text: card?.dueDay.toString());
  var saving = false;
  final route = DialogRoute<void>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(card == null ? 'Novo cartão' : 'Editar cartão'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: limit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Limite em R\$'),
              ),
              TextField(
                controller: closing,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dia de fechamento',
                ),
              ),
              TextField(
                controller: due,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dia de vencimento',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialog),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final cents = parseBrlCents(limit.text);
                    final closeDay = int.tryParse(closing.text);
                    final dueDay = int.tryParse(due.text);
                    if (cents == null || closeDay == null || dueDay == null) {
                      await _showError(dialog, 'Preencha o limite e os dias.');
                      return;
                    }
                    setState(() => saving = true);
                    try {
                      final repo = ref.read(creditCardRepositoryProvider);
                      if (card == null) {
                        await repo.createCard(
                          name: name.text,
                          limitCents: cents,
                          closingDay: closeDay,
                          dueDay: dueDay,
                        );
                      } else {
                        await repo.updateCard(
                          card.copyWith(
                            name: name.text,
                            limitCents: cents,
                            closingDay: closeDay,
                            dueDay: dueDay,
                          ),
                        );
                      }
                      if (dialog.mounted) Navigator.pop(dialog);
                    } catch (error) {
                      if (dialog.mounted) await _showError(dialog, error);
                      if (dialog.mounted) setState(() => saving = false);
                    }
                  },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
  await Navigator.of(context).push(route);
  await route.completed;
  name.dispose();
  limit.dispose();
  closing.dispose();
  due.dispose();
}

class CardDetailsScreen extends ConsumerWidget {
  const CardDetailsScreen({super.key, required this.cardId});
  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(creditCardsProvider);
    final purchases = ref.watch(cardPurchasesProvider);
    final installments = ref.watch(cardInstallmentsProvider);
    if (cards.hasError || purchases.hasError || installments.hasError) {
      return const Scaffold(
        body: Center(child: Text('Não foi possível carregar o cartão.')),
      );
    }
    if (!cards.hasValue || !purchases.hasValue || !installments.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final matches = cards.requireValue.where((item) => item.id == cardId);
    if (matches.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Cartão não encontrado.')),
      );
    }
    final card = matches.first;
    final cardPurchases = {
      for (final item in purchases.requireValue.where(
        (item) => item.cardId == cardId,
      ))
        item.id: item,
    };
    final cardInstallments = installments.requireValue
        .where((item) => cardPurchases.containsKey(item.purchaseId))
        .toList();
    final used = cardInstallments
        .where((item) => item.paymentId == null)
        .fold<int>(0, (sum, item) => sum + item.amountCents);
    final dates =
        cardInstallments.map((item) => item.closingDate).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    return Scaffold(
      appBar: AppBar(
        title: Text(card.name),
        actions: [
          IconButton(
            tooltip: 'Editar cartão',
            onPressed: () => _cardForm(context, ref, card: card),
            icon: const Icon(Icons.edit_outlined),
          ),
          if (card.isActive)
            IconButton(
              tooltip: 'Arquivar cartão',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Arquivar cartão?'),
                    content: const Text(
                      'As faturas existentes continuarão disponíveis.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Arquivar'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await ref
                      .read(creditCardRepositoryProvider)
                      .archiveCard(card.id);
                }
              },
              icon: const Icon(Icons.archive_outlined),
            ),
          if (!card.isActive)
            IconButton(
              tooltip: 'Reativar cartão',
              onPressed: () => ref
                  .read(creditCardRepositoryProvider)
                  .reactivateCard(card.id),
              icon: const Icon(Icons.unarchive_outlined),
            ),
        ],
      ),
      floatingActionButton: card.isActive
          ? FloatingActionButton.extended(
              onPressed: () => _purchaseForm(context, ref, card),
              icon: const Icon(Icons.add),
              label: const Text('Compra'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            'Limite disponível ${formatBrl(card.limitCents - used)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Utilizado ${formatBrl(used)} · limite ${formatBrl(card.limitCents)}',
          ),
          Text(
            'Fechamento dia ${card.closingDay} · vencimento dia ${card.dueDay}',
          ),
          const SizedBox(height: 20),
          Text('Faturas', style: Theme.of(context).textTheme.titleLarge),
          if (dates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Nenhuma compra registrada.'),
            ),
          for (final date in dates) ...[
            Builder(
              builder: (context) {
                final rows = cardInstallments
                    .where((item) => item.closingDate == date)
                    .toList();
                final total = rows.fold<int>(
                  0,
                  (sum, item) => sum + item.amountCents,
                );
                final pending = rows.any((item) => item.paymentId == null);
                final due = rows.first.dueDate;
                return Card(
                  child: ExpansionTile(
                    title: Text(
                      'Vencimento ${due.day}/${due.month}/${due.year}',
                    ),
                    subtitle: Text(
                      '${pending ? 'Pendente' : 'Paga'} · fechamento ${date.day}/${date.month}/${date.year}',
                    ),
                    trailing: Text(formatBrl(total)),
                    children: [
                      for (final item in rows)
                        ListTile(
                          title: Text(
                            cardPurchases[item.purchaseId]!.description,
                          ),
                          subtitle: Text(
                            'Parcela ${item.number}/${cardPurchases[item.purchaseId]!.installmentCount}',
                          ),
                          trailing: Text(formatBrl(item.amountCents)),
                        ),
                      if (pending)
                        TextButton.icon(
                          onPressed: () =>
                              _payStatement(context, ref, card, date),
                          icon: const Icon(Icons.check),
                          label: const Text('Pagar fatura'),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _purchaseForm(
  BuildContext context,
  WidgetRef ref,
  CreditCardRow card,
) async {
  final description = TextEditingController();
  final amount = TextEditingController();
  final count = TextEditingController(text: '1');
  var date = DateTime.now();
  int? categoryId;
  var saving = false;
  final categories = (await ref.read(
    allCategoriesProvider(type: 'expense').future,
  )).where((item) => item.isActive).toList();
  if (!context.mounted) {
    description.dispose();
    amount.dispose();
    count.dispose();
    return;
  }
  final route = DialogRoute<void>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Nova compra'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor total em R\$',
                ),
              ),
              TextField(
                controller: count,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de parcelas',
                ),
              ),
              DropdownButtonFormField<int>(
                initialValue: categoryId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sem categoria'),
                  ),
                  for (final category in categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() => categoryId = value),
              ),
              TextButton(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: dialog,
                    initialDate: date,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (selected != null) setState(() => date = selected);
                },
                child: Text('Data ${date.day}/${date.month}/${date.year}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialog),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final cents = parseBrlCents(amount.text);
                    final number = int.tryParse(count.text);
                    if (cents == null || number == null) {
                      await _showError(
                        dialog,
                        'Informe valor e parcelas válidos.',
                      );
                      return;
                    }
                    setState(() => saving = true);
                    try {
                      await ref
                          .read(creditCardRepositoryProvider)
                          .createPurchase(
                            cardId: card.id,
                            description: description.text,
                            amountCents: cents,
                            count: number,
                            date: date,
                            categoryId: categoryId,
                          );
                      if (dialog.mounted) Navigator.pop(dialog);
                    } catch (error) {
                      if (dialog.mounted) await _showError(dialog, error);
                      if (dialog.mounted) setState(() => saving = false);
                    }
                  },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
  await Navigator.of(context).push(route);
  await route.completed;
  description.dispose();
  amount.dispose();
  count.dispose();
}

Future<void> _payStatement(
  BuildContext context,
  WidgetRef ref,
  CreditCardRow card,
  DateTime closing,
) async {
  final accounts = (await ref.read(allAccountsProvider.future))
      .where((item) => item.isActive)
      .toList();
  if (!context.mounted) return;
  int? accountId;
  var saving = false;
  await showDialog<void>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Pagar fatura'),
        content: DropdownButtonFormField<int>(
          initialValue: accountId,
          decoration: const InputDecoration(labelText: 'Conta de pagamento'),
          items: [
            for (final account in accounts)
              DropdownMenuItem(value: account.id, child: Text(account.name)),
          ],
          onChanged: (value) => setState(() => accountId = value),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialog),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (accountId == null) {
                      await _showError(dialog, 'Selecione uma conta.');
                      return;
                    }
                    setState(() => saving = true);
                    try {
                      await ref
                          .read(creditCardRepositoryProvider)
                          .payStatement(
                            cardId: card.id,
                            closingDate: closing,
                            accountId: accountId!,
                          );
                      if (dialog.mounted) Navigator.pop(dialog);
                    } catch (error) {
                      if (dialog.mounted) await _showError(dialog, error);
                      if (dialog.mounted) setState(() => saving = false);
                    }
                  },
            child: const Text('Confirmar pagamento'),
          ),
        ],
      ),
    ),
  );
}
