import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/refresh_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/services/text_tv_repository.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The page is always black, so the system bars are too: drawn edge to edge
/// with light icons.
const SystemUiOverlayStyle textTvSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarColor: TvColors.black,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarDividerColor: TvColors.black,
  systemNavigationBarContrastEnforced: false,
);

class TextTvApp extends StatelessWidget {
  const TextTvApp({
    super.key,
    required this.repository,
    this.session = const TextTvSession(),
    this.onSessionChanged,
    this.reader = const ReaderSettings(),
    this.onReaderChanged,
    this.crt = CrtSettings.defaults,
    this.onCrtChanged,
    this.refresh = const RefreshSettings(),
    this.onRefreshChanged,
  });

  final TextTvRepository repository;

  /// Where the reader left off, or the front page.
  final TextTvSession session;
  final ValueChanged<TextTvSession>? onSessionChanged;

  /// How the reader was set up on the last run.
  final ReaderSettings reader;
  final ValueChanged<ReaderSettings>? onReaderChanged;

  /// The CRT look of the teletext page on the last run.
  final CrtSettings crt;
  final ValueChanged<CrtSettings>? onCrtChanged;

  /// Whether the page refreshes by itself, as of the last run.
  final RefreshSettings refresh;
  final ValueChanged<RefreshSettings>? onRefreshChanged;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: textTvSystemUi,
      child: MaterialApp(
        title: Messages.title,
        debugShowCheckedModeBanner: false,
        theme: textTvTheme(),
        home: TextTvScreen(
          repository: repository,
          initial: session,
          onSessionChanged: onSessionChanged,
          reader: reader,
          onReaderChanged: onReaderChanged,
          crt: crt,
          onCrtChanged: onCrtChanged,
          refresh: refresh,
          onRefreshChanged: onRefreshChanged,
        ),
      ),
    );
  }
}
