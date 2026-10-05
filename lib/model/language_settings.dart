import 'dart:convert';
import 'dart:ui' show Locale;

/// Which language the app speaks.
enum AppLanguage {
  /// The phone's: Swedish on a Swedish phone, English on any other.
  system,
  swedish,
  english;

  /// The locale to force, or null to follow the phone.
  Locale? get locale => switch (this) {
    AppLanguage.system => null,
    AppLanguage.swedish => const Locale('sv'),
    AppLanguage.english => const Locale('en'),
  };
}

/// The languages the app has words for, English first: it is what any other
/// language gets.
const List<Locale> appLocales = <Locale>[Locale('en'), Locale('sv')];

/// The locale the app uses for a phone set to [device]: Swedish for Swedish,
/// English for everything else (Danish, say).
Locale resolveLocale(Locale? device) =>
    device?.languageCode == 'sv' ? const Locale('sv') : const Locale('en');

/// The language setting, kept between runs. Read from disk, so decoding is
/// tolerant: anything unreadable is [AppLanguage.system].
class LanguageSettings {
  const LanguageSettings({this.language = AppLanguage.system});

  final AppLanguage language;

  static const LanguageSettings defaults = LanguageSettings();

  LanguageSettings copyWith({AppLanguage? language}) =>
      LanguageSettings(language: language ?? this.language);

  factory LanguageSettings.decode(String? source) {
    if (source == null) return defaults;
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return defaults;
    }
    if (json is! Map<String, Object?>) return defaults;
    return LanguageSettings(
      language:
          AppLanguage.values.asNameMap()[json['language']] ??
          AppLanguage.system,
    );
  }

  String encode() => jsonEncode(<String, Object?>{'language': language.name});

  @override
  bool operator ==(Object other) =>
      other is LanguageSettings && other.language == language;

  @override
  int get hashCode => language.hashCode;
}
