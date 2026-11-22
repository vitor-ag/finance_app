import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/design/components.dart';
import '../data/android_access.dart';
import '../domain/local_access.dart';
import 'password_form.dart';

class AppAccessGate extends ConsumerWidget {
  const AppAccessGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(localAccessProvider);
    return access == null ? child : _ProtectedApp(access: access, child: child);
  }
}

class _ProtectedApp extends StatefulWidget {
  const _ProtectedApp({required this.access, required this.child});

  final LocalAccess access;
  final Widget child;

  @override
  State<_ProtectedApp> createState() => _ProtectedAppState();
}

class _ProtectedAppState extends State<_ProtectedApp> {
  late final AppLifecycleListener _lifecycle;
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _covered = state != null && state != AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(onStateChange: _lifecycleChanged);
    Future.microtask(() {
      if (mounted) widget.access.load();
    });
  }

  void _lifecycleChanged(AppLifecycleState state) {
    final access = widget.access;
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        access.enteredBackground();
      case AppLifecycleState.resumed:
        access.resumed();
      case AppLifecycleState.inactive:
        break;
    }
    setState(() => _covered = state != AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.access.unlocked) {
      return Overlay.wrap(child: _AccessScreen(access: widget.access));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: _covered,
          child: ExcludeFocus(
            excluding: _covered,
            child: TickerMode(enabled: !_covered, child: widget.child),
          ),
        ),
        if (_covered)
          Scaffold(backgroundColor: Theme.of(context).colorScheme.surface),
      ],
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }
}

class _AccessScreen extends StatefulWidget {
  const _AccessScreen({required this.access});

  final LocalAccess access;

  @override
  State<_AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<_AccessScreen> {
  String? _biometricMessage;

  Future<void> _useBiometrics({bool enroll = false}) async {
    setState(() => _biometricMessage = null);
    try {
      if (enroll) {
        await widget.access.enableBiometrics();
      } else {
        await widget.access.unlockWithBiometrics();
      }
    } on AccessProblem catch (error) {
      if (mounted) setState(() => _biometricMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _biometricMessage = 'Não foi possível usar a biometria.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = widget.access;
    final theme = Theme.of(context);
    final title = switch (access) {
      LocalAccess(ready: false) => 'Finance App',
      LocalAccess(needsPassword: true) => 'Crie sua senha',
      LocalAccess(offerBiometrics: true) => 'Ativar biometria?',
      _ => 'Bem-vindo de volta',
    };
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                theme.colorScheme.primary.withValues(alpha: .12),
                theme.scaffoldBackgroundColor,
              ),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AppContent(
              maxWidth: 480,
              child: Center(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Center(
                      child: BrandShapes(icon: Symbols.lock_rounded, size: 96),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    if (!access.ready) ...[
                      if (access.loadFailed) ...[
                        const AccessMessage(
                          'Não foi possível abrir a proteção do app.',
                        ),
                        FilledButton(
                          onPressed: access.busy ? null : access.load,
                          child: const Text('Tentar novamente'),
                        ),
                      ] else
                        const Center(child: CircularProgressIndicator()),
                    ] else if (access.offerBiometrics) ...[
                      const Text(
                        'Use uma biometria cadastrada no Android para desbloquear o app.',
                      ),
                      const SizedBox(height: 12),
                      if (_biometricMessage case final message?)
                        AccessMessage(message),
                      FilledButton.icon(
                        onPressed: access.busy
                            ? null
                            : () => _useBiometrics(enroll: true),
                        icon: const Icon(Symbols.fingerprint_rounded),
                        label: const Text('Ativar biometria'),
                      ),
                      TextButton(
                        onPressed: access.busy ? null : access.finishSetup,
                        child: const Text('Agora não'),
                      ),
                    ] else if (access.needsPassword) ...[
                      const Text(
                        'Escolha uma senha de 8 a 128 caracteres para proteger seus dados neste aparelho.',
                      ),
                      const SizedBox(height: 16),
                      PasswordForm(
                        key: const ValueKey(PasswordFormMode.create),
                        access: access,
                        mode: PasswordFormMode.create,
                        buttonLabel: 'Criar senha',
                        onSubmit: (password, _) =>
                            access.createPassword(password),
                      ),
                    ] else ...[
                      PasswordForm(
                        key: const ValueKey(PasswordFormMode.unlock),
                        access: access,
                        mode: PasswordFormMode.unlock,
                        buttonLabel: 'Desbloquear',
                        onSubmit: (password, _) =>
                            access.unlockWithPassword(password),
                      ),
                      if (_biometricMessage case final message?)
                        AccessMessage(message),
                      if (access.biometricsEnabled)
                        OutlinedButton.icon(
                          onPressed: access.busy ? null : _useBiometrics,
                          icon: const Icon(Symbols.fingerprint_rounded),
                          label: const Text('Usar biometria'),
                        ),
                      const ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text('Esqueci minha senha'),
                        children: [
                          Text(
                            'Use a biometria se ela estiver ativada. O app ainda não tem um fluxo de recuperação de senha.',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
