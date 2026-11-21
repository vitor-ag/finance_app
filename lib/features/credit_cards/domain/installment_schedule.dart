import '../../../core/calendar.dart';
import '../../../core/money.dart';

class ScheduledInstallment {
  const ScheduledInstallment({
    required this.number,
    required this.amountCents,
    required this.closingDate,
    required this.dueDate,
  });

  final int number;
  final int amountCents;
  final DateTime closingDate;
  final DateTime dueDate;
}

/// Purchases on the closing date are included in that statement.
List<ScheduledInstallment> scheduleInstallments({
  required int totalCents,
  required int count,
  required DateTime purchaseDate,
  required int closingDay,
  required int dueDay,
}) {
  validatePositiveCents(totalCents);
  if (count < 1 || count > 120 || count > totalCents) {
    throw StateError('Informe uma quantidade válida de parcelas.');
  }
  if (closingDay < 1 || closingDay > 31 || dueDay < 1 || dueDay > 31) {
    throw StateError('Informe dias de fechamento e vencimento válidos.');
  }
  final date = calendarDate(purchaseDate);
  final firstClosing = dateWithClampedDay(date.year, date.month, closingDay);
  final firstMonth = date.isAfter(firstClosing) ? date.month + 1 : date.month;
  final base = totalCents ~/ count;
  final remainder = totalCents % count;
  return List.generate(count, (index) {
    final closing = dateWithClampedDay(
      date.year,
      firstMonth + index,
      closingDay,
    );
    var due = dateWithClampedDay(closing.year, closing.month, dueDay);
    if (!due.isAfter(closing)) {
      due = dateWithClampedDay(closing.year, closing.month + 1, dueDay);
    }
    return ScheduledInstallment(
      number: index + 1,
      amountCents: base + (index < remainder ? 1 : 0),
      closingDate: closing,
      dueDate: due,
    );
  });
}
