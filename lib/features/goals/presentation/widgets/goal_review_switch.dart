import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/design/components.dart';
import '../../../notifications/data/android_reminder_notifications.dart';
import '../../../notifications/presentation/providers/reminder_providers.dart';
import '../providers/goal_providers.dart';

const _preference = 'goalSavingsReminder';
final _settings = Provider((_) => SharedPreferencesAsync());
final _gateway = Provider<AndroidReminderNotifications?>((ref) {
  final gateway = ref.watch(reminderNotificationsProvider);
  return gateway is AndroidReminderNotifications && gateway.isSupported
      ? gateway
      : null;
});
final _enabled = FutureProvider<bool>(
  (ref) async => await ref.watch(_settings).getBool(_preference) ?? false,
);

final goalReviewSyncProvider = FutureProvider<void>((ref) async {
  final gateway = ref.watch(_gateway);
  if (gateway == null) return;
  final enabled = ref.watch(_enabled).valueOrNull;
  if (enabled == null) return;
  if (!enabled) {
    await gateway.syncGoalReview(null);
    return;
  }
  final plans = ref.watch(goalPlansProvider).valueOrNull;
  if (plans == null) return;
  final now = DateTime.now();
  DateTime? when;
  for (final plan in plans.where((item) => item.leftThisMonth > BigInt.zero)) {
    final end = plan.checkpoint;
    var checkpoint = DateTime(now.year, now.month, 25, 19);
    var deadline = DateTime(end.year, end.month, end.day, 19);
    if (!deadline.isAfter(now)) {
      deadline = DateTime(now.year, now.month + 1, 0, 19);
    }
    if (!checkpoint.isAfter(now) || deadline.isBefore(checkpoint))
      checkpoint = deadline;
    if (!checkpoint.isAfter(now)) continue;
    if (when == null || checkpoint.isBefore(when)) when = checkpoint;
  }
  await gateway.syncGoalReview(when);
});

class GoalReviewSwitch extends ConsumerStatefulWidget {
  const GoalReviewSwitch({super.key});

  @override
  ConsumerState<GoalReviewSwitch> createState() => _GoalReviewSwitchState();
}

class _GoalReviewSwitchState extends ConsumerState<GoalReviewSwitch> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final gateway = ref.watch(_gateway);
    if (gateway == null) return const SizedBox.shrink();
    final enabled = ref.watch(_enabled).valueOrNull;
    return AppSurface(
      child: SwitchListTile(
        value: enabled ?? false,
        title: const Text('Aviso de economia para metas'),
        subtitle: const Text(
          'Receba um aviso se ainda faltar guardar dinheiro perto do fim do mês ou do prazo.',
        ),
        onChanged: _saving || enabled == null
            ? null
            : (value) async {
                setState(() => _saving = true);
                try {
                  final settings = ref.read(_settings);
                  if (value && !await gateway.allowGoalReview()) {
                    throw StateError(
                      'Autorize as notificações nos ajustes do Android.',
                    );
                  }
                  await settings.setBool(_preference, value);
                  if (mounted) ref.invalidate(_enabled);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error is StateError
                              ? error.message
                              : 'Não foi possível ajustar o aviso.',
                        ),
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
      ),
    );
  }
}
