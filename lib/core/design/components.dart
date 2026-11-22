import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'app_preferences.dart';
import 'app_theme.dart';

enum MoneyKind { neutral, income, expense }

class MoneyText extends StatelessWidget {
  MoneyText(
    int cents, {
    super.key,
    this.kind = MoneyKind.neutral,
    this.style,
    this.emphasis = false,
    this.signed = false,
    this.animate = false,
    this.alignment = Alignment.centerLeft,
  }) : cents = BigInt.from(cents);

  const MoneyText.total(
    this.cents, {
    super.key,
    this.kind = MoneyKind.neutral,
    this.style,
    this.emphasis = false,
    this.signed = false,
    this.animate = false,
    this.alignment = Alignment.centerLeft,
  });

  final BigInt cents;
  final MoneyKind kind;
  final TextStyle? style;
  final bool emphasis, signed, animate;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final color =
        style?.color ??
        switch (kind) {
          MoneyKind.income => palette.incomeText,
          MoneyKind.expense => palette.expenseText,
          MoneyKind.neutral => Theme.of(context).colorScheme.onSurface,
        };
    final baseStyle =
        (style ??
                (emphasis
                    ? Theme.of(context).textTheme.displayLarge
                    : Theme.of(context).textTheme.titleMedium))!
            .copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    final hidden = PreferencesScope.of(context)?.discreet ?? false;
    if (hidden)
      return Text('••••', semanticsLabel: 'Valor oculto', style: baseStyle);

    Widget render(BigInt value) {
      final absolute = value.abs();
      final whole = groupedReais(absolute ~/ BigInt.from(100));
      final fraction = (absolute % BigInt.from(100)).toString().padLeft(2, '0');
      final sign = value.isNegative || (signed && kind == MoneyKind.expense)
          ? '−'
          : signed && kind == MoneyKind.income
          ? '+'
          : '';
      final size = baseStyle.fontSize ?? 18;
      return Semantics(
        label:
            '${sign == '−'
                ? 'menos '
                : sign == '+'
                ? 'mais '
                : ''}$whole reais e $fraction centavos',
        excludeSemantics: true,
        child: FittedBox(
          alignment: alignment,
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: sign),
                TextSpan(
                  text: 'R\$ ',
                  style: TextStyle(fontSize: size * .6),
                ),
                TextSpan(text: whole),
                TextSpan(
                  text: ',$fraction',
                  style: emphasis
                      ? TextStyle(
                          fontSize: size * .7,
                          fontWeight: FontWeight.w500,
                          fontVariations: const [FontVariation('wght', 500)],
                        )
                      : null,
                ),
              ],
            ),
            style: baseStyle,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      );
    }

    if (!animate || MediaQuery.disableAnimationsOf(context))
      return render(cents);
    return TweenAnimationBuilder<double>(
      key: ValueKey(cents),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      duration: AppLayout.progressMotion,
      builder: (context, value, _) => render(
        cents * BigInt.from((value * 1000).round()) ~/ BigInt.from(1000),
      ),
    );
  }
}

final _integerFormat = NumberFormat.decimalPattern('pt_BR');

String groupedReais(BigInt whole) {
  if (whole <= BigInt.from(9007199254740991))
    return _integerFormat.format(whole.toInt());
  final digits = whole.toString();
  return digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]}.',
  );
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return onTap == null
        ? Card(clipBehavior: Clip.antiAlias, child: content)
        : _PressableCard(onTap: onTap!, child: content);
  }
}

class _PressableCard extends StatefulWidget {
  const _PressableCard({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: _pressed ? .98 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: _focused
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppLayout.cardRadius),
                side: BorderSide(color: scheme.primary, width: 2),
              )
            : null,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (value) => setState(() => _focused = value),
          onHighlightChanged: MediaQuery.disableAnimationsOf(context)
              ? null
              : (value) => setState(() => _pressed = value),
          child: widget.child,
        ),
      ),
    );
  }
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.color, this.size = 40});
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = color == null
        ? scheme.primaryContainer
        : Color.alphaBlend(color!.withValues(alpha: .16), scheme.surface);
    var foreground = color ?? scheme.primary;
    double contrast(Color first, Color second) {
      final a = first.computeLuminance();
      final b = second.computeLuminance();
      return (math.max(a, b) + .05) / (math.min(a, b) + .05);
    }

    for (var i = 0; i < 8 && contrast(foreground, background) < 3; i++) {
      foreground = Color.lerp(foreground, scheme.onSurface, .16)!;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppLayout.iconRadius),
      ),
      child: Icon(
        icon,
        size: size == 40 ? 20 : 28,
        weight: 500,
        color: foreground,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Symbols.account_balance_wallet_rounded,
    this.compact = false,
  });
  final String title;
  final String? message, actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandShapes(icon: icon, size: compact ? 80 : 160),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class BrandShapes extends StatelessWidget {
  const BrandShapes({super.key, required this.icon, this.size = 160});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _BrandShapesPainter(scheme),
          child: Center(
            child: Icon(
              icon,
              size: size * .34,
              color: scheme.primary,
              weight: 500,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandShapesPainter extends CustomPainter {
  const _BrandShapesPainter(this.scheme);
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width;
    final center = size.center(Offset.zero);
    final paint = Paint()..color = scheme.primaryContainer;
    canvas.drawCircle(center, unit * .34, paint);
    paint
      ..color = scheme.primary.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: unit * .43),
      -2.6,
      1.9,
      false,
      paint,
    );
    paint
      ..color = scheme.secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(unit * .82, unit * .27), unit * .055, paint);
    paint.color = scheme.primary;
    canvas.drawCircle(Offset(unit * .17, unit * .76), unit * .031, paint);
  }

  @override
  bool shouldRepaint(_BrandShapesPainter oldDelegate) =>
      oldDelegate.scheme != scheme;
}

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.label,
  });
  final double progress;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      curve: Curves.easeOutCubic,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppLayout.progressMotion,
      builder: (context, animated, _) => LinearProgressIndicator(
        value: animated,
        minHeight: 10,
        borderRadius: BorderRadius.circular(AppLayout.pill),
        color: color ?? scheme.primary,
        backgroundColor: scheme.surfaceContainerHighest,
        semanticsLabel: label,
        semanticsValue: '${(progress * 100).round()}%',
      ),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.maxContent,
  });
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool fullScreen = false,
  double width = AppLayout.maxForm,
  bool sidePanel = false,
}) {
  final reduced = MediaQuery.disableAnimationsOf(context);
  if (WindowSizeClass.of(context) != WindowSizeClass.compact) {
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierDismissible: true,
      barrierColor: AppColors.scrim,
      transitionDuration: reduced
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, animation, secondary) => SafeArea(
        child: Align(
          alignment: sidePanel ? Alignment.centerRight : Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: sidePanel ? 400 : width,
                maxHeight: math.min(
                  760,
                  MediaQuery.sizeOf(dialogContext).height - 48,
                ),
              ),
              child: Material(
                color: Theme.of(dialogContext).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppLayout.sheetRadius),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: double.infinity,
                  child: Builder(builder: builder),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, secondary, child) {
        final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: curved,
          child: reduced
              ? child
              : SlideTransition(
                  position: curved.drive(
                    Tween(
                      begin: sidePanel
                          ? const Offset(.16, 0)
                          : const Offset(0, .04),
                      end: Offset.zero,
                    ),
                  ),
                  child: child,
                ),
        );
      },
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    barrierColor: AppColors.scrim,
    sheetAnimationStyle: reduced
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          ),
    builder: (context) => fullScreen
        ? FractionallySizedBox(heightFactor: 1, child: builder(context))
        : builder(context),
  );
}
