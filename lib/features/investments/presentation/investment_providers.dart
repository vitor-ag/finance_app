import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../notifications/data/android_reminder_notifications.dart';
import '../../notifications/presentation/providers/reminder_providers.dart';
import '../data/investment_repository.dart';
import '../domain/investment_portfolio.dart';

final investmentRepositoryProvider = Provider(
  (ref) => InvestmentRepository(ref.watch(databaseProvider)),
);

final investmentPortfolioProvider =
    StreamProvider.autoDispose<InvestmentPortfolio>(
      (ref) => ref.watch(investmentRepositoryProvider).watchPortfolio(),
    );

final investmentReminderGatewayProvider =
    Provider<AndroidReminderNotifications?>((ref) {
      final gateway = ref.watch(reminderNotificationsProvider);
      return gateway is AndroidReminderNotifications && gateway.isSupported
          ? gateway
          : null;
    });

final investmentReminderProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final gateway = ref.watch(investmentReminderGatewayProvider);
  return await gateway?.hasInvestmentReminder() ?? false;
});
