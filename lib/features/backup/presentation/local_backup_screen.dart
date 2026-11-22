import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/components.dart';
import '../../../core/widgets/record_actions.dart';
import '../data/android_drive_backup.dart';
import '../data/backup_encryption.dart';
import '../data/backup_snapshot.dart';
import '../data/local_backup.dart';
import 'cloud_backup_screen.dart';

class LocalBackupScreen extends ConsumerStatefulWidget {
  const LocalBackupScreen({super.key});

  @override
  ConsumerState<LocalBackupScreen> createState() => _LocalBackupScreenState();
}

class _LocalBackupScreenState extends ConsumerState<LocalBackupScreen> {
  DateTime? _last;
  LocalBackupFrequency? _frequency;
  String? _warning;
  String? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(localBackupProvider);
    try {
      final (last, cadence, warning) = await (
        service.lastBackup(),
        service.frequency(),
        service.automaticError(),
      ).wait;
      if (mounted)
        setState(() {
          _last = last;
          _frequency = cadence;
          _warning = cadence == null ? null : warning;
        });
    } catch (_) {
      if (mounted)
        setState(
          () => _warning = 'Não foi possível ler as preferências de backup.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _perform(
    String label,
    Future<void> Function(LocalBackup) work,
  ) async {
    if (_progress != null) return;
    setState(() => _progress = label);
    try {
      await work(ref.read(localBackupProvider));
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        showRecordError(
          context,
          error is BackupProblem ? StateError(error.message) : error,
          'Não foi possível concluir o backup.',
        );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  Future<void> _create() async {
    final password = await _askPassword(context, create: true);
    if (!mounted || password == null) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    await _perform('Cifrando seus dados…', (backup) async {
      final bytes = await backup.create(password);
      if (!mounted) return;
      final result = await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'application/octet-stream')],
        fileNameOverrides: [LocalBackup.fileName()],
        subject: 'Backup do Finance App',
        sharePositionOrigin: origin,
      );
      if (result.status != ShareResultStatus.dismissed)
        await backup.recordBackup();
    });
  }

  Future<void> _restore() async {
    final pick = await FilePicker.platform.pickFiles(
      withReadStream: true,
      withData: false,
    );
    final file = pick?.files.single;
    if (!mounted || file == null) return;
    final password = await _askPassword(context, create: false);
    if (!mounted || password == null) return;
    await _perform('Verificando o arquivo…', (backup) async {
      final input = file.readStream;
      if (input == null || file.size > maxBackupBytes + 4096)
        throw const BackupProblem('O tamanho do arquivo de backup é inválido.');
      final builder = BytesBuilder(copy: false);
      await for (final chunk in input) {
        if (builder.length + chunk.length > maxBackupBytes + 4096) {
          throw const BackupProblem(
            'O tamanho do arquivo de backup é inválido.',
          );
        }
        builder.add(chunk);
      }
      final prepared = await backup.prepare(builder.takeBytes(), password);
      if (!mounted) return;
      final date = DateFormat.yMd('pt_BR')
          .add_Hm()
          .format(prepared.createdAt.toLocal());
      final count = NumberFormat.decimalPattern('pt_BR')
          .format(prepared.snapshot.transactionCount);
      final confirmed = await confirmRecordAction(
        context,
        title: 'Substituir os dados deste aparelho?',
        message:
            'O backup de $date contém $count lançamentos. Ele substituirá todos os dados financeiros locais.',
        action: 'Restaurar backup',
      );
      if (!confirmed || !mounted) return;
      setState(() => _progress = 'Restaurando $count lançamentos…');
      await backup.restore(prepared);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Backup restaurado.')));
    });
  }

  Future<void> _automatic() async {
    final cadence = await showAppBottomSheet<LocalBackupFrequency>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(title: Text('Frequência do backup automático')),
            for (final option in LocalBackupFrequency.values)
              ListTile(
                title: Text(option.label),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (!mounted || cadence == null) return;
    await _perform('Configurando backup automático…', (backup) async {
      final folder = await LocalBackup.chooseFolder();
      if (!mounted || folder == null) return;
      final password = await _askPassword(context, create: true);
      if (!mounted || password == null) return;
      await backup.configure(cadence, folder, password);
      await backup.runAutomatic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drive = ref.watch(driveBackupProvider);
    final busy = _progress != null || _loading;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup e restauração')),
      body: AppContent(
        maxWidth: AppLayout.maxReading,
        child: ListView(
          padding: AppLayout.pagePadding(context),
          children: [
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppIcon(
                        _last == null
                            ? Symbols.lock_rounded
                            : Symbols.verified_rounded,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Backup local criptografado',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _last == null
                        ? 'Nenhum backup local criado.'
                        : 'Último backup em ${DateFormat.yMd('pt_BR').add_Hm().format(_last!)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Os arquivos são cifrados neste aparelho. Você decide onde guardá-los.',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (busy) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      semanticsLabel: _progress ?? 'Carregando backup',
                    ),
                    if (_progress != null) Text(_progress!),
                  ],
                  if (_warning != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _warning!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy ? null : _create,
              icon: const Icon(Symbols.backup_rounded),
              label: const Text('Criar backup agora'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : _restore,
              icon: const Icon(Symbols.folder_open_rounded),
              label: const Text('Restaurar de arquivo'),
            ),
            const SizedBox(height: 16),
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Backup automático', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    _frequency == null
                        ? 'Desativado'
                        : '${_frequency!.label} · pasta escolhida no aparelho',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: busy ? null : _automatic,
                    child: Text(
                      _frequency == null
                          ? 'Escolher frequência e pasta'
                          : 'Alterar frequência e pasta',
                    ),
                  ),
                  if (_frequency != null)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => _perform(
                              'Desativando…',
                              (backup) => backup.disable(),
                            ),
                      child: const Text('Desativar backup automático'),
                    ),
                ],
              ),
            ),
            if (drive != null) ...[
              const SizedBox(height: 16),
              AppSurface(
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => const CloudBackupScreen()),
                ),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AppIcon(Symbols.cloud_rounded),
                  title: Text('Backup em nuvem'),
                  subtitle: Text('Sincronização opcional pelo Google Drive.'),
                  trailing: Icon(Symbols.chevron_right_rounded),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<String?> _askPassword(BuildContext context, {required bool create}) =>
    showAppBottomSheet<String>(
      context: context,
      builder: (_) => _LocalPassword(create: create),
    );

class _LocalPassword extends StatefulWidget {
  const _LocalPassword({required this.create});
  final bool create;

  @override
  State<_LocalPassword> createState() => _LocalPasswordState();
}

class _LocalPasswordState extends State<_LocalPassword> {
  final _form = GlobalKey<FormState>();
  String _password = '';
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Senha do backup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use de 12 a 128 caracteres. Guarde esta senha para restaurar o arquivo.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              obscureText: _hidden,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (value) => _password = value,
              decoration: InputDecoration(
                labelText: 'Senha do backup',
                suffixIcon: IconButton(
                  tooltip: _hidden ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(
                    _hidden
                        ? Symbols.visibility_rounded
                        : Symbols.visibility_off_rounded,
                  ),
                ),
              ),
              validator: (value) =>
                  _password.length < 12 || _password.length > 128
                  ? 'Use uma senha de 12 a 128 caracteres.'
                  : null,
            ),
            if (widget.create) ...[
              const SizedBox(height: 12),
              TextFormField(
                obscureText: _hidden,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha do backup',
                ),
                validator: (value) => value == _password
                    ? null
                    : 'As senhas precisam ser iguais.',
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_form.currentState!.validate())
                  Navigator.pop(context, _password);
              },
              child: Text(
                widget.create ? 'Criar backup cifrado' : 'Verificar arquivo',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
