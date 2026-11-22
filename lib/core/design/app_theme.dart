import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

enum WindowSizeClass {
  compact,
  medium,
  expanded,
  large;

  static WindowSizeClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return large;
    if (width >= 840) return expanded;
    if (width >= 600) return medium;
    return compact;
  }

  static bool wide(BuildContext context) => of(context).index >= expanded.index;

  double get margin => switch (this) {
    compact => 20,
    medium => 24,
    expanded => 32,
    large => 40,
  };

  double get gutter => index >= expanded.index ? 24 : 16;
}

class AppLayout {
  static const cardRadius = 24.0;
  static const sheetRadius = 28.0;
  static const controlRadius = 16.0;
  static const iconRadius = 12.0;
  static const pill = 999.0;
  static const maxContent = 1200.0;
  static const maxForm = 560.0;
  static const maxReading = 640.0;
  static const barHeight = 72.0;
  static const controlHeight = 52.0;
  static const target = 48.0;
  static const motion = Duration(milliseconds: 300);
  static const progressMotion = Duration(milliseconds: 700);

  static double margin(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360 ||
          MediaQuery.textScalerOf(context).scale(16) > 20.8
      ? 16
      : WindowSizeClass.of(context).margin;

  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.fromLTRB(margin(context), 12, margin(context), 24);
}

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.income,
    required this.incomeText,
    required this.expense,
    required this.expenseText,
    required this.warning,
    required this.info,
    required this.balance,
  });

  final Color income, incomeText, expense, expenseText, warning, info;
  final List<Color> balance;

  static const inkOnGradient = Color(0xFFFFFFFF);
  static const gradientShade = Color(0xFF1B0B45);
  static const scrim = Color(0x66000000);
  static const categoryPalette = [
    Color(0xFF7B3FE4),
    Color(0xFFFF8A3D),
    Color(0xFF2D9CDB),
    Color(0xFFFF5CA8),
    Color(0xFF1DB88A),
    Color(0xFFF5B83D),
    Color(0xFF00B8D9),
    Color(0xFF5B6B8C),
    Color(0xFF9A93B5),
    Color(0xFF3B82F6),
    Color(0xFFF04F5F),
    Color(0xFF8B3FD9),
  ];
  static const accents = [
    Color(0xFF7B3FE4),
    Color(0xFF245FC7),
    Color(0xFF087A5B),
    Color(0xFFA42968),
  ];
  static const darkAccents = [
    Color(0xFFA47BFF),
    Color(0xFF83B2FF),
    Color(0xFF3DDDB0),
    Color(0xFFFF7FBC),
  ];

  static const light = AppColors(
    income: Color(0xFF1DB88A),
    incomeText: Color(0xFF087A5B),
    expense: Color(0xFFF04F5F),
    expenseText: Color(0xFFD62F42),
    warning: Color(0xFFFFB020),
    info: Color(0xFF3B82F6),
    balance: [Color(0xFF7B3FE4), Color(0xFFB24BF3), Color(0xFFFF5CA8)],
  );
  static const dark = AppColors(
    income: Color(0xFF3DDDB0),
    incomeText: Color(0xFF3DDDB0),
    expense: Color(0xFFFF7A86),
    expenseText: Color(0xFFFF7A86),
    warning: Color(0xFFFFC24D),
    info: Color(0xFF83B2FF),
    balance: [Color(0xFF5B2BC0), Color(0xFF8B3FD9), Color(0xFFD4458F)],
  );

  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppColors copyWith({
    Color? income,
    Color? incomeText,
    Color? expense,
    Color? expenseText,
    Color? warning,
    Color? info,
    List<Color>? balance,
  }) => AppColors(
    income: income ?? this.income,
    incomeText: incomeText ?? this.incomeText,
    expense: expense ?? this.expense,
    expenseText: expenseText ?? this.expenseText,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    balance: balance ?? this.balance,
  );

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      income: Color.lerp(income, other.income, t)!,
      incomeText: Color.lerp(incomeText, other.incomeText, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseText: Color.lerp(expenseText, other.expenseText, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      balance: List.generate(
        balance.length,
        (i) => Color.lerp(balance[i], other.balance[i], t)!,
      ),
    );
  }
}

ThemeData appTheme(Brightness brightness, WindowSizeClass size, int accent) {
  final dark = brightness == Brightness.dark;
  final tokens = dark ? AppColors.dark : AppColors.light;
  final primary = (dark ? AppColors.darkAccents : AppColors.accents)[accent];
  final onPrimary = dark ? const Color(0xFF1B0B45) : AppColors.inkOnGradient;
  final primaryContainer = dark
      ? const Color(0xFF34246B)
      : const Color(0xFFEDE4FF);
  final secondary = dark ? const Color(0xFFFF7FBC) : const Color(0xFFFF5CA8);
  final background = dark ? const Color(0xFF120D22) : const Color(0xFFF7F5FF);
  final surface = dark ? const Color(0xFF1C1533) : AppColors.inkOnGradient;
  final variant = dark ? const Color(0xFF261D45) : const Color(0xFFF0ECFB);
  final outline = dark ? const Color(0xFF342A57) : const Color(0xFFE3DEF5);
  final ink = dark ? const Color(0xFFF3EFFF) : const Color(0xFF1B1530);
  final muted = dark ? const Color(0xFFA9A1C7) : const Color(0xFF6B6485);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: ink,
    secondary: secondary,
    onSecondary: const Color(0xFF1B1530),
    secondaryContainer: variant,
    onSecondaryContainer: ink,
    tertiary: tokens.info,
    onTertiary: onPrimary,
    error: tokens.expenseText,
    onError: onPrimary,
    errorContainer: variant,
    onErrorContainer: tokens.expenseText,
    surface: surface,
    onSurface: ink,
    onSurfaceVariant: muted,
    surfaceContainerLowest: background,
    surfaceContainerLow: surface,
    surfaceContainer: variant,
    surfaceContainerHigh: variant,
    surfaceContainerHighest: variant,
    outline: outline,
    outlineVariant: outline,
    shadow: Colors.transparent,
    surfaceTint: Colors.transparent,
    scrim: Colors.black,
    inverseSurface: ink,
    onInverseSurface: background,
    inversePrimary: primary,
  );
  TextStyle style(
    double size,
    double line, {
    bool heading = false,
    int weight = 400,
  }) => TextStyle(
    fontFamily: heading ? 'Outfit' : 'Inter',
    fontSize: size,
    height: line / size,
    letterSpacing: 0,
    fontWeight: FontWeight.values[weight ~/ 100 - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
  );
  final headline = switch (size) {
    WindowSizeClass.compact => 28.0,
    WindowSizeClass.medium => 30.0,
    _ => 32.0,
  };
  final display = switch (size) {
    WindowSizeClass.compact => 40.0,
    WindowSizeClass.medium => 44.0,
    _ => 48.0,
  };
  final text = TextTheme(
    displayLarge: style(display, display + 8, heading: true, weight: 700),
    headlineLarge: style(headline, headline + 8, heading: true, weight: 600),
    headlineMedium: style(headline, headline + 8, heading: true, weight: 600),
    headlineSmall: style(24, 32, heading: true, weight: 600),
    titleLarge: style(20, 28, heading: true, weight: 600),
    titleMedium: style(18, 24, heading: true, weight: 600),
    titleSmall: style(16, 24, heading: true, weight: 600),
    bodyLarge: style(16, 24),
    bodyMedium: style(16, 24),
    bodySmall: style(14, 20).copyWith(color: muted),
    labelLarge: style(14, 20, weight: 500),
    labelMedium: style(12, 16, weight: 500),
    labelSmall: style(12, 16, weight: 500),
  );
  final control = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppLayout.controlRadius),
  );
  final pill = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppLayout.pill),
  );
  final field = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppLayout.controlRadius),
    borderSide: BorderSide.none,
  );
  const transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _AppTransitions(),
      TargetPlatform.iOS: _AppTransitions(),
      TargetPlatform.windows: _AppTransitions(),
      TargetPlatform.linux: _AppTransitions(),
      TargetPlatform.macOS: _AppTransitions(),
    },
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    textTheme: text,
    scaffoldBackgroundColor: background,
    hoverColor: primaryContainer.withValues(alpha: .4),
    focusColor: primary.withValues(alpha: .16),
    extensions: [tokens],
    pageTransitionsTheme: transitions,
    iconTheme: IconThemeData(color: ink, size: 24, weight: 500),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineLarge!.copyWith(color: ink),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        side: BorderSide(color: outline),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      modalBarrierColor: AppColors.scrim,
      elevation: 0,
      showDragHandle: true,
      dragHandleSize: const Size(36, 4),
      dragHandleColor: muted,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppLayout.sheetRadius),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.sheetRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: variant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: field,
      enabledBorder: field,
      focusedBorder: field.copyWith(
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: field.copyWith(
        borderSide: BorderSide(color: tokens.expenseText),
      ),
      focusedErrorBorder: field.copyWith(
        borderSide: BorderSide(color: tokens.expenseText, width: 2),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(AppLayout.target, AppLayout.controlHeight),
        shape: control,
        disabledForegroundColor: muted,
        disabledBackgroundColor: primary.withValues(alpha: .16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppLayout.target, AppLayout.controlHeight),
        shape: control,
        side: BorderSide(color: primary, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppLayout.target, AppLayout.target),
        shape: pill,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppLayout.target),
        shape: pill,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: scheme.onSecondary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: pill,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: primaryContainer,
      checkmarkColor: primary,
      side: BorderSide(color: outline),
      shape: pill,
      labelStyle: text.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: muted,
      titleTextStyle: text.bodyLarge!.copyWith(color: ink),
      subtitleTextStyle: text.bodySmall,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      actionTextColor: dark ? onPrimary : secondary,
      contentTextStyle: text.bodySmall!.copyWith(color: background),
      shape: control,
      width: size == WindowSizeClass.compact ? null : 480,
    ),
  );
}

class _AppTransitions extends PageTransitionsBuilder {
  const _AppTransitions();

  @override
  Duration get transitionDuration => AppLayout.motion;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? FadeTransition(opacity: animation, child: child)
      : SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        );
}
