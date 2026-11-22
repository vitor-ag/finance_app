import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'app_preferences.dart';
import 'components.dart';

class DiscreetSetting extends StatelessWidget {
  const DiscreetSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = PreferencesScope.of(context);
    return SwitchListTile(
      secondary: const AppIcon(Symbols.visibility_off_rounded),
      title: const Text('Modo discreto'),
      subtitle: const Text('Oculta os valores nas telas financeiras.'),
      value: preferences?.discreet ?? false,
      onChanged: preferences?.setDiscreet,
    );
  }
}
