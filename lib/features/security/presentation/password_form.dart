import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/local_access.dart';

enum PasswordFormMode { create, unlock, confirm, change }

class PasswordForm extends StatefulWidget {
  const PasswordForm({
    super.key,
    required this.access,
    required this.mode,
    required this.buttonLabel,
    required this.onSubmit,
  });

  final LocalAccess access;
  final PasswordFormMode mode;
  final String buttonLabel;
  final Future<void> Function(String password, String? replacement) onSubmit;

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _replacement = TextEditingController();
  final _confirmation = TextEditingController();
  Timer? _timer;
  String? _message;
  bool _submitting = false;

  bool get _creating => widget.mode == PasswordFormMode.create;
  bool get _changing => widget.mode == PasswordFormMode.change;
  Duration get _wait => _creating ? Duration.zero : widget.access.passwordWait;

  @override
  void initState() {
    super.initState();
    _refreshCountdown();
  }

  void _refreshCountdown() {
    if (_wait <= Duration.zero || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_wait <= Duration.zero) {
        _timer?.cancel();
        _timer = null;
      }
      setState(() {});
    });
  }

  Future<void> _submit() async {
    if (widget.access.busy ||
        _submitting ||
        _wait > Duration.zero ||
        !_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _message = null;
      _submitting = true;
    });
    try {
      await widget.onSubmit(
        _password.text,
        _changing ? _replacement.text : null,
      );
    } on AccessProblem catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Não foi possível concluir. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        _password.clear();
        _replacement.clear();
        _confirmation.clear();
        _refreshCountdown();
        setState(() => _submitting = false);
      }
    }
  }

  String? _validateNew(String? value) {
    if (value == null ||
        !LocalAccess.validLength(value) ||
        value.trim().isEmpty) {
      return 'Use de 8 a 128 caracteres.';
    }
    return null;
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validate, {
    required bool last,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: !widget.access.busy && !_submitting && _wait <= Duration.zero,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => _submit() : null,
      validator: validate,
    ),
  );

  @override
  void dispose() {
    _timer?.cancel();
    _password.dispose();
    _replacement.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (_wait.inMilliseconds / 1000).ceil();
    final confirmationTarget = _creating ? _password : _replacement;
    final needsConfirmation = _creating || _changing;
    final canSubmit = !widget.access.busy && !_submitting && seconds == 0;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            _password,
            switch (widget.mode) {
              PasswordFormMode.create => 'Nova senha',
              PasswordFormMode.unlock => 'Senha do app',
              _ => 'Senha atual',
            },
            _creating
                ? _validateNew
                : (value) => value == null || value.isEmpty
                      ? 'Informe a senha.'
                      : null,
            last: !needsConfirmation,
          ),
          if (_changing)
            _field(_replacement, 'Nova senha', _validateNew, last: false),
          if (needsConfirmation)
            _field(
              _confirmation,
              'Confirmar nova senha',
              (value) => value == confirmationTarget.text
                  ? null
                  : 'As senhas precisam ser iguais.',
              last: true,
            ),
          if (_message case final message?) AccessMessage(message),
          if (seconds > 0)
            AccessMessage(
              'Tente novamente em ${seconds == 1 ? '1 segundo' : '$seconds segundos'}.',
            ),
          FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: Text(widget.buttonLabel),
          ),
          if (_submitting) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class AccessMessage extends StatelessWidget {
  const AccessMessage(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}
