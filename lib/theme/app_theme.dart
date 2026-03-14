import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color backgroundAccent;
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color borderSubtle;
  final Color heroStart;
  final Color heroEnd;
  final Color success;
  final Color warning;
  final Color info;

  const AppThemeColors({
    required this.background,
    required this.backgroundAccent,
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.borderSubtle,
    required this.heroStart,
    required this.heroEnd,
    required this.success,
    required this.warning,
    required this.info,
  });

  static const AppThemeColors light = AppThemeColors(
    background: Color(0xFFF4F7FB),
    backgroundAccent: Color(0xFFE7EEF7),
    surfacePrimary: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF8FAFD),
    borderSubtle: Color(0xFFD9E2EC),
    heroStart: Color(0xFF143A5A),
    heroEnd: Color(0xFF1F6A7D),
    success: Color(0xFF1F7A5A),
    warning: Color(0xFFB7791F),
    info: Color(0xFF245A9B),
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? backgroundAccent,
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? borderSubtle,
    Color? heroStart,
    Color? heroEnd,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      backgroundAccent: backgroundAccent ?? this.backgroundAccent,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      background: Color.lerp(background, other.background, t) ?? background,
      backgroundAccent:
          Color.lerp(backgroundAccent, other.backgroundAccent, t) ?? backgroundAccent,
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t) ?? surfacePrimary,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t) ?? surfaceSecondary,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      heroStart: Color.lerp(heroStart, other.heroStart, t) ?? heroStart,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t) ?? heroEnd,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }
}

class AppTheme {
  static ThemeData light() {
    const colors = AppThemeColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF184E77),
      brightness: Brightness.light,
      primary: const Color(0xFF184E77),
      secondary: const Color(0xFF2A7F9E),
      tertiary: const Color(0xFF6C8DAB),
      surface: colors.surfacePrimary,
      background: colors.background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      extensions: const [colors],
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.8),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.6),
        headlineSmall: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.4),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(height: 1.5),
        bodyMedium: TextStyle(height: 1.45),
      ),
      cardTheme: CardThemeData(
        color: colors.surfacePrimary,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        space: 1,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        backgroundColor: colors.surfaceSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: colors.borderSubtle),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfacePrimary.withOpacity(0.94),
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfacePrimary,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surfacePrimary,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: scheme.primary, width: 2.5),
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        dividerColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF17324D),
        contentTextStyle: TextStyle(color: scheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: colors.backgroundAccent,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withOpacity(0.12),
      ),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeColors get appThemeColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
}

class AppPageShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? headerAction;
  final EdgeInsetsGeometry padding;

  const AppPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerAction,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.background, colors.backgroundAccent.withOpacity(0.55)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.heroStart, colors.heroEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colors.heroStart.withOpacity(0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompactHeader = constraints.maxWidth < 700;

                    return Flex(
                      direction: isCompactHeader ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isCompactHeader ? 0 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withOpacity(0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (headerAction != null) ...[
                          SizedBox(width: isCompactHeader ? 0 : 16, height: isCompactHeader ? 16 : 0),
                          headerAction!,
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}