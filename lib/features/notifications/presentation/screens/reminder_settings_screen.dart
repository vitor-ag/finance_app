import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components.dart';
import '../../../../core/widgets/record_actions.dart';
import '../../data/android_reminder_notifications.dart';
import '../../data/planning_reminders.dart';
import '../../domain/reminder_settings.dart';
import '../providers/reminder_providers.dart';

class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supported = ref.watch(reminderNotificationsProvider).isSupported;
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações'), centerTitle: true),
      body: supported
          ? ref
                .watch(reminderSettingsProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                    child: Text('Não foi possível carregar as preferências.'),
                  ),
                  data: (settings) => _ReminderForm(settings: settings),
                )
          : const Center(child: Text('Lembretes disponíveis no Android.')),
    );
  }
}

class _ReminderForm extends ConsumerStatefulWidget {
  const _ReminderForm({required this.settings});

  final ReminderSettings settings;

  @override
  ConsumerState<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends ConsumerState<_ReminderForm> {
  late final AppLifecycleListener _lifecycle;
  late bool _enabled;
  late int _daysBefore;
  late TimeOfDay _time;
  bool? _allowed;
  bool _working = false;
  bool _daily = false;
  bool _budget = false;
  bool _extras = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.settings;
    _enabled = settings.enabled;
    _daysBefore = settings.daysBefore;
    _time = TimeOfDay(
      hour: settings.minuteOfDay ~/ 60,
      minute: settings.minuteOfDay % 60,
    );
    _lifecycle = AppLifecycleListener(onResume: _refreshPermission);
    Future.microtask(_refreshPermission);
    if (ref.read(reminderNotificationsProvider)
        is AndroidReminderNotifications) {
      Future.microtask(_loadPlanning);
    }
  }

  Future<void> _loadPlanning() async {
    try {
      final settings = await ref.read(planningReminderStoreProvider).read();
      if (!mounted) return;
      setState(() {
        _extras = true;
        _daily = settings.daily;
        _budget = settings.budget;
        if (!_enabled && _daily) {
          _time = TimeOfDay(
            hour: settings.minutes ~/ 60,
            minute: settings.minutes % 60,
          );
        }
      });
    } catch (error) {
      if (mounted) {
        showRecordError(
          context,
          error,
          'Não foi possível ler as preferências de planejamento.',
        );
      }
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refreshPermission() async {
    if (!mounted) return;
    try {
      final allowed = await ref.read(reminderNotificationsProvider).isAllowed();
      if (mounted) setState(() => _allowed = allowed);
    } catch (error) {
      if (mounted) {
        showRecordError(
          context,
          error,
          'Não foi possível consultar a permissão de notificações.',
        );
      }
    }
  }

  Future<bool> _ensurePermission() async {
    final gateway = ref.read(reminderNotificationsProvider);
    final allowed =
        await gateway.isAllowed() || await gateway.requestPermission();
    if (mounted) setState(() => _allowed = allowed);
    return allowed;
  }

  Future<void> _perform(Future<String> Function() action) async {
    setState(() => _working = true);
    try {
      final message = await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        showRecordError(
          context,
          error,
          'Não foi possível concluir a configuração.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _save() => _perform(() async {
    final store = ref.read(reminderSettingsStoreProvider);
    final enabled = _enabled;
    final settings = ReminderSettings(
      enabled: enabled,
      daysBefore: _daysBefore,
      minuteOfDay: _time.hour * 60 + _time.minute,
    );
    final allowed =
        !(enabled || _daily || _budget) || await _ensurePermission();
    await store.save(settings);
    if (_extras && mounted) {
      final gateway = ref.read(reminderNotificationsProvider);
      if (gateway is AndroidReminderNotifications) {
        await gateway.setDailyReminder(_daily, settings.minuteOfDay);
      }
      if (mounted) {
        await ref.read(planningReminderStoreProvider).save((
          daily: _daily,
          budget: _budget,
          minutes: settings.minuteOfDay,
        ));
      }
      if (mounted) ref.invalidate(planningPreferencesProvider);
    }
    if (mounted) ref.invalidate(billReminderSyncProvider);
    return allowed
        ? 'Preferências salvas.'
        : 'Preferências salvas. Para receber os lembretes, permita as notificações no Android.';
  });

  Future<void> _test() => _perform(() async {
    final gateway = ref.read(reminderNotificationsProvider);
    if (!await _ensurePermission()) {
      return 'Permita as notificações nas configurações do Android para enviar o teste.';
    }
    await gateway.showTest();
    return 'Notificação de teste enviada.';
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sync = ref.watch(billReminderSyncProvider);
    final hour = _time.hour.toString().padLeft(2, '0');
    final minute = _time.minute.toString().padLeft(2, '0');

    return AppContent(
      maxWidth: AppLayout.maxReading,
      child: ListView(
        padding: AppLayout.pagePadding(context),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lembretes de vencimento'),
            subtitle: const Text('Receba avisos de contas a pagar pendentes.'),
            value: _enabled,
            onChanged: _working
                ? null
                : (enabled) => setState(() => _enabled = enabled),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _daysBefore,
            isExpanded: true,
            menuMaxHeight: 320,
            decoration: const InputDecoration(
              labelText: 'Antecedência',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: 0,
                child: Text('No dia do vencimento'),
              ),
              const DropdownMenuItem(value: 1, child: Text('1 dia antes')),
              for (var day = 2; day <= 30; day++)
                DropdownMenuItem(value: day, child: Text('$day dias antes')),
            ],
            onChanged: !_enabled || _working
                ? null
                : (days) => setState(() => _daysBefore = days!),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Symbols.schedule_rounded),
            title: const Text('Horário do lembrete'),
            subtitle: Text('$hour:$minute'),
            enabled: (_enabled || _daily) && !_working,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
                helpText: 'Horário do lembrete',
                cancelText: 'Cancelar',
                confirmText: 'Confirmar',
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (mounted && picked != null) setState(() => _time = picked);
            },
          ),
          if (_extras) ...[
            const SizedBox(height: 8),
            AppSurface(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const AppIcon(Symbols.notifications_rounded),
                    title: const Text('Lembrete diário'),
                    subtitle: const Text(
                      'Um aviso para registrar os lançamentos do dia.',
                    ),
                    value: _daily,
                    onChanged: _working
                        ? null
                        : (value) => setState(() => _daily = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const AppIcon(Symbols.pie_chart_rounded),
                    title: const Text('Alertas de orçamento'),
                    subtitle: const Text(
                      'Receba um aviso ao chegar a 80% e ao atingir o limite.',
                    ),
                    value: _budget,
                    onChanged: _working
                        ? null
                        : (value) => setState(() => _budget = value),
                  ),
                ],
              ),
            ),
          ],
          if ((_enabled || _daily || _budget) && _allowed == false)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Para receber os lembretes, permita notificações do app nas configurações do Android.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (sync.hasError)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Não foi possível atualizar os lembretes.'),
              trailing: TextButton(
                onPressed: () => ref.invalidate(billReminderSyncProvider),
                child: const Text('Tentar novamente'),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _working ? null : _save,
            child: const Text('Salvar preferências'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _working ? null : _test,
            icon: const Icon(Symbols.notifications_rounded),
            label: const Text('Enviar notificação de teste'),
          ),
        ],
      ),
    );
  }
}
