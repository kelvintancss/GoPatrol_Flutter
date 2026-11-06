import 'package:flutter/material.dart';
import 'package:patrol/core/services/user_preference.dart';
import 'package:patrol/service_locator.dart';

/// Runtime-switchable app locale, backed by [UserPreferences] so the choice
/// survives app restarts. `PatrolApp` listens to [notifier] to rebuild
/// `MaterialApp.router` with the selected [Locale].
class LocaleController {
  LocaleController._();

  static const List<String> supportedLanguageCodes = ['en', 'ms'];

  static final ValueNotifier<Locale> notifier = ValueNotifier(Locale(_initLanguageCode()));

  /// Reads the stored language code, falling back to (and persisting) 'en'
  /// so a fresh install has a real, saved value rather than a value that
  /// only ever existed as [UserPreferences.getLangCodeOrDefault]'s in-memory
  /// fallback.
  static String _initLanguageCode() {
    final prefs = sl<UserPreferences>();
    final code = _sanitize(prefs.getLangCodeOrDefault);
    prefs.setLanguageCode(code);
    return code;
  }

  static String _sanitize(String code) => supportedLanguageCodes.contains(code) ? code : 'en';

  static Locale get current => notifier.value;

  static Future<void> setLocale(String languageCode) async {
    if (notifier.value.languageCode == languageCode) return;
    await sl<UserPreferences>().setLanguageCode(languageCode);
    notifier.value = Locale(languageCode);
  }
}
