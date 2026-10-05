import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:codedbykay_text_tv/model/page_share.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_page_area.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// How wide the picture is, in logical pixels; [_scale] makes it sharp.
const double _snapshotWidth = 480;
const double _scale = 3;

/// A PNG of part [part] of [page] as teletext (its colours, on black, with the
/// page's address under it), the same whatever the screen shows: reader mode,
/// the CRT look and the phone's size do not change it. Null if it could not be
/// drawn.
///
/// The picture is built off to the side of the screen, in [context]'s overlay,
/// so it gets the app's theme and fonts, and taken once it has been drawn.
Future<Uint8List?> capturePageImage(
  BuildContext context,
  TextTvPage page,
  int part, {
  PageFont font = PageFont.pixel,
}) async {
  final OverlayState? overlay = Overlay.maybeOf(context);
  if (overlay == null) return null;
  final GlobalKey boundary = GlobalKey();
  final OverlayEntry entry = OverlayEntry(
    builder: (BuildContext context) => Positioned(
      left: -_snapshotWidth * 2,
      top: 0,
      width: _snapshotWidth,
      child: RepaintBoundary(
        key: boundary,
        child: ColoredBox(
          color: TvColors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: TvMetrics.margin),
              TvGrid(
                page: page,
                part: part,
                onLink: (String _) {},
                width: _snapshotWidth,
                height: 0,
                font: font,
              ),
              const SizedBox(height: TvMetrics.gutter),
              Text(
                pageLink(page.number).replaceFirst('https://', ''),
                style: tvText(8, TvColors.dim),
              ),
              const SizedBox(height: TvMetrics.margin),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    // One frame to build and paint it.
    await WidgetsBinding.instance.endOfFrame;
    final RenderObject? render = boundary.currentContext?.findRenderObject();
    if (render is! RenderRepaintBoundary) return null;
    final ui.Image image = await render.toImage(pixelRatio: _scale);
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    return bytes?.buffer.asUint8List();
  } on Object {
    return null;
  } finally {
    entry.remove();
    entry.dispose();
  }
}
