const maxMoneyCents = 9000000000000000;

final _decimalAmount = RegExp(r'^([+-]?)(\d+)(?:[,.](\d{1,2}))?$');

int? parseBrlCents(String? input) {
  final match = _decimalAmount.firstMatch(input?.trim() ?? '');
  if (match == null) return null;
  final cents = int.tryParse(match[2]! + (match[3] ?? '').padRight(2, '0'));
  if (cents == null || cents > maxMoneyCents) return null;
  return match[1] == '-' ? -cents : cents;
}

String brlInput(int cents) => _decimalText(cents.toString());

String formatBrl(int cents) => 'R\$ ${brlInput(cents)}';

String formatBrlSum(BigInt cents) => 'R\$ ${_decimalText(cents.toString())}';

String formatBrlTotal(Iterable<int> amounts) {
  final sum = amounts.fold(
    BigInt.zero,
    (total, amount) => total + BigInt.from(amount),
  );
  return formatBrlSum(sum);
}

String _decimalText(String cents) {
  final negative = cents.startsWith('-');
  final digits = (negative ? cents.substring(1) : cents).padLeft(3, '0');
  final split = digits.length - 2;
  return '${negative ? '-' : ''}${digits.substring(0, split)},${digits.substring(split)}';
}

void validateBalanceCents(int cents) {
  if (cents < -maxMoneyCents || cents > maxMoneyCents) {
    throw StateError('O saldo ultrapassa o limite de valores do aplicativo.');
  }
}

void validatePositiveCents(int cents) {
  if (cents <= 0 || cents > maxMoneyCents) {
    throw StateError(
      'Informe um valor positivo dentro do limite do aplicativo.',
    );
  }
}
