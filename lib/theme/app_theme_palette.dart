import 'package:flutter/material.dart';

/// Built-in app color themes (primary + text + surfaces).
enum AppThemeId {
  forest,
  ocean,
  teal,
  sunset,
  indigo,
  midnight,
  custom,
}

class AppThemePalette {
  const AppThemePalette({
    required this.id,
    required this.brightness,
    required this.splashBackground,
    required this.splashCircle,
    required this.logoGreen,
    required this.calculatorOrange,
    required this.subtitle,
    required this.loadingRing,
    required this.primary,
    required this.darkPrimary,
    required this.banner,
    required this.pageBackground,
    required this.textDark,
    required this.textGrey,
    required this.borderGrey,
    required this.inputBackground,
    required this.featurePrimaryBg,
    required this.featureOrangeBg,
    required this.featureOrangeIcon,
    required this.selectedCardBg,
    required this.infoBoxBg,
    required this.headerIcon,
    required this.statusOrange,
    required this.actionOrange,
    required this.actionBlue,
    required this.actionBlueIcon,
    required this.marketBrown,
    required this.monthRed,
    required this.balanceGreenBg,
    required this.updateOrangeBg,
    required this.marketOrange,
    required this.marketOrangeDark,
    required this.marketAmountBrown,
    required this.dateChipBg,
  });

  final AppThemeId id;
  final Brightness brightness;

  final Color splashBackground;
  final Color splashCircle;
  final Color logoGreen;
  final Color calculatorOrange;
  final Color subtitle;
  final Color loadingRing;

  final Color primary;
  final Color darkPrimary;
  final Color banner;
  final Color pageBackground;
  final Color textDark;
  final Color textGrey;
  final Color borderGrey;
  final Color inputBackground;
  final Color featurePrimaryBg;
  final Color featureOrangeBg;
  final Color featureOrangeIcon;
  final Color selectedCardBg;
  final Color infoBoxBg;
  final Color headerIcon;

  final Color statusOrange;
  final Color actionOrange;
  final Color actionBlue;
  final Color actionBlueIcon;
  final Color marketBrown;
  final Color monthRed;
  final Color balanceGreenBg;
  final Color updateOrangeBg;

  final Color marketOrange;
  final Color marketOrangeDark;
  final Color marketAmountBrown;
  final Color dateChipBg;

  /// Swatch shown in the theme picker.
  Color get preview => primary;

  static const forest = AppThemePalette(
    id: AppThemeId.forest,
    brightness: Brightness.light,
    splashBackground: Color(0xFF22702E),
    splashCircle: Color(0xFF2A8A36),
    logoGreen: Color(0xFF1F6B28),
    calculatorOrange: Color(0xFFE8941C),
    subtitle: Color(0xFFB8C9B8),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFF2E7D32),
    darkPrimary: Color(0xFF1B5E20),
    banner: Color(0xFF2E7D32),
    pageBackground: Color(0xFFF5F7F4),
    textDark: Color(0xFF1A1A1A),
    textGrey: Color(0xFF6B7280),
    borderGrey: Color(0xFFE2E5E2),
    inputBackground: Color(0xFFF8F9F8),
    featurePrimaryBg: Color(0xFFE8F5E9),
    featureOrangeBg: Color(0xFFFFF3E0),
    featureOrangeIcon: Color(0xFFE65100),
    selectedCardBg: Color(0xFFE8F5E9),
    infoBoxBg: Color(0xFFE8F0E8),
    headerIcon: Color(0xFF5A8F5E),
    statusOrange: Color(0xFFFFB74D),
    actionOrange: Color(0xFFF57C00),
    actionBlue: Color(0xFFE3F2FD),
    actionBlueIcon: Color(0xFF1565C0),
    marketBrown: Color(0xFF8D6E63),
    monthRed: Color(0xFFE53935),
    balanceGreenBg: Color(0xFFE8F5E9),
    updateOrangeBg: Color(0xFFFFF3E0),
    marketOrange: Color(0xFFFF9800),
    marketOrangeDark: Color(0xFFE65100),
    marketAmountBrown: Color(0xFF5D4037),
    dateChipBg: Color(0xFFFFE0B2),
  );

  static const ocean = AppThemePalette(
    id: AppThemeId.ocean,
    brightness: Brightness.light,
    splashBackground: Color(0xFF1565C0),
    splashCircle: Color(0xFF1E88E5),
    logoGreen: Color(0xFF0D47A1),
    calculatorOrange: Color(0xFFFFB74D),
    subtitle: Color(0xFFBBDEFB),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFF1976D2),
    darkPrimary: Color(0xFF0D47A1),
    banner: Color(0xFF1976D2),
    pageBackground: Color(0xFFF3F7FB),
    textDark: Color(0xFF102A43),
    textGrey: Color(0xFF627D98),
    borderGrey: Color(0xFFD9E2EC),
    inputBackground: Color(0xFFF7FAFC),
    featurePrimaryBg: Color(0xFFE3F2FD),
    featureOrangeBg: Color(0xFFFFF3E0),
    featureOrangeIcon: Color(0xFFE65100),
    selectedCardBg: Color(0xFFE3F2FD),
    infoBoxBg: Color(0xFFE8F1F8),
    headerIcon: Color(0xFF4A90C8),
    statusOrange: Color(0xFFFFB74D),
    actionOrange: Color(0xFFF57C00),
    actionBlue: Color(0xFFE3F2FD),
    actionBlueIcon: Color(0xFF1565C0),
    marketBrown: Color(0xFF8D6E63),
    monthRed: Color(0xFFE53935),
    balanceGreenBg: Color(0xFFE8F5E9),
    updateOrangeBg: Color(0xFFFFF3E0),
    marketOrange: Color(0xFFFF9800),
    marketOrangeDark: Color(0xFFE65100),
    marketAmountBrown: Color(0xFF5D4037),
    dateChipBg: Color(0xFFFFE0B2),
  );

  static const teal = AppThemePalette(
    id: AppThemeId.teal,
    brightness: Brightness.light,
    splashBackground: Color(0xFF00695C),
    splashCircle: Color(0xFF00897B),
    logoGreen: Color(0xFF004D40),
    calculatorOrange: Color(0xFFFFB300),
    subtitle: Color(0xFFB2DFDB),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFF00897B),
    darkPrimary: Color(0xFF004D40),
    banner: Color(0xFF00897B),
    pageBackground: Color(0xFFF2F8F7),
    textDark: Color(0xFF102A27),
    textGrey: Color(0xFF5F7A76),
    borderGrey: Color(0xFFD5E5E2),
    inputBackground: Color(0xFFF7FBFA),
    featurePrimaryBg: Color(0xFFE0F2F1),
    featureOrangeBg: Color(0xFFFFF3E0),
    featureOrangeIcon: Color(0xFFE65100),
    selectedCardBg: Color(0xFFE0F2F1),
    infoBoxBg: Color(0xFFE4F0EE),
    headerIcon: Color(0xFF4DB6AC),
    statusOrange: Color(0xFFFFB74D),
    actionOrange: Color(0xFFF57C00),
    actionBlue: Color(0xFFE0F7FA),
    actionBlueIcon: Color(0xFF00838F),
    marketBrown: Color(0xFF8D6E63),
    monthRed: Color(0xFFE53935),
    balanceGreenBg: Color(0xFFE8F5E9),
    updateOrangeBg: Color(0xFFFFF3E0),
    marketOrange: Color(0xFFFF9800),
    marketOrangeDark: Color(0xFFE65100),
    marketAmountBrown: Color(0xFF5D4037),
    dateChipBg: Color(0xFFFFE0B2),
  );

  static const sunset = AppThemePalette(
    id: AppThemeId.sunset,
    brightness: Brightness.light,
    splashBackground: Color(0xFFE65100),
    splashCircle: Color(0xFFEF6C00),
    logoGreen: Color(0xFFBF360C),
    calculatorOrange: Color(0xFFFFCA28),
    subtitle: Color(0xFFFFE0B2),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFFEF6C00),
    darkPrimary: Color(0xFFBF360C),
    banner: Color(0xFFEF6C00),
    pageBackground: Color(0xFFFFF8F3),
    textDark: Color(0xFF2D1608),
    textGrey: Color(0xFF7A5C4A),
    borderGrey: Color(0xFFEDE0D4),
    inputBackground: Color(0xFFFFFBF8),
    featurePrimaryBg: Color(0xFFFFF3E0),
    featureOrangeBg: Color(0xFFFFECB3),
    featureOrangeIcon: Color(0xFFE65100),
    selectedCardBg: Color(0xFFFFF3E0),
    infoBoxBg: Color(0xFFFFF0E6),
    headerIcon: Color(0xFFFF8A65),
    statusOrange: Color(0xFFFFB74D),
    actionOrange: Color(0xFFF57C00),
    actionBlue: Color(0xFFE3F2FD),
    actionBlueIcon: Color(0xFF1565C0),
    marketBrown: Color(0xFF8D6E63),
    monthRed: Color(0xFFE53935),
    balanceGreenBg: Color(0xFFE8F5E9),
    updateOrangeBg: Color(0xFFFFF3E0),
    marketOrange: Color(0xFFFF9800),
    marketOrangeDark: Color(0xFFE65100),
    marketAmountBrown: Color(0xFF5D4037),
    dateChipBg: Color(0xFFFFE0B2),
  );

  static const indigo = AppThemePalette(
    id: AppThemeId.indigo,
    brightness: Brightness.light,
    splashBackground: Color(0xFF303F9F),
    splashCircle: Color(0xFF3F51B5),
    logoGreen: Color(0xFF1A237E),
    calculatorOrange: Color(0xFFFFB74D),
    subtitle: Color(0xFFC5CAE9),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFF3949AB),
    darkPrimary: Color(0xFF1A237E),
    banner: Color(0xFF3949AB),
    pageBackground: Color(0xFFF5F5FA),
    textDark: Color(0xFF1A1A2E),
    textGrey: Color(0xFF6B6B85),
    borderGrey: Color(0xFFE0E0EC),
    inputBackground: Color(0xFFFAFAFD),
    featurePrimaryBg: Color(0xFFE8EAF6),
    featureOrangeBg: Color(0xFFFFF3E0),
    featureOrangeIcon: Color(0xFFE65100),
    selectedCardBg: Color(0xFFE8EAF6),
    infoBoxBg: Color(0xFFECEEF8),
    headerIcon: Color(0xFF7986CB),
    statusOrange: Color(0xFFFFB74D),
    actionOrange: Color(0xFFF57C00),
    actionBlue: Color(0xFFE3F2FD),
    actionBlueIcon: Color(0xFF1565C0),
    marketBrown: Color(0xFF8D6E63),
    monthRed: Color(0xFFE53935),
    balanceGreenBg: Color(0xFFE8F5E9),
    updateOrangeBg: Color(0xFFFFF3E0),
    marketOrange: Color(0xFFFF9800),
    marketOrangeDark: Color(0xFFE65100),
    marketAmountBrown: Color(0xFF5D4037),
    dateChipBg: Color(0xFFFFE0B2),
  );

  static const midnight = AppThemePalette(
    id: AppThemeId.midnight,
    brightness: Brightness.dark,
    splashBackground: Color(0xFF0F172A),
    splashCircle: Color(0xFF1E293B),
    logoGreen: Color(0xFF22C55E),
    calculatorOrange: Color(0xFFFBBF24),
    subtitle: Color(0xFF94A3B8),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFF22C55E),
    darkPrimary: Color(0xFF16A34A),
    banner: Color(0xFF1E293B),
    pageBackground: Color(0xFF0F172A),
    textDark: Color(0xFFF1F5F9),
    textGrey: Color(0xFF94A3B8),
    borderGrey: Color(0xFF334155),
    inputBackground: Color(0xFF1E293B),
    featurePrimaryBg: Color(0xFF14532D),
    featureOrangeBg: Color(0xFF422006),
    featureOrangeIcon: Color(0xFFFBBF24),
    selectedCardBg: Color(0xFF14532D),
    infoBoxBg: Color(0xFF1E293B),
    headerIcon: Color(0xFF86EFAC),
    statusOrange: Color(0xFFFBBF24),
    actionOrange: Color(0xFFF59E0B),
    actionBlue: Color(0xFF1E3A5F),
    actionBlueIcon: Color(0xFF93C5FD),
    marketBrown: Color(0xFFD6B29A),
    monthRed: Color(0xFFF87171),
    balanceGreenBg: Color(0xFF14532D),
    updateOrangeBg: Color(0xFF422006),
    marketOrange: Color(0xFFFBBF24),
    marketOrangeDark: Color(0xFFF59E0B),
    marketAmountBrown: Color(0xFFFDE68A),
    dateChipBg: Color(0xFF422006),
  );

  static const List<AppThemePalette> all = [
    forest,
    ocean,
    teal,
    sunset,
    indigo,
    midnight,
  ];

  /// Builds a full palette from any seed color.
  /// Page / text colors adjust automatically for light or dark.
  static AppThemePalette fromSeed(
    Color seed, {
    Brightness brightness = Brightness.light,
    AppThemeId id = AppThemeId.custom,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;
    final primary = scheme.primary;
    final onSurface = scheme.onSurface;
    final surface = scheme.surface;
    final surfaceContainer = scheme.surfaceContainerHighest;

    Color tint(Color base, double amount) {
      return Color.lerp(base, primary, amount)!;
    }

    return AppThemePalette(
      id: id,
      brightness: brightness,
      splashBackground: dark ? surface : Color.lerp(primary, Colors.black, 0.25)!,
      splashCircle: primary,
      logoGreen: Color.lerp(primary, Colors.black, dark ? 0.0 : 0.2)!,
      calculatorOrange: const Color(0xFFE8941C),
      subtitle: dark
          ? onSurface.withValues(alpha: 0.7)
          : Colors.white.withValues(alpha: 0.85),
      loadingRing: const Color(0x4DFFFFFF),
      primary: primary,
      darkPrimary: Color.lerp(primary, Colors.black, 0.35)!,
      banner: primary,
      pageBackground: dark
          ? scheme.surface
          : Color.lerp(scheme.surface, primary, 0.04)!,
      // Main app text — always readable on page background
      textDark: onSurface,
      textGrey: onSurface.withValues(alpha: 0.62),
      borderGrey: dark
          ? scheme.outlineVariant
          : Color.lerp(scheme.outlineVariant, primary, 0.08)!,
      inputBackground: dark ? surfaceContainer : Color.lerp(surface, primary, 0.03)!,
      featurePrimaryBg: tint(surface, dark ? 0.25 : 0.12),
      featureOrangeBg: dark ? const Color(0xFF422006) : const Color(0xFFFFF3E0),
      featureOrangeIcon: const Color(0xFFE65100),
      selectedCardBg: tint(surface, dark ? 0.28 : 0.14),
      infoBoxBg: tint(surface, dark ? 0.2 : 0.1),
      headerIcon: Color.lerp(primary, onSurface, 0.25)!,
      statusOrange: const Color(0xFFFFB74D),
      actionOrange: const Color(0xFFF57C00),
      actionBlue: dark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD),
      actionBlueIcon: const Color(0xFF1565C0),
      marketBrown: const Color(0xFF8D6E63),
      monthRed: dark ? const Color(0xFFF87171) : const Color(0xFFE53935),
      balanceGreenBg: tint(surface, dark ? 0.25 : 0.12),
      updateOrangeBg: dark ? const Color(0xFF422006) : const Color(0xFFFFF3E0),
      marketOrange: const Color(0xFFFF9800),
      marketOrangeDark: const Color(0xFFE65100),
      marketAmountBrown: dark ? const Color(0xFFFDE68A) : const Color(0xFF5D4037),
      dateChipBg: dark ? const Color(0xFF422006) : const Color(0xFFFFE0B2),
    );
  }

  static AppThemePalette byId(AppThemeId id) {
    if (id == AppThemeId.custom) return forest;
    return all.firstWhere((p) => p.id == id, orElse: () => forest);
  }

  static AppThemeId? tryParseId(String? raw) {
    if (raw == null) return null;
    for (final id in AppThemeId.values) {
      if (id.name == raw) return id;
    }
    return null;
  }
}
