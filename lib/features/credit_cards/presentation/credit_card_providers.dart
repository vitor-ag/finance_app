import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../data/local/database.dart';
import '../data/credit_card_repository.dart';

final creditCardRepositoryProvider = Provider<CreditCardRepository>(
  (ref) => CreditCardRepository(ref.watch(databaseProvider)),
);
final creditCardsProvider = StreamProvider<List<CreditCardRow>>(
  (ref) => ref.watch(creditCardRepositoryProvider).watchCards(),
);
final cardPurchasesProvider = StreamProvider<List<CardPurchaseRow>>(
  (ref) => ref.watch(creditCardRepositoryProvider).watchPurchases(),
);
final cardInstallmentsProvider = StreamProvider<List<CardInstallmentRow>>(
  (ref) => ref.watch(creditCardRepositoryProvider).watchInstallments(),
);
