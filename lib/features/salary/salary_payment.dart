import '../../core/money.dart';

const salaryIncomeSource = 'Salário (folha)';

class SalaryPayment {
  const SalaryPayment({
    required this.gross,
    required this.variable,
    required this.deductions,
  });

  final int gross, variable, deductions;

  int get net => gross + variable - deductions;

  void validate() {
    if (gross < 0 ||
        variable < 0 ||
        deductions < 0 ||
        gross + variable > maxMoneyCents ||
        net <= 0) {
      throw StateError(
        'Confira os valores. O líquido deve ser maior que zero.',
      );
    }
  }

  String get note =>
      'Bruto: ${brlInput(gross)}\nVariável: ${brlInput(variable)}\nDescontos: ${brlInput(deductions)}';

  static SalaryPayment? fromNote(String? note) {
    final match = RegExp(
      r'^Bruto: ([^\n]+)\nVariável: ([^\n]+)\nDescontos: ([^\n]+)$',
    ).firstMatch(note ?? '');
    final gross = parseBrlCents(match?.group(1));
    final variable = parseBrlCents(match?.group(2));
    final deductions = parseBrlCents(match?.group(3));
    if (gross == null || variable == null || deductions == null) return null;
    return SalaryPayment(
      gross: gross,
      variable: variable,
      deductions: deductions,
    );
  }
}
