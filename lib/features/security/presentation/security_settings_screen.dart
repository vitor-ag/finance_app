import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/android_access.dart';
import '../domain/local_access.dart';
import 'password_form.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(localAccessProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          if (access != null)
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Segurança'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => _SecurityScreen(access: access),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SecurityScreen extends StatefulWidget {
  const _SecurityScreen({required this.access});

  final LocalAccess access;

  @override
  State<_SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<_SecurityScreen> {
  late final AppLifecycleListener _lifecycle;
  late Future<bool> _available;

  LocalAccess get _access => widget.access;

  @override
  void initState() {
    super.initState();
    _available = _access.biometricsAvailable();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        final available = _access.biometricsAvailable();
        setState(() {
          _available = available;
        });
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _openPasswordPage(PasswordFormMode mode) async {
    final changed = mode == PasswordFormMode.change;
    final title = changed ? 'Alterar senha' : 'Ativar biometria';
    final navigator = Navigator.of(context);
    final saved = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (pageContext) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!changed) ...[
                const Text('Confirme a senha do app para ativar a biometria.'),
                const SizedBox(height: 16),
              ],
              PasswordForm(
                access: _access,
                mode: mode,
                buttonLabel: changed ? 'Salvar senha' : 'Confirmar senha',
                onSubmit: (current, replacement) async {
                  if (changed) {
                    await _access.changePassword(current, replacement!);
                  } else {
                    await _access.enableBiometrics(currentPassword: current);
                  }
                  if (pageContext.mounted &&
                      ModalRoute.of(pageContext)?.isCurrent == true &&
                      _access.unlocked &&
                      (changed || _access.biometricsEnabled)) {
                    Navigator.of(pageContext).pop(true);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted && saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(changed ? 'Senha alterada.' : 'Biometria ativada.'),
        ),
      );
    }
  }

  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar a configuração.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _access,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Segurança')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.password),
            title: const Text('Alterar senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _access.busy
                ? null
                : () => _openPasswordPage(PasswordFormMode.change),
          ),
          FutureBuilder<bool>(
            future: _available,
            builder: (context, snapshot) {
              final available = snapshot.data ?? false;
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Desbloqueio por biometria'),
                subtitle: Text(
                  available
                      ? 'Use uma biometria cadastrada no Android.'
                      : 'Biometria forte indisponível neste aparelho.',
                ),
                value: _access.biometricsEnabled,
                onChanged:
                    _access.busy || (!available && !_access.biometricsEnabled)
                    ? null
                    : (enabled) {
                        if (enabled) {
                          _openPasswordPage(PasswordFormMode.confirm);
                        } else {
                          _save(_access.disableBiometrics);
                        }
                      },
              );
            },
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Bloqueio automático',
              helperText: 'Tempo fora do app antes de solicitar desbloqueio.',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Duration>(
                isDense: true,
                isExpanded: true,
                value: _access.lockDelay,
                items: [
                  for (final option in lockDelayOptions.entries)
                    DropdownMenuItem(
                      value: option.key,
                      child: Text(option.value),
                    ),
                ],
                onChanged: _access.busy
                    ? null
                    : (delay) {
                        if (delay != null) {
                          _save(() => _access.setLockDelay(delay));
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
