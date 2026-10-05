import 'dart:async';

import 'package:codedbykay_text_tv/app.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/services/http_fetcher.dart';
import 'package:codedbykay_text_tv/services/io_http_fetcher.dart';
import 'package:codedbykay_text_tv/services/live_text_tv_repository.dart';
import 'package:codedbykay_text_tv/services/session_store.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final HttpFetcher fetcher = IoHttpFetcher();
  final SessionStore store = PrefsSessionStore();
  final TextTvSession session = await store.load();
  runApp(
    TextTvApp(
      repository: LiveTextTvRepository(textTv: TextTv(fetcher: fetcher)),
      session: session,
      onSessionChanged: (TextTvSession s) => unawaited(store.save(s)),
    ),
  );
}
