import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'app_theme_palette.dart';

class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'app_theme_id';
  static const _prefsCustomColor = 'app_theme_custom_color';
  static const _prefsCustomDark = 'app_theme_custom_dark';

  AppThemeId _themeId = AppThemeId.forest;
  Color _customPrimary = const Color(0xFF2E7D32);
  bool _customDark = false;

  AppThemeId get themeId => _themeId;
  Color get customPrimary => _customPrimary;
  bool get customDark => _customDark;

  AppThemePalette get palette {
    if (_themeId == AppThemeId.custom) {
      return AppThemePalette.fromSeed(
        _customPrimary,
        brightness: _customDark ? Brightness.dark : Brightness.light,
      );
    }
    return AppThemePalette.byId(_themeId);
  }

  bool get isDark => palette.brightness == Brightness.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final parsed = AppThemePalette.tryParseId(prefs.getString(_prefsKey));
    if (parsed != null) {
      _themeId = parsed;
    }
    final colorValue = prefs.getInt(_prefsCustomColor);
    if (colorValue != null) {
      _customPrimary = Color(colorValue);
    }
    _customDark = prefs.getBool(_prefsCustomDark) ?? false;
    AppColors.apply(palette);
  }

  Future<void> setTheme(AppThemeId id) async {
    if (id == AppThemeId.custom) {
      await setCustomColor(_customPrimary, dark: _customDark);
      return;
    }
    if (id == _themeId && id != AppThemeId.custom) return;
    _themeId = id;
    AppColors.apply(palette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id.name);
    notifyListeners();
  }

  /// Pick any theme color — text / background colors update automatically.
  Future<void> setCustomColor(Color color, {bool? dark}) async {
    _themeId = AppThemeId.custom;
    _customPrimary = color;
    if (dark != null) _customDark = dark;
    AppColors.apply(palette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, AppThemeId.custom.name);
    await prefs.setInt(_prefsCustomColor, color.toARGB32());
    await prefs.setBool(_prefsCustomDark, _customDark);
    notifyListeners();
  }

  Future<void> setCustomDark(bool value) async {
    if (_themeId != AppThemeId.custom) {
      await setCustomColor(palette.primary, dark: value);
      return;
    }
    await setCustomColor(_customPrimary, dark: value);
  }

  ThemeData buildThemeData({required bool isBengali}) {
    final p = palette;
    AppColors.apply(p);
    final baseText = isBengali
        ? GoogleFonts.notoSansBengaliTextTheme()
        : GoogleFonts.interTextTheme();
    final coloredText = baseText.apply(
      bodyColor: p.textDark,
      displayColor: p.textDark,
    );

    return ThemeData(
      brightness: p.brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: p.brightness,
        primary: p.primary,
        onPrimary: Colors.white,
        surface: p.brightness == Brightness.dark
            ? p.inputBackground
            : Colors.white,
        onSurface: p.textDark,
      ),
      scaffoldBackgroundColor: p.pageBackground,
      cardColor:
          p.brightness == Brightness.dark ? p.inputBackground : Colors.white,
      cardTheme: CardThemeData(
        color: p.brightness == Brightness.dark ? p.inputBackground : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.borderGrey),
        ),
      ),
      dividerColor: p.borderGrey,
      textTheme: coloredText,
      primaryTextTheme: coloredText,
      appBarTheme: AppBarTheme(
        backgroundColor: p.pageBackground,
        foregroundColor: p.textDark,
        elevation: 0,
        titleTextStyle: (isBengali
                ? GoogleFonts.notoSansBengali
                : GoogleFonts.inter)(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.textDark,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.darkPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
        ),
      ),
      useMaterial3: true,
    );
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found');
    return scope!.notifier!;
  }

  static ThemeController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
  }
}
