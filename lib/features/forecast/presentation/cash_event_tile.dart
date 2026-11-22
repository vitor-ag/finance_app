import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/components.dart';
import '../domain/cash_forecast.dart';

class CashEventTile extends StatelessWidget {
  const CashEventTile({
    super.key,
    required this.event,
    required this.delta,
    required this.today,
    this.showDate = false,
    this.onTap,
  });

  final CashEvent event;
  final BigInt delta;
  final DateTime today;
  final bool showDate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (event.source) {
      CashEventSource.bill => ('Conta a pagar', Symbols.event_rounded),
      CashEventSource.repeatingBill => (
        'Conta recorrente prevista',
        Symbols.repeat_rounded,
      ),
      CashEventSource.statement => ('Fatura', Symbols.credit_card_rounded),
      CashEventSource.scheduled => (
        'Agendado',
        Symbols.event_available_rounded,
      ),
      CashEventSource.recurrence => (
        'Recorrência prevista',
        Symbols.repeat_rounded,
      ),
    };
    final overdue = event.date.isBefore(today);
    final date = DateFormat.Md('pt_BR').format(event.date);
    final detail = [
      label,
      if (overdue)
        (delta.isNegative ? 'Vencido em $date' : 'Previsto em $date')
      else if (showDate)
        date,
    ].join(' · ');
    final kind = delta.isNegative ? MoneyKind.expense : MoneyKind.income;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final amount = MoneyText.total(
      delta,
      kind: kind,
      signed: true,
      alignment: largeText ? Alignment.centerLeft : Alignment.centerRight,
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppIcon(
        icon,
        color: overdue && delta.isNegative
            ? AppColors.of(context).expenseText
            : null,
      ),
      title: Text(event.title),
      subtitle: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(detail), amount],
            )
          : Text(detail),
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
