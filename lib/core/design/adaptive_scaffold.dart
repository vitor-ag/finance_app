import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'app_theme.dart';
import 'components.dart';

const appDestinations = [
  (label: 'Início', icon: Symbols.home_rounded),
  (label: 'Lançamentos', icon: Symbols.receipt_long_rounded),
  (label: 'Planejar', icon: Symbols.flag_rounded),
  (label: 'Relatórios', icon: Symbols.bar_chart_rounded),
];

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onNew,
    required this.onSettings,
    required this.onSearch,
    required this.creating,
    required this.body,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onNew, onSettings, onSearch;
  final bool creating;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final size = WindowSizeClass.of(context);
    final window = MediaQuery.sizeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final side =
        size != WindowSizeClass.compact ||
        (window.height < 480 && window.width > window.height);
    final extended = WindowSizeClass.wide(context);
    final railWidth = size == WindowSizeClass.large
        ? 280.0
        : extended
        ? 240.0
        : 80.0;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): onNew,
        const SingleActivator(LogicalKeyboardKey.slash): onSearch,
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
            onSettings,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              if (side)
                SizedBox(
                  width: railWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: Border(right: BorderSide(color: scheme.outline)),
                    ),
                    child: SafeArea(
                      right: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              padding: EdgeInsets.all(extended ? 16 : 4),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight:
                                      (constraints.maxHeight -
                                              (extended ? 32 : 8))
                                          .clamp(0, double.infinity),
                                ),
                                child: IntrinsicHeight(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Center(
                                        child: _NewAction(
                                          extended: extended,
                                          size: 56,
                                          open: creating,
                                          onTap: onNew,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      for (
                                        var i = 0;
                                        i < appDestinations.length;
                                        i++
                                      )
                                        _Destination(
                                          index: i,
                                          active: i == index,
                                          extended: extended,
                                          onTap: () => onSelect(i),
                                        ),
                                      const Spacer(),
                                      const SizedBox(height: 8),
                                      if (extended)
                                        TextButton.icon(
                                          onPressed: onSettings,
                                          icon: const Icon(
                                            Symbols.settings_rounded,
                                          ),
                                          label: const Text('Ajustes'),
                                        )
                                      else
                                        IconButton(
                                          tooltip: 'Ajustes',
                                          onPressed: onSettings,
                                          icon: const Icon(
                                            Symbols.settings_rounded,
                                          ),
                                        ),
                                      if (extended)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: PrivacyLabel(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              Expanded(key: const ValueKey('conteúdo'), child: body),
            ],
          ),
          bottomNavigationBar: side
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border(top: BorderSide(color: scheme.outline)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(12) > 16
                          ? 44 +
                                MediaQuery.textScalerOf(context).scale(11) *
                                    8 /
                                    3
                          : AppLayout.barHeight,
                      child: Row(
                        children: [
                          for (var i = 0; i < appDestinations.length; i++) ...[
                            if (i == 2)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Transform.translate(
                                  offset: const Offset(0, -8),
                                  child: _NewAction(
                                    size: 60,
                                    open: creating,
                                    onTap: onNew,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: _Destination(
                                index: i,
                                active: i == index,
                                onTap: () => onSelect(i),
                              ),
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

class _Destination extends StatelessWidget {
  const _Destination({
    required this.index,
    required this.active,
    this.extended = false,
    required this.onTap,
  });
  final int index;
  final bool active, extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final destination = appDestinations[index];
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    final wrapLabel =
        extended || MediaQuery.textScalerOf(context).scale(12) > 16;
    final icon = Container(
      width: extended ? 48 : 52,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.pill),
        color: active ? scheme.primaryContainer : null,
      ),
      child: Icon(
        destination.icon,
        color: color,
        fill: active ? 1 : 0,
        weight: 500,
        size: 22,
      ),
    );
    final label = Text(
      destination.label,
      textAlign: extended ? TextAlign.start : TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        color: color,
        fontSize: extended ? 14 : 11,
      ),
      maxLines: wrapLabel ? 2 : 1,
      softWrap: wrapLabel,
    );
    return Semantics(
      selected: active,
      button: true,
      label: destination.label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppLayout.controlRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: extended
                    ? Row(
                        children: [
                          icon,
                          const SizedBox(width: 8),
                          Expanded(child: label),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          icon,
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: wrapLabel
                                ? label
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: label,
                                  ),
                          ),
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

class _NewAction extends StatelessWidget {
  const _NewAction({
    required this.size,
    required this.open,
    required this.onTap,
    this.extended = false,
  });
  final double size;
  final bool open, extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.brightness == Brightness.dark
        ? scheme.onPrimary
        : AppColors.inkOnGradient;
    return Tooltip(
      message: 'Novo lançamento',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppLayout.pill),
          gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
          border: scheme.brightness == Brightness.dark
              ? Border.all(color: scheme.outline)
              : null,
          boxShadow: scheme.brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: .25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: SizedBox(
              height: size,
              width: extended ? 208 : size,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: open ? .125 : 0,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Symbols.add_rounded,
                      size: 32,
                      weight: 500,
                      color: ink,
                    ),
                  ),
                  if (extended)
                    Flexible(
                      child: Text(
                        'Novo lançamento',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrivacyLabel extends StatelessWidget {
  const PrivacyLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = WindowSizeClass.of(context) != WindowSizeClass.compact;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppIcon(Symbols.lock_rounded),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            wide
                ? 'Seus dados ficam só neste aparelho'
                : 'Seus dados ficam só neste celular',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}
