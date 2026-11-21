import 'package:flutter/material.dart';

Future<bool> confirmRecordAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
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
}

void showRecordError(BuildContext context, Object error, String fallback) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error is StateError ? error.message : fallback)),
  );
}
