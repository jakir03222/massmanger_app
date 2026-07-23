import 'app_strings.dart';
import 'locale_controller.dart';

/// Global access to the active language (for services without BuildContext).
abstract final class AppLocale {
  static LocaleController? _controller;

  static void bind(LocaleController controller) {
    _controller = controller;
  }

  static LocaleController? get controller => _controller;

  static bool get isBengali => _controller?.isBengali ?? true;

  static AppStrings get strings =>
      isBengali ? AppStrings.bn() : AppStrings.en();

  /// Pick bn/en text for the active language.
  static String pick(String bn, String en) => isBengali ? bn : en;
}
