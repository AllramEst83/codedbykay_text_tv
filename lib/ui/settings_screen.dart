import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

/// The settings page, opened from the gear button. Nothing is set here yet;
/// settings are added to it as the app gets them.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TvColors.black,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(TvMetrics.gutter),
              child: Row(
                children: <Widget>[
                  TvButton(
                    key: textTvSettingsBackKey,
                    label: '<',
                    semanticLabel: Messages.back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: TvMetrics.margin),
                  Expanded(
                    child: Text(
                      Messages.settingsTitle,
                      style: tvText(14, TvColors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  Messages.noSettings,
                  style: tvText(10, TvColors.dim),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
