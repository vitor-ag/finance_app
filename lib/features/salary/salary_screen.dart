import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/calendar.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/components.dart';
import '../../core/money.dart';
import '../../core/widgets/record_actions.dart';
import '../accounts/presentation/providers/account_providers.dart';
import '../recurrences/domain/entities/recurrence.dart';
import '../recurrences/presentation/providers/recurrence_providers.dart';
import '../recurrences/presentation/screens/recurrences_screen.dart';
import '../transactions/domain/entities/transaction.dart';
import '../transactions/presentation/providers/transaction_providers.dart';
import 'salary_payment.dart';

Future<void> showSalaryPaymentForm(
  BuildContext context, {
  Transaction? entry,
}) => showAppBottomSheet<void>(
  context: context,
  builder: (_) => _SalaryForm(entry: entry),
);

class SalaryScreen extends ConsumerWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(allTransactionsProvider);
    void edit([Transaction? entry]) =>
        showSalaryPaymentForm(context, entry: entry);
    return Scaffold(
      appBar: AppBar(title: const Text('Salário')),
      body: AppContent(
        maxWidth: AppLayout.maxReading,
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            title: 'Não foi possível carregar os pagamentos.',
            actionLabel: 'Tentar novamente',
            onAction: () => ref.invalidate(allTransactionsProvider),
          ),
          data: (all) {
            final payments = all
                .where(
                  (item) =>
                      item.type == 'income' &&
                      item.incomeSource == salaryIncomeSource &&
                      item.status != 'cancelled',
                )
                .toList();
            payments.sort((a, b) {
              final byStatus = (a.status == 'pending' ? 0 : 1).compareTo(
                b.status == 'pending' ? 0 : 1,
              );
              if (byStatus != 0) return byStatus;
              return a.status == 'pending'
                  ? a.date.compareTo(b.date)
                  : b.date.compareTo(a.date);
            });
            return ListView(
              padding: AppLayout.pagePadding(context),
              children: [
                const Text(
                  'Cadastre cada parcela na data em que você recebe. Use os valores da parcela e os descontos do holerite.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: edit,
                      icon: const Icon(Symbols.add_rounded),
                      label: const Text('Adicionar parcela'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecurrencesScreen(),
                        ),
                      ),
                      child: const Text('Gerenciar recorrências'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (payments.isEmpty)
                  const EmptyState(
                    title: 'Nenhuma parcela cadastrada.',
                    compact: true,
                  ),
                for (final item in payments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppSurface(
                      onTap: () => edit(item),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.description ?? 'Salário'),
                                Text(
                                  '${DateFormat.yMd('pt_BR').format(item.date)} · ${item.status == 'paid' ? 'Recebido' : 'Previsto'}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: MoneyText(
                              item.amountCents,
                              kind: MoneyKind.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SalaryForm extends ConsumerStatefulWidget {
  const _SalaryForm({this.entry});
  final Transaction? entry;

  @override
  ConsumerState<_SalaryForm> createState() => _SalaryFormState();
}

class _SalaryFormState extends ConsumerState<_SalaryForm> {
  final _form = GlobalKey<FormState>();
  late final _previousAmounts = SalaryPayment.fromNote(widget.entry?.note);
  late final _label = TextEditingController(text: widget.entry?.description);
  late final _gross = TextEditingController(
    text: widget.entry == null
        ? ''
        : brlInput(_previousAmounts?.gross ?? widget.entry!.amountCents),
  );
  late final _variable = TextEditingController(
    text: brlInput(_previousAmounts?.variable ?? 0),
  );
  late final _discounts = TextEditingController(
    text: brlInput(_previousAmounts?.deductions ?? 0),
  );
  late DateTime _date = calendarDate(widget.entry?.date ?? DateTime.now());
  late int? _account = widget.entry?.accountId;
  late bool _received = widget.entry?.status == 'paid';
  bool _repeat = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final field in [_label, _gross, _variable, _discounts]) {
      field.dispose();
    }
    super.dispose();
  }

  SalaryPayment? get _amounts {
    final gross = parseBrlCents(_gross.text);
    final extra = parseBrlCents(_variable.text);
    final discounts = parseBrlCents(_discounts.text);
    if (gross == null || extra == null || discounts == null) return null;
    return SalaryPayment(gross: gross, variable: extra, deductions: discounts);
  }

  Future<void> _save(int account) async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final amounts = _amounts!..validate();
      if (_repeat && amounts.variable != 0) {
        throw StateError(
          'Registre o variável em uma parcela avulsa ou ajuste o pagamento quando receber.',
        );
      }
      final old = widget.entry;
      final entry = Transaction(
        id: old?.id,
        type: 'income',
        amountCents: amounts.net,
        date: _date,
        accountId: account,
        categoryId: old?.categoryId,
        description: _label.text.trim(),
        incomeSource: salaryIncomeSource,
        note: amounts.note,
        photo: old?.photo,
        status: _received ? 'paid' : 'pending',
        createdAt: old?.createdAt ?? DateTime.now(),
        recurrenceId: old?.recurrenceId,
      );
      final ledger = ref.read(transactionRepositoryProvider);
      if (old != null) {
        await ledger.updateTransaction(entry);
      } else if (_repeat) {
        await ref
            .read(recurrenceRepositoryProvider)
            .createRecurrence(
              Recurrence(
                name: entry.description!,
                type: 'income',
                amountCents: entry.amountCents,
                accountId: account,
                description: entry.description,
                frequency: 'monthly',
                startDate: _date,
                nextOccurrenceDate: _date,
                createdAt: entry.createdAt,
              ),
              first: entry,
            );
      } else {
        await ledger.createTransaction(entry);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showRecordError(context, error, 'Não foi possível salvar a parcela.');
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = (ref.watch(allAccountsProvider).valueOrNull ?? [])
        .where(
          (item) => item.isAvailableCash || item.id == widget.entry?.accountId,
        )
        .toList();
    final account = accounts.any((item) => item.id == _account)
        ? _account
        : accounts.length == 1
        ? accounts.single.id
        : null;
    final amounts = _amounts;
    final future = _date.isAfter(calendarDate(DateTime.now()));
    return Form(
      key: _form,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          Text(
            widget.entry == null
                ? 'Nova parcela de salário'
                : 'Editar parcela de salário',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _label,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Adiantamento ou pagamento final',
            ),
            validator: (value) =>
                value?.trim().isNotEmpty == true ? null : 'Informe o nome.',
          ),
          DropdownButtonFormField<int>(
            initialValue: account,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Conta de recebimento',
            ),
            items: [
              for (final item in accounts)
                DropdownMenuItem(value: item.id, child: Text(item.name)),
            ],
            onChanged: (value) => setState(() => _account = value),
          ),
          OutlinedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                initialDate: _date,
              );
              if (!mounted || date == null) return;
              setState(() {
                _date = date;
                if (date.isAfter(calendarDate(DateTime.now())))
                  _received = false;
              });
            },
            child: Text(
              'Data de pagamento · ${DateFormat.yMd('pt_BR').format(_date)}',
            ),
          ),
          for (final (name, controller) in [
            ('Bruto desta parcela', _gross),
            ('Variável desta parcela', _variable),
            ('Descontos nesta parcela', _discounts),
          ])
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: name,
                  prefixText: 'R\$ ',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) => (parseBrlCents(value) ?? -1) < 0
                    ? 'Informe zero ou um valor válido.'
                    : null,
              ),
            ),
          const SizedBox(height: 8),
          if (amounts != null) ...[
            const Text('Líquido'),
            MoneyText(amounts.net),
          ],
          if (widget.entry == null)
            SwitchListTile(
              title: const Text('Repetir todo mês'),
              subtitle: const Text(
                'O valor fixo fica previsto até você confirmar cada crédito.',
              ),
              value: _repeat,
              onChanged: (value) => setState(() {
                _repeat = value;
                if (value) _received = false;
              }),
            ),
          SwitchListTile(
            title: const Text('Já recebi'),
            value: _received,
            onChanged: future || _repeat
                ? null
                : (value) => setState(() => _received = value),
          ),
          if (accounts.isEmpty)
            const Text('Cadastre uma conta disponível para receber a parcela.'),
          FilledButton(
            onPressed: account == null || _saving ? null : () => _save(account),
            child: const Text('Salvar parcela'),
          ),
        ],
      ),
    );
  }
}
