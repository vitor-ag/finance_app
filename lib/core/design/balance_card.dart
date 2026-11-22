import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'app_preferences.dart';
import 'app_theme.dart';
import 'components.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    this.label = 'Saldo total',
    this.shortcuts,
  });
  final String label;
  final BigInt? balance;
  final BigInt income, expense;
  final Widget? shortcuts;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preferences = PreferencesScope.of(context);
    final hidden = preferences?.discreet ?? false;
    final radius = BorderRadius.circular(AppLayout.cardRadius);
    final foreground = theme.textTheme.displayLarge?.copyWith(
      color: AppColors.inkOnGradient,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
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
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: scheme.brightness == Brightness.dark
                ? Border.all(color: scheme.outline)
                : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.balance,
              stops: const [0, .60, 1],
            ),
          ),
          child: CustomPaint(
            painter: const _BalanceShapes(),
            child: Container(
              constraints: const BoxConstraints(minHeight: 188),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.inkOnGradient.withValues(
                              alpha: .86,
                            ),
                          ),
                        ),
                      ),
                      if (preferences != null)
                        IconButton(
                          tooltip: hidden
                              ? 'Mostrar valores'
                              : 'Ocultar valores',
                          onPressed: () => preferences.setDiscreet(!hidden),
                          icon: Icon(
                            hidden
                                ? Symbols.visibility_off_rounded
                                : Symbols.visibility_rounded,
                            color: AppColors.inkOnGradient,
                            weight: 500,
                          ),
                        ),
                    ],
                  ),
                  if (balance == null)
                    Text('—', style: foreground)
                  else
                    MoneyText.total(
                      balance!,
                      emphasis: true,
                      animate: true,
                      style: foreground,
                    ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked =
                          MediaQuery.textScalerOf(context).scale(12) > 17;
                      final width = stacked
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 8) / 2;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: width,
                            child: _BalanceMetric(
                              label: 'Receitas do mês',
                              value: income,
                              kind: MoneyKind.income,
                              icon: Symbols.arrow_upward_rounded,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _BalanceMetric(
                              label: 'Despesas do mês',
                              value: expense,
                              kind: MoneyKind.expense,
                              icon: Symbols.arrow_downward_rounded,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (shortcuts != null) ...[
                    const SizedBox(height: 12),
                    shortcuts!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.value,
    required this.kind,
    required this.icon,
  });
  final String label;
  final BigInt value;
  final MoneyKind kind;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1B0B45).withValues(alpha: .34),
        borderRadius: BorderRadius.circular(AppLayout.controlRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.inkOnGradient, weight: 500),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: text.labelMedium?.copyWith(
                      color: AppColors.inkOnGradient,
                    ),
                  ),
                  MoneyText.total(
                    value,
                    kind: kind,
                    signed: true,
                    style: text.titleSmall?.copyWith(
                      color: AppColors.inkOnGradient,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceShapes extends CustomPainter {
  const _BalanceShapes();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkOnGradient.withValues(alpha: .12);
    final width = size.width;
    final height = size.height;
    canvas.drawCircle(Offset(width * .96, height * .13), height * .47, paint);
    canvas.drawCircle(Offset(width * .79, -height * .12), height * .56, paint);
    final shape = Path()
      ..moveTo(width * .46, height)
      ..cubicTo(
        width * .53,
        height * .76,
        width * .78,
        height * 1.01,
        width * 1.04,
        height * .41,
      )
      ..lineTo(width * 1.04, height)
      ..close();
    canvas.drawPath(shape, paint);
    // A soft veil keeps the white title and controls readable across the gradient.
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B0B45).withValues(alpha: .1),
            const Color(0xFF1B0B45).withValues(alpha: .35),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BalanceShapes oldDelegate) => false;
}
