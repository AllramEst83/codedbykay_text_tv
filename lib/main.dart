import 'dart:async';
import 'dart:io';

import 'package:codedbykay_text_tv/app.dart';
import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/refresh_settings.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/services/controls_settings_store.dart';
import 'package:codedbykay_text_tv/services/crt_settings_store.dart';
import 'package:codedbykay_text_tv/services/http_fetcher.dart';
import 'package:codedbykay_text_tv/services/io_http_fetcher.dart';
import 'package:codedbykay_text_tv/services/live_text_tv_repository.dart';
import 'package:codedbykay_text_tv/services/page_disk_cache.dart';
import 'package:codedbykay_text_tv/services/reader_settings_store.dart';
import 'package:codedbykay_text_tv/services/refresh_settings_store.dart';
import 'package:codedbykay_text_tv/services/saved_pages_store.dart';
import 'package:codedbykay_text_tv/services/session_store.dart';
import 'package:codedbykay_text_tv/services/shortcut_service.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final HttpFetcher fetcher = IoHttpFetcher();
  final SessionStore store = PrefsSessionStore();
  final PageDiskCache? disk = await _pageCache();
  final TextTvSession session = await store.load();
  final ReaderSettingsStore readerStore = PrefsReaderSettingsStore();
  final ReaderSettings reader = await readerStore.load();
  final CrtSettingsStore crtStore = PrefsCrtSettingsStore();
  final CrtSettings crt = await crtStore.load();
  final RefreshSettingsStore refreshStore = PrefsRefreshSettingsStore();
  final RefreshSettings refresh = await refreshStore.load();
  final ControlsSettingsStore controlsStore = PrefsControlsSettingsStore();
  final ControlsSettings controls = await controlsStore.load();
  final SavedPagesStore savedStore = PrefsSavedPagesStore();
  final SavedPages saved = await savedStore.load();
  final ShortcutService shortcuts = ShortcutService(QuickActionsShortcuts());
  await shortcuts.start();
  runApp(
    TextTvApp(
      repository: LiveTextTvRepository(
        textTv: TextTv(fetcher: fetcher),
        disk: disk,
      ),
      session: session,
      onSessionChanged: (TextTvSession s) => unawaited(store.save(s)),
      reader: reader,
      crt: crt,
      onCrtChanged: (CrtSettings c) => unawaited(crtStore.save(c)),
      refresh: refresh,
      onRefreshChanged: (RefreshSettings r) => unawaited(refreshStore.save(r)),
      controls: controls,
      onControlsChanged: (ControlsSettings c) =>
          unawaited(controlsStore.save(c)),
      saved: saved,
      onSavedChanged: (SavedPages p) => unawaited(savedStore.save(p)),
      shortcuts: shortcuts,
      onReaderChanged: (ReaderSettings r) => unawaited(readerStore.save(r)),
    ),
  );
}

/// Pages saved between runs live in the app's cache folder, which Android may
/// clear when space is short; without one the app just works online only.
Future<PageDiskCache?> _pageCache() async {
  try {
    final Directory root = await getApplicationCacheDirectory();
    return FilePageDiskCache(Directory('${root.path}/pages'));
  } on Object {
    return null;
  }
}
