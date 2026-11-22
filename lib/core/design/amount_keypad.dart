import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey, required this.onDone});
  final ValueChanged<String> onKey;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final row in const [
        ['1', '2', '3', '⌫'],
        ['4', '5', '6', ','],
        ['7', '8', '9', '0'],
      ])
        Row(
          children: [
            for (final key in row)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => onKey(key),
                    child: key == '⌫'
                        ? const Icon(
                            Symbols.backspace_rounded,
                            semanticLabel: 'Apagar dígito',
                          )
                        : Text(
                            key,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                  ),
                ),
              ),
          ],
        ),
      TextButton(onPressed: onDone, child: const Text('OK')),
    ],
  );
}
