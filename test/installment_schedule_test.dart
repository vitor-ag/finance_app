import 'package:finance_app/features/credit_cards/domain/installment_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'distributes cents and follows statement closing across short months',
    () {
      final installments = scheduleInstallments(
        totalCents: 10000,
        count: 3,
        purchaseDate: DateTime(2024, 1, 31),
        closingDay: 31,
        dueDay: 10,
      );
      expect(installments.map((item) => item.amountCents), [3334, 3333, 3333]);
      expect(installments.map((item) => item.closingDate), [
        DateTime(2024, 1, 31),
        DateTime(2024, 2, 29),
        DateTime(2024, 3, 31),
      ]);
      expect(installments.map((item) => item.dueDate), [
        DateTime(2024, 2, 10),
        DateTime(2024, 3, 10),
        DateTime(2024, 4, 10),
      ]);
    },
  );

  test('purchases after closing enter the following statement', () {
    final item = scheduleInstallments(
      totalCents: 100,
      count: 1,
      purchaseDate: DateTime(2025, 12, 21),
      closingDay: 20,
      dueDay: 28,
    ).single;
    expect(item.closingDate, DateTime(2026, 1, 20));
    expect(item.dueDate, DateTime(2026, 1, 28));
  });
}
