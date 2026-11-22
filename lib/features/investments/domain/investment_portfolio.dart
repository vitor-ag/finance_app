import '../../../core/calendar.dart';
import '../../../data/local/database.dart';

enum InvestmentMovementKind { opening, contribution, redemption, valuation }

class InvestmentPosition {
  const InvestmentPosition(this.investment, this.movements);

  final InvestmentRow investment;
  final List<InvestmentMovementRow> movements;

  InvestmentMovementRow get latest => movements.last;
  InvestmentMovementRow get lastValuation => movements.lastWhere(
    (movement) =>
        movement.kind == InvestmentMovementKind.valuation.name ||
        movement.kind == InvestmentMovementKind.opening.name,
  );

  bool needsReview(DateTime now) {
    final month = DateTime(now.year, now.month);
    return investment.isActive &&
        latest.valueCents > 0 &&
        calendarDate(lastValuation.date).isBefore(month);
  }
}

class InvestmentPortfolio {
  const InvestmentPortfolio(
    this.positions,
    this.cashAccounts,
    this.legacyAccounts,
  );

  final List<InvestmentPosition> positions;
  final List<AccountRow> cashAccounts;
  final List<AccountRow> legacyAccounts;

  BigInt get cash => _sum(cashAccounts.map((item) => item.currentBalanceCents));
  BigInt get legacyValue =>
      _sum(legacyAccounts.map((item) => item.currentBalanceCents));
  BigInt get value => _sum(positions.map((item) => item.latest.valueCents));
  BigInt get redeemable =>
      _sum(positions.map((item) => item.latest.redeemableCents));

  InvestmentMonth summarize(DateTime month, {int? investmentId}) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    var opening = BigInt.zero;
    var closing = BigInt.zero;
    var imported = BigInt.zero;
    var contributed = BigInt.zero;
    var redeemed = BigInt.zero;
    var credited = BigInt.zero;
    var variation = BigInt.zero;

    for (final position in positions) {
      if (investmentId != null && investmentId != position.investment.id) {
        continue;
      }
      var before = 0;
      var after = 0;
      for (final movement in position.movements) {
        if (!movement.date.isBefore(end)) break;
        after = movement.valueCents;
        if (movement.date.isBefore(start)) {
          before = after;
          continue;
        }
        final amount = BigInt.from(movement.amountCents);
        switch (InvestmentMovementKind.values.byName(movement.kind)) {
          case InvestmentMovementKind.opening:
            imported += amount;
          case InvestmentMovementKind.contribution:
            contributed += amount;
          case InvestmentMovementKind.redemption:
            redeemed += amount;
            credited += BigInt.from(movement.cashCents);
          case InvestmentMovementKind.valuation:
            variation += amount;
        }
      }
      opening += BigInt.from(before);
      closing += BigInt.from(after);
    }
    return InvestmentMonth(
      opening: opening,
      closing: closing,
      imported: imported,
      contributed: contributed,
      redeemed: redeemed,
      credited: credited,
      variation: variation,
    );
  }
}

class InvestmentMonth {
  const InvestmentMonth({
    required this.opening,
    required this.closing,
    required this.imported,
    required this.contributed,
    required this.redeemed,
    required this.credited,
    required this.variation,
  });

  final BigInt opening, closing, imported, contributed, redeemed, credited;
  final BigInt variation;

  BigInt get redemptionDeductions => redeemed - credited;
  BigInt get netResult => variation - redemptionDeductions;
}

BigInt _sum(Iterable<int> cents) =>
    cents.fold(BigInt.zero, (total, amount) => total + BigInt.from(amount));
