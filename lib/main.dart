import 'dart:async';
import 'dart:io';

import 'package:codedbykay_text_tv/app.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/services/http_fetcher.dart';
import 'package:codedbykay_text_tv/services/io_http_fetcher.dart';
import 'package:codedbykay_text_tv/services/live_text_tv_repository.dart';
import 'package:codedbykay_text_tv/services/page_disk_cache.dart';
import 'package:codedbykay_text_tv/services/reader_settings_store.dart';
import 'package:codedbykay_text_tv/services/session_store.dart';
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
  runApp(
    TextTvApp(
      repository: LiveTextTvRepository(
        textTv: TextTv(fetcher: fetcher),
        disk: disk,
      ),
      session: session,
      onSessionChanged: (TextTvSession s) => unawaited(store.save(s)),
      reader: reader,
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
