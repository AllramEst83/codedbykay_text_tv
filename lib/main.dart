import 'package:codedbykay_text_tv/app.dart';
import 'package:codedbykay_text_tv/services/http_fetcher.dart';
import 'package:codedbykay_text_tv/services/io_http_fetcher.dart';
import 'package:codedbykay_text_tv/services/live_text_tv_repository.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final HttpFetcher fetcher = IoHttpFetcher();
  runApp(
    TextTvApp(
      repository: LiveTextTvRepository(textTv: TextTv(fetcher: fetcher)),
    ),
  );
}
