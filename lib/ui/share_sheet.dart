import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

/// What can be done with the page on show.
enum ShareAction { copyText, shareText, shareLink, shareImage }

/// Opens the ways to copy or share the page over it. The sheet closes itself
/// when one is chosen, and then [onChosen] is told which.
Future<void> showShareSheet(
  BuildContext context, {
  required ValueChanged<ShareAction> onChosen,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TvColors.black,
    barrierColor: Colors.black38,
    shape: const RoundedRectangleBorder(),
    builder: (BuildContext sheet) {
      void choose(ShareAction action) {
        Navigator.of(sheet).pop();
        onChosen(action);
      }

      return SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: TvColors.border, width: TvMetrics.border),
            ),
          ),
          padding: const EdgeInsets.all(TvMetrics.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(Messages.shareTitle, style: tvText(12, TvColors.white)),
              const SizedBox(height: TvMetrics.margin),
              TvButton(
                key: textTvCopyTextKey,
                label: Messages.copyText,
                onTap: () => choose(ShareAction.copyText),
              ),
              const SizedBox(height: TvMetrics.gutter),
              TvButton(
                key: textTvShareTextKey,
                label: Messages.shareText,
                onTap: () => choose(ShareAction.shareText),
              ),
              const SizedBox(height: TvMetrics.gutter),
              TvButton(
                key: textTvShareLinkKey,
                label: Messages.shareLink,
                onTap: () => choose(ShareAction.shareLink),
              ),
              const SizedBox(height: TvMetrics.gutter),
              TvButton(
                key: textTvShareImageKey,
                label: Messages.shareImage,
                onTap: () => choose(ShareAction.shareImage),
              ),
            ],
          ),
        ),
      );
    },
  );
}
