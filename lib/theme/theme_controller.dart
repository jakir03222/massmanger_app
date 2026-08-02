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
  Color _customPrimary = const Color(0xFF2F7D32);
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
    final fontFamily =
        isBengali ? GoogleFonts.notoSansBengali : GoogleFonts.inter;
    final baseText = isBengali
        ? GoogleFonts.notoSansBengaliTextTheme()
        : GoogleFonts.interTextTheme();
    final coloredText = baseText.apply(
      bodyColor: p.textDark,
      displayColor: p.textDark,
    );
    final cardColor =
        p.brightness == Brightness.dark ? p.inputBackground : Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.actionOrange,
      onSecondary: AppThemePalette.contrastOn(p.actionOrange),
      surface: cardColor,
      onSurface: p.textDark,
      error: p.monthRed,
      onError: Colors.white,
      outline: p.borderGrey,
    );

    return ThemeData(
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.pageBackground,
      canvasColor: p.pageBackground,
      cardColor: cardColor,
      dividerColor: p.borderGrey,
      textTheme: coloredText,
      primaryTextTheme: coloredText,
      iconTheme: IconThemeData(color: p.textDark),
      primaryIconTheme: IconThemeData(color: p.onPrimary),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.borderGrey),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.pageBackground,
        foregroundColor: p.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: p.textDark),
        actionsIconTheme: IconThemeData(color: p.textDark),
        titleTextStyle: fontFamily(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.textDark,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: fontFamily(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.textDark,
        ),
        contentTextStyle: fontFamily(
          fontSize: 14,
          color: p.textGrey,
          height: 1.4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textGrey,
        textColor: p.textDark,
        titleTextStyle: fontFamily(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: p.textDark,
        ),
        subtitleTextStyle: fontFamily(
          fontSize: 13,
          color: p.textGrey,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.featurePrimaryBg,
        selectedColor: p.primary,
        disabledColor: p.borderGrey,
        labelStyle: fontFamily(fontSize: 13, color: p.textDark),
        secondaryLabelStyle: fontFamily(fontSize: 13, color: p.onPrimary),
        side: BorderSide(color: p.borderGrey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputBackground,
        hintStyle: fontFamily(color: p.textGrey.withValues(alpha: 0.85)),
        labelStyle: fontFamily(color: p.textGrey),
        floatingLabelStyle: fontFamily(color: p.primary),
        prefixIconColor: p.textGrey,
        suffixIconColor: p.textGrey,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.monthRed),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.darkPrimary,
        contentTextStyle: fontFamily(
          color: AppThemePalette.contrastOn(p.darkPrimary),
          fontSize: 14,
        ),
        actionTextColor: AppThemePalette.contrastOn(p.darkPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.borderGrey,
          disabledForegroundColor: p.textGrey,
          elevation: 0,
          textStyle: fontFamily(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          textStyle: fontFamily(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: fontFamily(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary.withValues(alpha: 0.55)),
          textStyle: fontFamily(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return p.textGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.primary.withValues(alpha: 0.35);
          }
          return p.borderGrey;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        side: BorderSide(color: p.borderGrey, width: 1.6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        circularTrackColor: p.featurePrimaryBg,
      ),
      dividerTheme: DividerThemeData(
        color: p.borderGrey,
        thickness: 1,
        space: 1,
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
