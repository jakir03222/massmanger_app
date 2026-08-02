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
    required this.onPrimary,
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
  /// Text / icons on [primary] buttons, FABs, filled chips.
  final Color onPrimary;
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

  bool get isDark => brightness == Brightness.dark;

  /// Readable ink color for any filled surface.
  static Color contrastOn(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF121212);
  }

  // ── Presets (harmonized primary + accents + text) ──

  static const forest = AppThemePalette(
    id: AppThemeId.forest,
    brightness: Brightness.light,
    splashBackground: Color(0xFF1B5E28),
    splashCircle: Color(0xFF2E8B3A),
    logoGreen: Color(0xFF1B5E28),
    calculatorOrange: Color(0xFFE89A1C),
    subtitle: Color(0xFFC5D9C7),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFF2F7D32),
    darkPrimary: Color(0xFF1B5E20),
    onPrimary: Color(0xFFFFFFFF),
    banner: Color(0xFF2F7D32),
    pageBackground: Color(0xFFF4F7F3),
    textDark: Color(0xFF152018),
    textGrey: Color(0xFF5F6B63),
    borderGrey: Color(0xFFDCE4DC),
    inputBackground: Color(0xFFF7FAF7),
    featurePrimaryBg: Color(0xFFE6F4E8),
    featureOrangeBg: Color(0xFFFFF4E5),
    featureOrangeIcon: Color(0xFFD97706),
    selectedCardBg: Color(0xFFE6F4E8),
    infoBoxBg: Color(0xFFE8F0E9),
    headerIcon: Color(0xFF4A8F52),
    statusOrange: Color(0xFFF0A04B),
    actionOrange: Color(0xFFE67E22),
    actionBlue: Color(0xFFE8F1F8),
    actionBlueIcon: Color(0xFF1D6FA5),
    marketBrown: Color(0xFF7A6357),
    monthRed: Color(0xFFD32F2F),
    balanceGreenBg: Color(0xFFE6F4E8),
    updateOrangeBg: Color(0xFFFFF4E5),
    marketOrange: Color(0xFFF59E0B),
    marketOrangeDark: Color(0xFFD97706),
    marketAmountBrown: Color(0xFF5C4033),
    dateChipBg: Color(0xFFFFE8C7),
  );

  static const ocean = AppThemePalette(
    id: AppThemeId.ocean,
    brightness: Brightness.light,
    splashBackground: Color(0xFF0D47A1),
    splashCircle: Color(0xFF1976D2),
    logoGreen: Color(0xFF0D47A1),
    calculatorOrange: Color(0xFFFFB74D),
    subtitle: Color(0xFFBBDEFB),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFF1867C0),
    darkPrimary: Color(0xFF0D47A1),
    onPrimary: Color(0xFFFFFFFF),
    banner: Color(0xFF1867C0),
    pageBackground: Color(0xFFF2F6FB),
    textDark: Color(0xFF0F2438),
    textGrey: Color(0xFF5A7088),
    borderGrey: Color(0xFFD4E0EC),
    inputBackground: Color(0xFFF6F9FC),
    featurePrimaryBg: Color(0xFFE3F0FB),
    featureOrangeBg: Color(0xFFFFF4E5),
    featureOrangeIcon: Color(0xFFD97706),
    selectedCardBg: Color(0xFFE3F0FB),
    infoBoxBg: Color(0xFFE7F0F8),
    headerIcon: Color(0xFF3D8FD1),
    statusOrange: Color(0xFFF0A04B),
    actionOrange: Color(0xFFE67E22),
    actionBlue: Color(0xFFE3F0FB),
    actionBlueIcon: Color(0xFF1565C0),
    marketBrown: Color(0xFF7A6357),
    monthRed: Color(0xFFD32F2F),
    balanceGreenBg: Color(0xFFE5F5EA),
    updateOrangeBg: Color(0xFFFFF4E5),
    marketOrange: Color(0xFFF59E0B),
    marketOrangeDark: Color(0xFFD97706),
    marketAmountBrown: Color(0xFF5C4033),
    dateChipBg: Color(0xFFFFE8C7),
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
    primary: Color(0xFF0D9488),
    darkPrimary: Color(0xFF0F766E),
    onPrimary: Color(0xFFFFFFFF),
    banner: Color(0xFF0D9488),
    pageBackground: Color(0xFFF1F7F6),
    textDark: Color(0xFF0F2926),
    textGrey: Color(0xFF567470),
    borderGrey: Color(0xFFD0E4E1),
    inputBackground: Color(0xFFF6FBFA),
    featurePrimaryBg: Color(0xFFDDF4F1),
    featureOrangeBg: Color(0xFFFFF4E5),
    featureOrangeIcon: Color(0xFFD97706),
    selectedCardBg: Color(0xFFDDF4F1),
    infoBoxBg: Color(0xFFE2F1EF),
    headerIcon: Color(0xFF2DB5A8),
    statusOrange: Color(0xFFF0A04B),
    actionOrange: Color(0xFFE67E22),
    actionBlue: Color(0xFFE0F5F7),
    actionBlueIcon: Color(0xFF0E7490),
    marketBrown: Color(0xFF7A6357),
    monthRed: Color(0xFFD32F2F),
    balanceGreenBg: Color(0xFFE5F5EA),
    updateOrangeBg: Color(0xFFFFF4E5),
    marketOrange: Color(0xFFF59E0B),
    marketOrangeDark: Color(0xFFD97706),
    marketAmountBrown: Color(0xFF5C4033),
    dateChipBg: Color(0xFFFFE8C7),
  );

  static const sunset = AppThemePalette(
    id: AppThemeId.sunset,
    brightness: Brightness.light,
    splashBackground: Color(0xFFC2410C),
    splashCircle: Color(0xFFEA580C),
    logoGreen: Color(0xFF9A3412),
    calculatorOrange: Color(0xFFFBBF24),
    subtitle: Color(0xFFFFE0C2),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFFEA580C),
    darkPrimary: Color(0xFFC2410C),
    onPrimary: Color(0xFFFFFFFF),
    banner: Color(0xFFEA580C),
    pageBackground: Color(0xFFFFF7F2),
    textDark: Color(0xFF2A160C),
    textGrey: Color(0xFF7A5A48),
    borderGrey: Color(0xFFEAD9CC),
    inputBackground: Color(0xFFFFFBF8),
    featurePrimaryBg: Color(0xFFFFEDE3),
    featureOrangeBg: Color(0xFFFFF0D6),
    featureOrangeIcon: Color(0xFFC2410C),
    selectedCardBg: Color(0xFFFFEDE3),
    infoBoxBg: Color(0xFFFFF0E8),
    headerIcon: Color(0xFFF97316),
    statusOrange: Color(0xFFFBBF24),
    actionOrange: Color(0xFFD97706),
    actionBlue: Color(0xFFE8F1F8),
    actionBlueIcon: Color(0xFF1D6FA5),
    marketBrown: Color(0xFF7A6357),
    monthRed: Color(0xFFDC2626),
    balanceGreenBg: Color(0xFFE8F5E9),
    updateOrangeBg: Color(0xFFFFF0D6),
    marketOrange: Color(0xFFF59E0B),
    marketOrangeDark: Color(0xFFC2410C),
    marketAmountBrown: Color(0xFF5C4033),
    dateChipBg: Color(0xFFFFE0B2),
  );

  static const indigo = AppThemePalette(
    id: AppThemeId.indigo,
    brightness: Brightness.light,
    splashBackground: Color(0xFF312E81),
    splashCircle: Color(0xFF4338CA),
    logoGreen: Color(0xFF1E1B4B),
    calculatorOrange: Color(0xFFFBBF24),
    subtitle: Color(0xFFC7D2FE),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFF4F46E5),
    darkPrimary: Color(0xFF3730A3),
    onPrimary: Color(0xFFFFFFFF),
    banner: Color(0xFF4F46E5),
    pageBackground: Color(0xFFF5F5FB),
    textDark: Color(0xFF18182B),
    textGrey: Color(0xFF64647F),
    borderGrey: Color(0xFFDDDDEA),
    inputBackground: Color(0xFFFAFAFE),
    featurePrimaryBg: Color(0xFFE8E7FA),
    featureOrangeBg: Color(0xFFFFF4E5),
    featureOrangeIcon: Color(0xFFD97706),
    selectedCardBg: Color(0xFFE8E7FA),
    infoBoxBg: Color(0xFFECECF6),
    headerIcon: Color(0xFF818CF8),
    statusOrange: Color(0xFFF0A04B),
    actionOrange: Color(0xFFE67E22),
    actionBlue: Color(0xFFE8E7FA),
    actionBlueIcon: Color(0xFF4338CA),
    marketBrown: Color(0xFF7A6357),
    monthRed: Color(0xFFD32F2F),
    balanceGreenBg: Color(0xFFE5F5EA),
    updateOrangeBg: Color(0xFFFFF4E5),
    marketOrange: Color(0xFFF59E0B),
    marketOrangeDark: Color(0xFFD97706),
    marketAmountBrown: Color(0xFF5C4033),
    dateChipBg: Color(0xFFFFE8C7),
  );

  static const midnight = AppThemePalette(
    id: AppThemeId.midnight,
    brightness: Brightness.dark,
    splashBackground: Color(0xFF0B1220),
    splashCircle: Color(0xFF1A2740),
    logoGreen: Color(0xFF34D399),
    calculatorOrange: Color(0xFFFBBF24),
    subtitle: Color(0xFF94A3B8),
    loadingRing: Color(0x4DFFFFFF),
    primary: Color(0xFF34D399),
    darkPrimary: Color(0xFF10B981),
    onPrimary: Color(0xFF052E1C),
    banner: Color(0xFF1A2740),
    pageBackground: Color(0xFF0B1220),
    textDark: Color(0xFFF1F5F9),
    textGrey: Color(0xFF94A3B8),
    borderGrey: Color(0xFF2A3A52),
    inputBackground: Color(0xFF152033),
    featurePrimaryBg: Color(0xFF123528),
    featureOrangeBg: Color(0xFF3B2A12),
    featureOrangeIcon: Color(0xFFFBBF24),
    selectedCardBg: Color(0xFF123528),
    infoBoxBg: Color(0xFF152033),
    headerIcon: Color(0xFF6EE7B7),
    statusOrange: Color(0xFFFBBF24),
    actionOrange: Color(0xFFF59E0B),
    actionBlue: Color(0xFF1A3352),
    actionBlueIcon: Color(0xFF93C5FD),
    marketBrown: Color(0xFFD6B29A),
    monthRed: Color(0xFFF87171),
    balanceGreenBg: Color(0xFF123528),
    updateOrangeBg: Color(0xFF3B2A12),
    marketOrange: Color(0xFFFBBF24),
    marketOrangeDark: Color(0xFFF59E0B),
    marketAmountBrown: Color(0xFFFDE68A),
    dateChipBg: Color(0xFF3B2A12),
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
  /// Page / text / accents adjust automatically for light or dark.
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
    final onPrimary = contrastOn(primary);
    final onSurface = scheme.onSurface;
    final surface = scheme.surface;
    final surfaceContainer = scheme.surfaceContainerHighest;

    Color tint(Color base, double amount) =>
        Color.lerp(base, primary, amount)!;

    // Warm accent derived from seed (shifted toward amber).
    final warm = Color.lerp(primary, const Color(0xFFF59E0B), 0.55)!;
    final warmDark = Color.lerp(warm, Colors.black, dark ? 0.05 : 0.22)!;
    final warmSoft = dark
        ? Color.lerp(surface, warm, 0.22)!
        : Color.lerp(const Color(0xFFFFF8EF), warm, 0.12)!;

    // Cool accent for secondary actions.
    final cool = Color.lerp(primary, const Color(0xFF2563EB), 0.45)!;
    final coolSoft = dark
        ? Color.lerp(surface, cool, 0.28)!
        : Color.lerp(const Color(0xFFEFF6FF), cool, 0.14)!;

    final successSoft = dark
        ? Color.lerp(surface, const Color(0xFF22C55E), 0.22)!
        : const Color(0xFFE8F5E9);

    return AppThemePalette(
      id: id,
      brightness: brightness,
      splashBackground:
          dark ? surface : Color.lerp(primary, Colors.black, 0.28)!,
      splashCircle: primary,
      logoGreen: Color.lerp(primary, Colors.black, dark ? 0.0 : 0.18)!,
      calculatorOrange: warm,
      subtitle: dark
          ? onSurface.withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.88),
      loadingRing: const Color(0x4DFFFFFF),
      primary: primary,
      darkPrimary: Color.lerp(primary, Colors.black, 0.32)!,
      onPrimary: onPrimary,
      banner: dark ? surfaceContainer : primary,
      pageBackground: dark
          ? Color.lerp(surface, Colors.black, 0.18)!
          : Color.lerp(surface, primary, 0.035)!,
      textDark: onSurface,
      textGrey: onSurface.withValues(alpha: dark ? 0.68 : 0.58),
      borderGrey: dark
          ? scheme.outlineVariant
          : Color.lerp(scheme.outlineVariant, primary, 0.1)!,
      inputBackground:
          dark ? surfaceContainer : Color.lerp(surface, primary, 0.028)!,
      featurePrimaryBg: tint(surface, dark ? 0.26 : 0.12),
      featureOrangeBg: warmSoft,
      featureOrangeIcon: warmDark,
      selectedCardBg: tint(surface, dark ? 0.3 : 0.14),
      infoBoxBg: tint(surface, dark ? 0.2 : 0.09),
      headerIcon: Color.lerp(primary, onSurface, dark ? 0.15 : 0.22)!,
      statusOrange: warm,
      actionOrange: warmDark,
      actionBlue: coolSoft,
      actionBlueIcon: cool,
      marketBrown: dark
          ? const Color(0xFFD6B29A)
          : Color.lerp(const Color(0xFF7A6357), primary, 0.08)!,
      monthRed: dark ? const Color(0xFFF87171) : const Color(0xFFD32F2F),
      balanceGreenBg: successSoft,
      updateOrangeBg: warmSoft,
      marketOrange: warm,
      marketOrangeDark: warmDark,
      marketAmountBrown: dark
          ? const Color(0xFFFDE68A)
          : const Color(0xFF5C4033),
      dateChipBg: warmSoft,
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
