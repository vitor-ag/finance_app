import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/calendar.dart';
import '../../../core/providers/database_provider.dart';
import '../data/cash_forecast_repository.dart';
import '../domain/cash_forecast.dart';

final cashForecastDateProvider = Provider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  final today = calendarDate(now);
  final timer = Timer(
    forecastDateAt(today, 1).difference(now),
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);
  return today;
});

final cashForecastProvider = StreamProvider.autoDispose<CashForecast>((ref) {
  final today = ref.watch(cashForecastDateProvider);
  return CashForecastRepository(ref.watch(databaseProvider)).watch(today);
});
