import 'dart:convert';

import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// How often the background job looks at texttv.nu. Android's own floor for
/// periodic work is 15 minutes; these stay above it, and a longer wait costs
/// the site and the battery less.
const List<Duration> backgroundIntervals = <Duration>[
  Duration(minutes: 30),
  Duration(hours: 1),
  Duration(hours: 3),
];

/// The step a fresh install starts at: an index into [backgroundIntervals].
const int backgroundDefaultInterval = 1;

/// The page the widget and the alerts start on.
const int backgroundDefaultPage = 100;

/// What the app does in the background, kept between runs. Read from disk, so
/// decoding is tolerant: a bad field is replaced by its default. [interval] is
/// an index into [backgroundIntervals], so no value can be one the job was not
/// made for.
class BackgroundSettings {
  const BackgroundSettings({
    this.widgetPage = backgroundDefaultPage,
    this.interval = backgroundDefaultInterval,
    this.alerts = false,
    this.alertPage = backgroundDefaultPage,
  });

  /// The page whose headlines the home-screen widget shows.
  final int widgetPage;

  /// An index into [backgroundIntervals].
  final int interval;

  /// Whether a notification is shown when the top headline of [alertPage]
  /// changes. Off until the user turns it on.
  final bool alerts;

  /// The page the alerts watch.
  final int alertPage;

  static const BackgroundSettings defaults = BackgroundSettings();

  Duration get every => backgroundIntervals[interval];

  BackgroundSettings copyWith({
    int? widgetPage,
    int? interval,
    bool? alerts,
    int? alertPage,
  }) => BackgroundSettings(
    widgetPage: widgetPage ?? this.widgetPage,
    interval: interval ?? this.interval,
    alerts: alerts ?? this.alerts,
    alertPage: alertPage ?? this.alertPage,
  );

  static int _page(Object? value) =>
      value is int && value >= textTvFirstPage && value <= textTvLastPage
      ? value
      : backgroundDefaultPage;

  static int _step(Object? value) =>
      value is int && value >= 0 && value < backgroundIntervals.length
      ? value
      : backgroundDefaultInterval;

  factory BackgroundSettings.decode(String? source) {
    if (source == null) return defaults;
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return defaults;
    }
    if (json is! Map<String, Object?>) return defaults;
    return BackgroundSettings(
      widgetPage: _page(json['widgetPage']),
      interval: _step(json['interval']),
      alerts: json['alerts'] == true,
      alertPage: _page(json['alertPage']),
    );
  }

  String encode() => jsonEncode(<String, Object?>{
    'widgetPage': widgetPage,
    'interval': interval,
    'alerts': alerts,
    'alertPage': alertPage,
  });

  @override
  bool operator ==(Object other) =>
      other is BackgroundSettings &&
      other.widgetPage == widgetPage &&
      other.interval == interval &&
      other.alerts == alerts &&
      other.alertPage == alertPage;

  @override
  int get hashCode => Object.hash(widgetPage, interval, alerts, alertPage);
}
