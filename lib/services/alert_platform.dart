import 'dart:ui' as ui;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The phone's notifications, as little as it can be: [LocalNotificationsAlerts]
/// is the real one; tests use a fake. Nothing here throws: a phone that cannot
/// notify just does not.
abstract interface class AlertPlatform {
  /// Starts hearing taps on a notification: [onPage] gets the page it was for,
  /// also when the tap is what started the app.
  Future<void> start(void Function(int page) onPage);

  /// Asks the user for permission to notify (Android 13 and later ask). True
  /// when notifications may be shown.
  Future<bool> requestPermission();

  /// Whether notifications may be shown now.
  Future<bool> allowed();

  /// Shows a notification that [headline] is new on [page].
  Future<void> show(int page, String headline);
}

/// [AlertPlatform] on the `flutter_local_notifications` plugin.
class LocalNotificationsAlerts implements AlertPlatform {
  LocalNotificationsAlerts();

  static const String _channelId = 'breaking';
  static const String _icon = 'ic_stat_texttv';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // The background job has no screen and so no localizations: the two words
  // needed are chosen here by the phone's language.
  bool get _swedish =>
      ui.PlatformDispatcher.instance.locale.languageCode == 'sv';
  String get _channelName => _swedish ? 'Senaste nytt' : 'Breaking news';
  String get _channelDescription => _swedish
      ? 'När den översta rubriken på en vald text-tv-sida byts ut'
      : 'When the top headline of a chosen Text TV page changes';
  String get _title => _swedish ? 'Text-TV' : 'Text TV';

  Future<void> _init({void Function(NotificationResponse)? onTap}) async {
    if (_ready && onTap == null) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
      onDidReceiveNotificationResponse: onTap,
    );
    _ready = true;
  }

  @override
  Future<void> start(void Function(int page) onPage) async {
    try {
      await _init(
        onTap: (NotificationResponse response) {
          final int? page = int.tryParse(response.payload ?? '');
          if (page != null) onPage(page);
        },
      );
      final NotificationAppLaunchDetails? launch = await _plugin
          .getNotificationAppLaunchDetails();
      final int? first = int.tryParse(
        launch?.notificationResponse?.payload ?? '',
      );
      if (launch?.didNotificationLaunchApp ?? false) {
        if (first != null) onPage(first);
      }
    } on Object {
      // No notifications here: nothing to hear.
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    try {
      await _init();
      return await _android?.requestNotificationsPermission() ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> allowed() async {
    try {
      await _init();
      return await _android?.areNotificationsEnabled() ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> show(int page, String headline) async {
    try {
      await _init();
      await _plugin.show(
        id: page,
        title: '$_title $page',
        body: headline,
        payload: '$page',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            icon: _icon,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    } on Object {
      // Not shown: the next change is tried again.
    }
  }
}
