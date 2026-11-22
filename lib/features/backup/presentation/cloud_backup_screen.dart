import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/components.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/android_drive_backup.dart';
import '../data/backup_drive.dart';
import '../data/backup_snapshot.dart';
import '../data/drive_sync.dart';

class CloudBackupScreen extends ConsumerStatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  ConsumerState<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends ConsumerState<CloudBackupScreen> {
  bool _busy = false;
  String? _message;

  AndroidDriveBackup get _backup => ref.read(driveBackupProvider)!;

  Future<void> _run(Future<String?> Function() operation) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final message = await operation();
      if (mounted) setState(() => _message = message);
    } on BackupProblem catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Não foi possível concluir a operação de backup.',
        );
      }
    } finally {
      if (mounted) {
        ref.invalidate(driveStatusProvider);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _connect({bool choose = true}) => _run(() async {
    await _backup.connect(chooseAccount: choose);
    return choose ? 'Conta Google vinculada.' : 'Acesso ao Drive autorizado.';
  });

  Future<void> _backupNow(DriveStatus state) => _run(() async {
    final password = state.automatic
        ? null
        : await _password(
            title: 'Senha de criptografia',
            detail:
                'Os dados deste aparelho serão enviados ao Drive de ${state.email}. '
                'Se já houver backups, use a mesma senha. Guarde-a para restaurar em outro aparelho.',
            confirm: true,
          );
    if (!state.automatic && password == null) return null;
    if (!mounted) return null;
    await _backup.backupNow(password);
    return null;
  });

  Future<void> _configureAutomatic(
    bool enabled,
    DriveStatus state,
  ) => _run(() async {
    if (!enabled) {
      await _backup.setAutomatic(false);
      return 'Sincronização automática desativada.';
    }
    final password = await _password(
      title: 'Ativar sincronização',
      detail:
          'Este aparelho poderá enviar e importar alterações automaticamente pelo Drive de ${state.email}. '
          'A chave derivada fica protegida pelo Android. Guarde a senha para usar em outro aparelho.',
      confirm: true,
    );
    if (password == null || !mounted) return null;
    await _backup.setAutomatic(true, password: password);
    return null;
  });

  Future<void> _restore(DriveStatus state) => _run(() async {
    final backups = await _backup.list();
    if (!mounted) return null;
    if (backups.isEmpty) return 'Ainda não há backups nesta conta.';
    final heads = backupHeads(backups).map((file) => file.id).toSet();
    final selection = await showAppBottomSheet<DriveBackup>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Escolha um backup',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final file = backups[index];
                  final current = heads.contains(file.id);
                  final label = current
                      ? (heads.length == 1
                            ? 'Versão atual'
                            : 'Versão concorrente')
                      : 'Versão anterior';
                  return ListTile(
                    leading: Icon(
                      current
                          ? Symbols.cloud_done_rounded
                          : Symbols.history_rounded,
                    ),
                    title: Text(_date(file.createdAt)),
                    subtitle: Text(
                      '$label · ${file.id.substring(0, file.id.length.clamp(0, 8))}',
                    ),
                    onTap: () => Navigator.pop(context, file),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selection == null || !mounted) return null;
    final password = await _password(
      title: 'Descriptografar backup',
      detail:
          'Informe a senha do backup de ${_date(selection.createdAt)} em ${state.email}.',
    );
    if (password == null || !mounted) return null;
    final prepared = await _backup.prepareRestore(selection.id, password);
    if (!mounted) return null;
    final accepted = await _confirm(
      title: 'Substituir os dados deste aparelho?',
      description:
          'O backup de ${_date(selection.createdAt)} de ${state.email} '
          'vai substituir os dados locais. Alterações locais que ainda não foram enviadas serão perdidas. '
          'Se esta escolha resolver um conflito ou recuperar uma versão anterior, '
          'ela será publicada como a versão atual da conta.',
      action: 'Restaurar',
    );
    if (!accepted || !mounted) return null;
    return _backup.restore(prepared);
  });

  Future<void> _disconnect() => _run(() async {
    final accepted = await _confirm(
      title: 'Desvincular a conta Google?',
      description: 'A sincronização será desativada neste aparelho. Os dados locais e as cópias no Drive continuam disponíveis.',
      action: 'Desvincular',
    );
    if (!accepted || !mounted) return null;
    await _backup.disconnect();
    return 'Conta desvinculada deste aparelho.';
  });

  Future<bool> _confirm({
    required String title,
    required String description,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<String?> _password({
    required String title,
    required String detail,
    bool confirm = false,
  }) => showDialog<String>(
    context: context,
    builder: (_) =>
        _BackupPassword(title: title, detail: detail, confirm: confirm),
  );

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(driveStatusProvider);
    final state = status.valueOrNull;
    final disabled = _busy || (state == null && status.isLoading);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup em nuvem')),
      body: AppContent(
        maxWidth: AppLayout.maxReading,
        child: ListView(
          padding: AppLayout.pagePadding(context),
          children: [
            if (disabled) const LinearProgressIndicator(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Symbols.cloud_rounded),
              title: Text(state?.email ?? 'Google Drive'),
              subtitle: Text(
                state == null ? 'Nenhuma conta vinculada' : 'Conta vinculada',
              ),
              trailing: TextButton(
                onPressed: disabled ? null : _connect,
                child: Text(state == null ? 'Vincular' : 'Trocar conta'),
              ),
            ),
            const Text(
              'O Drive guarda as cópias criptografadas na área privada do app. '
              'Elas ficam ocultas na lista de arquivos. Remover os dados do app pelo Drive pode excluir as cópias.',
            ),
            if (status.hasError)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Não foi possível abrir as configurações de backup.',
                ),
              ),
            if (state != null) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sincronização automática'),
                subtitle: const Text(
                  'Envia e importa alterações com internet. Em segundo plano, o Android escolhe quando executar.',
                ),
                value: state.automatic,
                onChanged: disabled
                    ? null
                    : (enabled) => _configureAutomatic(enabled, state),
              ),
              Text(
                'Último envio neste aparelho: ${state.lastUpload == null ? '—' : _date(state.lastUpload!)}',
              ),
              Text(
                'Última sincronização concluída: ${state.lastSync == null ? '—' : _date(state.lastSync!)}',
              ),
              if (state.message case final message?)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(liveRegion: true, child: Text(message)),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: disabled ? null : () => _backupNow(state),
                icon: const Icon(Symbols.cloud_upload_rounded),
                label: const Text('Backup agora'),
              ),
              OutlinedButton.icon(
                onPressed: disabled ? null : () => _restore(state),
                icon: const Icon(Symbols.restore_rounded),
                label: const Text('Restaurar backup'),
              ),
              const SizedBox(height: 8),
              const Text(
                'O Drive mantém até $retainedBackupCount versões recentes após um envio confirmado. Versões concorrentes são preservadas até você escolher uma.',
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: disabled ? null : () => _connect(choose: false),
                child: const Text('Autorizar novamente'),
              ),
              TextButton(
                onPressed: disabled ? null : _disconnect,
                child: const Text('Desvincular deste aparelho'),
              ),
            ],
            if (_message case final message? when message != state?.message)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(liveRegion: true, child: Text(message)),
              ),
          ],
        ),
      ),
    );
  }
}

class _BackupPassword extends StatefulWidget {
  const _BackupPassword({
    required this.title,
    required this.detail,
    required this.confirm,
  });

  final String title;
  final String detail;
  final bool confirm;

  @override
  State<_BackupPassword> createState() => _BackupPasswordState();
}

class _BackupPasswordState extends State<_BackupPassword> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();

  void _submit() {
    if (_form.currentState!.validate()) Navigator.pop(context, _password.text);
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.title),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.detail),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Senha do backup'),
            textInputAction: widget.confirm
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: widget.confirm ? null : (_) => _submit(),
            validator: (value) =>
                value == null || value.length < 12 || value.length > 128
                ? 'Use de 12 a 128 caracteres.'
                : null,
          ),
          if (widget.confirm)
            TextFormField(
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Repita a senha do backup',
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) =>
                  value == _password.text ? null : 'As senhas são diferentes.',
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Continuar')),
    ],
  );
}

String _date(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}, ${two(local.hour)}:${two(local.minute)}';
}
