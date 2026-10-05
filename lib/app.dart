import 'package:codedbykay_text_tv/messages.dart';
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
  const TextTvApp({super.key, required this.repository});

  final TextTvRepository repository;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: textTvSystemUi,
      child: MaterialApp(
        title: Messages.title,
        debugShowCheckedModeBanner: false,
        theme: textTvTheme(),
        home: TextTvScreen(repository: repository),
      ),
    );
  }
}
