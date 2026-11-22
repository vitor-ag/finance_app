import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/calendar.dart';
import '../../../core/design/components.dart';
import '../../../core/money.dart';
import '../../../core/widgets/record_actions.dart';
import '../../../data/local/database.dart';
import '../domain/investment_portfolio.dart';
import 'investment_providers.dart';

Future<int?> showInvestmentForm(
  BuildContext context, {
  InvestmentRow? investment,
}) => showAppBottomSheet(
  context: context,
  builder: (_) => _InvestmentForm(investment: investment),
);

Future<bool?> showInvestmentMovement(
  BuildContext context,
  InvestmentPosition position,
  InvestmentMovementKind kind,
  List<AccountRow> accounts,
) => showAppBottomSheet(
  context: context,
  builder: (_) =>
      _MovementForm(position: position, kind: kind, accounts: accounts),
);

class _InvestmentForm extends ConsumerStatefulWidget {
  const _InvestmentForm({this.investment});

  final InvestmentRow? investment;

  @override
  ConsumerState<_InvestmentForm> createState() => _InvestmentFormState();
}

class _InvestmentFormState extends ConsumerState<_InvestmentForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.investment?.name);
  late final _institution = TextEditingController(
    text: widget.investment?.institution,
  );
  late final _kind = TextEditingController(text: widget.investment?.kind);
  final _value = TextEditingController(text: '0,00');
  final _redeemable = TextEditingController(text: '0,00');
  DateTime _date = calendarDate(DateTime.now());
  bool _saving = false;

  @override
  void dispose() {
    for (final field in [_name, _institution, _kind, _value, _redeemable]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(investmentRepositoryProvider);
      var id = widget.investment?.id;
      if (id == null) {
        id = await repo.create(
          name: _name.text,
          institution: _institution.text,
          kind: _kind.text,
          date: _date,
          cents: parseBrlCents(_value.text)!,
          redeemable: parseBrlCents(_redeemable.text)!,
        );
      } else {
        await repo.updateDetails(
          id,
          name: _name.text,
          institution: _institution.text,
          kind: _kind.text,
        );
      }
      if (mounted) {
        ref.invalidate(investmentPortfolioProvider);
        Navigator.pop(context, id);
      }
    } catch (error) {
      if (!mounted) return;
      showRecordError(
        context,
        error,
        'Não foi possível salvar o investimento.',
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = widget.investment == null;
    return _FormFrame(
      form: _form,
      title: creating ? 'Novo investimento' : 'Editar investimento',
      saving: _saving,
      onSave: _save,
      fields: [
        TextFormField(
          controller: _name,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Nome'),
          validator: (value) =>
              value?.trim().isNotEmpty == true ? null : 'Informe o nome.',
        ),
        TextFormField(
          controller: _kind,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'Tipo',
            hintText: 'CDB, Tesouro Direto, fundo, ação…',
          ),
          validator: (value) =>
              value?.trim().isNotEmpty == true ? null : 'Informe o tipo.',
        ),
        TextFormField(
          controller: _institution,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Instituição (opcional)',
          ),
        ),
        if (creating) ...[
          Text(
            'Cadastre uma posição que você já possui ou comece com zero e registre o primeiro aporte.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _DateField(
            date: _date,
            firstDate: DateTime(1900),
            onChanged: (value) => setState(() => _date = value),
          ),
          _AmountField(controller: _value, label: 'Valor bruto da posição'),
          _AmountField(
            controller: _redeemable,
            label: 'Resgatável hoje (líquido)',
          ),
        ],
      ],
    );
  }
}

class _MovementForm extends ConsumerStatefulWidget {
  const _MovementForm({
    required this.position,
    required this.kind,
    required this.accounts,
  });

  final InvestmentPosition position;
  final InvestmentMovementKind kind;
  final List<AccountRow> accounts;

  @override
  ConsumerState<_MovementForm> createState() => _MovementFormState();
}

class _MovementFormState extends ConsumerState<_MovementForm> {
  final _form = GlobalKey<FormState>();
  bool get _valuation => widget.kind == InvestmentMovementKind.valuation;
  bool get _redemption => widget.kind == InvestmentMovementKind.redemption;
  InvestmentMovementRow get _latest => widget.position.latest;
  late final _gross = TextEditingController(
    text: _valuation ? brlInput(_latest.valueCents) : '',
  );
  final _cash = TextEditingController();
  late final _redeemable = TextEditingController(
    text: brlInput(_latest.redeemableCents),
  );
  late int? _account = widget.accounts.length == 1
      ? widget.accounts.single.id
      : null;
  DateTime _date = calendarDate(DateTime.now());
  bool _editedCash = false, _editedRedeemable = false, _saving = false;

  @override
  void dispose() {
    _gross.dispose();
    _cash.dispose();
    _redeemable.dispose();
    super.dispose();
  }

  void _suggestRedeemable() {
    if (_editedRedeemable || !_redemption) return;
    final gross = parseBrlCents(_gross.text) ?? 0;
    final cash = parseBrlCents(_cash.text) ?? 0;
    final remainingValue = math.max(0, _latest.valueCents - gross);
    final remainingAvailable = math.max(0, _latest.redeemableCents - cash);
    _redeemable.text = brlInput(math.min(remainingValue, remainingAvailable));
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(investmentRepositoryProvider);
      final id = widget.position.investment.id;
      final gross = parseBrlCents(_gross.text)!;
      final redeemable = parseBrlCents(_redeemable.text)!;
      if (_valuation) {
        await repo.recordValuation(
          id,
          date: _date,
          value: gross,
          redeemable: redeemable,
          expectedMovementId: _latest.id,
        );
      } else {
        await repo.moveCash(
          id,
          kind: widget.kind,
          accountId: _account!,
          date: _date,
          gross: gross,
          cash: _redemption ? parseBrlCents(_cash.text)! : gross,
          redeemable: redeemable,
          expectedMovementId: _latest.id,
        );
      }
      if (mounted) {
        ref.invalidate(investmentPortfolioProvider);
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      showRecordError(
        context,
        error,
        'Não foi possível registrar a movimentação.',
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.kind) {
      InvestmentMovementKind.valuation => 'Atualizar posição',
      InvestmentMovementKind.redemption => 'Registrar resgate',
      _ => 'Registrar aporte',
    };
    return _FormFrame(
      form: _form,
      title: title,
      saving: _saving,
      onSave: _save,
      fields: [
        if (_valuation)
          Text(
            'Use os valores do extrato na data de referência. Informe zero se a posição estiver indisponível para resgate.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        _DateField(
          date: _date,
          firstDate: calendarDate(_latest.date),
          onChanged: (value) => setState(() => _date = value),
        ),
        if (!_valuation)
          DropdownButtonFormField<int>(
            initialValue: _account,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: _redemption ? 'Conta de destino' : 'Conta de origem',
            ),
            items: [
              for (final item in widget.accounts)
                DropdownMenuItem(value: item.id, child: Text(item.name)),
            ],
            onChanged: (value) => setState(() => _account = value),
            validator: (value) => value == null ? 'Selecione uma conta.' : null,
          ),
        _AmountField(
          controller: _gross,
          label: _valuation
              ? 'Valor bruto da posição'
              : _redemption
              ? 'Valor bruto resgatado'
              : 'Valor do aporte',
          positive: !_valuation,
          onChanged: (value) {
            if (_redemption && !_editedCash) _cash.text = value;
            _suggestRedeemable();
          },
        ),
        if (_redemption)
          _AmountField(
            controller: _cash,
            label: 'Valor líquido creditado',
            onChanged: (_) {
              _editedCash = true;
              _suggestRedeemable();
            },
          ),
        _AmountField(
          controller: _redeemable,
          label: _valuation
              ? 'Resgatável hoje (líquido)'
              : 'Resgatável após a movimentação',
          onChanged: (_) => _editedRedeemable = true,
        ),
      ],
    );
  }
}

class _FormFrame extends StatelessWidget {
  const _FormFrame({
    required this.form,
    required this.title,
    required this.saving,
    required this.onSave,
    required this.fields,
  });

  final GlobalKey<FormState> form;
  final String title;
  final bool saving;
  final VoidCallback onSave;
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: ListView(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        for (final field in fields)
          Padding(padding: const EdgeInsets.only(top: 12), child: field),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: saving ? null : onSave,
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    this.positive = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool positive;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label, prefixText: 'R\$ '),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: onChanged,
    validator: (value) {
      final amount = parseBrlCents(value);
      if (amount == null || amount < 0 || (positive && amount == 0)) {
        return positive
            ? 'Informe um valor maior que zero.'
            : 'Informe zero ou um valor válido.';
      }
      return null;
    },
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.firstDate,
    required this.onChanged,
  });

  final DateTime date, firstDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: firstDate,
        lastDate: DateTime.now(),
        helpText: 'Data de referência',
      );
      if (context.mounted && picked != null) onChanged(picked);
    },
    icon: const Icon(Symbols.event_rounded),
    label: Text('Data do registro · ${DateFormat.yMd('pt_BR').format(date)}'),
  );
}
