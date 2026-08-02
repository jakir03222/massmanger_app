import 'package:flutter/material.dart';

import 'app_theme_palette.dart';

/// App-wide colors. Values follow the active [AppThemePalette]
/// (set by [ThemeController] via [apply]).
abstract final class AppColors {
  static AppThemePalette _palette = AppThemePalette.forest;

  static AppThemePalette get palette => _palette;

  static void apply(AppThemePalette palette) {
    _palette = palette;
  }

  static Color get splashBackground => _palette.splashBackground;
  static Color get splashCircle => _palette.splashCircle;
  static Color get logoGreen => _palette.logoGreen;
  static Color get calculatorOrange => _palette.calculatorOrange;
  static Color get subtitle => _palette.subtitle;
  static Color get loadingRing => _palette.loadingRing;

  static Color get primaryGreen => _palette.primary;
  static Color get darkGreen => _palette.darkPrimary;
  static Color get onPrimary => _palette.onPrimary;
  static Color get bannerGreen => _palette.banner;
  static Color get pageBackground => _palette.pageBackground;
  static Color get textDark => _palette.textDark;
  static Color get textGrey => _palette.textGrey;
  static Color get borderGrey => _palette.borderGrey;
  static Color get inputBackground => _palette.inputBackground;
  static Color get featureGreenBg => _palette.featurePrimaryBg;
  static Color get featureOrangeBg => _palette.featureOrangeBg;
  static Color get featureOrangeIcon => _palette.featureOrangeIcon;
  static Color get selectedCardBg => _palette.selectedCardBg;
  static Color get infoBoxBg => _palette.infoBoxBg;
  static Color get headerIcon => _palette.headerIcon;

  static Color get statusOrange => _palette.statusOrange;
  static Color get actionOrange => _palette.actionOrange;
  static Color get actionBlue => _palette.actionBlue;
  static Color get actionBlueIcon => _palette.actionBlueIcon;
  static Color get marketBrown => _palette.marketBrown;
  static Color get monthRed => _palette.monthRed;
  static Color get balanceGreenBg => _palette.balanceGreenBg;
  static Color get updateOrangeBg => _palette.updateOrangeBg;

  static Color get marketOrange => _palette.marketOrange;
  static Color get marketOrangeDark => _palette.marketOrangeDark;
  static Color get marketAmountBrown => _palette.marketAmountBrown;
  static Color get dateChipBg => _palette.dateChipBg;

  /// Cards / sheets — white in light themes, elevated surface in dark.
  static Color get card =>
      _palette.brightness == Brightness.dark
          ? _palette.inputBackground
          : const Color(0xFFFFFFFF);

  /// Readable text/icon color for a filled background.
  static Color on(Color background) => AppThemePalette.contrastOn(background);
}
