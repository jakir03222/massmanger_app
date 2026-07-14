import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'app_locale';
  static const supportedLocales = [Locale('bn'), Locale('en')];

  Locale _locale = const Locale('bn');

  Locale get locale => _locale;
  bool get isBengali => _locale.languageCode == 'bn';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == 'en' || code == 'bn') {
      _locale = Locale(code!);
    }
  }

  Future<void> setBengali(bool value) async {
    final next = Locale(value ? 'bn' : 'en');
    if (next == _locale) return;
    _locale = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _locale.languageCode);
    notifyListeners();
  }

  Future<void> toggle() => setBengali(!isBengali);
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found');
    return scope!.notifier!;
  }

  static LocaleController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.notifier;
  }
}
