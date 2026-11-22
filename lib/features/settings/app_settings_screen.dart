import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/design/adaptive_scaffold.dart';
import '../../core/design/app_preferences.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/components.dart';
import '../../core/design/discreet_setting.dart';
import '../accounts/presentation/screens/accounts_screen.dart';
import '../backup/presentation/local_backup_screen.dart';
import '../bills/presentation/screens/bills_screen.dart';
import '../categories/presentation/screens/categories_screen.dart';
import '../credit_cards/presentation/credit_cards_screen.dart';
import '../notifications/presentation/screens/reminder_settings_screen.dart';
import '../recurrences/presentation/screens/recurrences_screen.dart';
import '../security/data/android_access.dart';
import '../security/presentation/security_settings_screen.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  int _group = 0;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(localAccessProvider);
    final wide = WindowSizeClass.of(context) != WindowSizeClass.compact;
    final groups = <(String, IconData, Widget)>[
      (
        'Contas e cartões',
        Symbols.account_balance_wallet_rounded,
        const _AccountsAndCards(),
      ),
      ('Categorias', Symbols.category_rounded, const CategoriesScreen()),
      (
        'Recorrências e agendados',
        Symbols.event_repeat_rounded,
        const _Schedules(),
      ),
      (
        'Notificações',
        Symbols.notifications_rounded,
        const ReminderSettingsScreen(),
      ),
      (
        'Segurança',
        Symbols.shield_rounded,
        access == null
            ? const _DiscreetSettings()
            : SecurityScreen(access: access),
      ),
      ('Aparência', Symbols.palette_rounded, const _Appearance()),
      (
        'Backup e restauração',
        Symbols.backup_rounded,
        const LocalBackupScreen(),
      ),
      ('Sobre', Symbols.info_rounded, const _About()),
    ];
    final menu = ListView(
      padding: AppLayout.pagePadding(context),
      children: [
        for (final range in [groups.take(4), groups.skip(4)])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppSurface(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (label, icon, screen) in range)
                    ListTile(
                      selected:
                          wide &&
                          _group ==
                              groups.indexWhere((item) => item.$1 == label),
                      selectedTileColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      leading: AppIcon(icon),
                      title: Text(label),
                      trailing: const Icon(Symbols.chevron_right_rounded),
                      onTap: wide
                          ? () => setState(
                              () => _group = groups.indexWhere(
                                (item) => item.$1 == label,
                              ),
                            )
                          : () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(builder: (_) => screen),
                            ),
                    ),
                ],
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: PrivacyLabel(),
        ),
        Text(
          'Você pode ativar backups e escolher onde guardá-los.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: AppContent(
        child: wide
            ? Row(
                children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width < 700 ? 256 : 320,
                    child: menu,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey(_group),
                      child: groups[_group].$3,
                    ),
                  ),
                ],
              )
            : menu,
      ),
    );
  }
}

class _AccountsAndCards extends StatefulWidget {
  const _AccountsAndCards();

  @override
  State<_AccountsAndCards> createState() => _AccountsAndCardsState();
}

class _AccountsAndCardsState extends State<_AccountsAndCards> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Contas e cartões')),
    body: Column(
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final (index, label) in [
              'Contas',
              'Cartões de crédito',
            ].indexed)
              ChoiceChip(
                label: Text(label),
                selected: _tab == index,
                onSelected: (_) => setState(() => _tab = index),
              ),
          ],
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: const [
              AccountsScreen(embedded: true),
              CreditCardsScreen(embedded: true),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Schedules extends StatefulWidget {
  const _Schedules();

  @override
  State<_Schedules> createState() => _SchedulesState();
}

class _SchedulesState extends State<_Schedules> {
  bool _bills = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recorrências e agendados')),
    body: Column(
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Recorrências'),
              selected: !_bills,
              onSelected: (_) => setState(() => _bills = false),
            ),
            ChoiceChip(
              label: const Text('Contas a pagar'),
              selected: _bills,
              onSelected: (_) => setState(() => _bills = true),
            ),
          ],
        ),
        Expanded(
          child: IndexedStack(
            index: _bills ? 1 : 0,
            children: const [
              RecurrencesScreen(embedded: true),
              BillsScreen(embedded: true),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Appearance extends StatelessWidget {
  const _Appearance();

  @override
  Widget build(BuildContext context) {
    final preferences = PreferencesScope.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.brightness == Brightness.light
        ? AppColors.accents
        : AppColors.darkAccents;
    return Scaffold(
      appBar: AppBar(title: const Text('Aparência')),
      body: AppContent(
        maxWidth: AppLayout.maxReading,
        child: ListView(
          padding: AppLayout.pagePadding(context),
          children: [
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (mode, label) in [
                        (ThemeMode.system, 'Automático'),
                        (ThemeMode.light, 'Claro'),
                        (ThemeMode.dark, 'Escuro'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: preferences.theme == mode,
                          onSelected: (_) => preferences.setTheme(mode),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cor de destaque', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (index, label) in [
                        'Violeta',
                        'Azul',
                        'Verde',
                        'Rosa',
                      ].indexed)
                        ChoiceChip(
                          label: Text(label),
                          avatar: Icon(
                            Symbols.circle_rounded,
                            color: colors[index],
                            fill: 1,
                          ),
                          selected: preferences.accent == index,
                          onSelected: (_) => preferences.setAccent(index),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscreetSettings extends StatelessWidget {
  const _DiscreetSettings();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Segurança')),
    body: AppContent(
      maxWidth: AppLayout.maxReading,
      child: ListView(
        padding: AppLayout.pagePadding(context),
        children: const [
          AppSurface(child: DiscreetSetting()),
          SizedBox(height: 12),
          PrivacyLabel(),
        ],
      ),
    ),
  );
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sobre')),
    body: AppContent(
      maxWidth: AppLayout.maxReading,
      child: ListView(
        padding: AppLayout.pagePadding(context),
        children: [
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Finance App',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text('Versão 1.0.0'),
                const SizedBox(height: 12),
                const PrivacyLabel(),
                const SizedBox(height: 8),
                const Text(
                  'O app funciona offline. O Google Drive recebe backups cifrados quando você ativa essa opção.',
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'Finance App',
                    applicationVersion: '1.0.0',
                  ),
                  child: const Text('Ver licenças'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
