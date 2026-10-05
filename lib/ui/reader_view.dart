import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/reader_content.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The page as text to read: reflowed to the screen's width in the reader's
/// colours and size, with headlines, links and tables kept (see
/// `buildReaderBlocks`). Fills its space with the reader's background; loading,
/// failure and unbroadcast pages say so here too, in the same colours.
class ReaderView extends StatelessWidget {
  const ReaderView({
    super.key,
    required this.number,
    required this.part,
    required this.loading,
    required this.result,
    required this.settings,
    required this.onLink,
    required this.onRetry,
  });

  final int number;
  final int part;
  final bool loading;
  final TextTvResult? result;
  final ReaderSettings settings;
  final ValueChanged<int> onLink;
  final VoidCallback onRetry;

  /// A line of text stops widening past this, so a tablet is not read across.
  static const double _widest = 680;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = readerPalette(settings.theme);
    final TextStyle base = readerTextStyle(settings.fontSize, palette.text);
    final TextTvResult? shown = result;
    final Widget content;
    if (loading || shown == null) {
      content = _Message(
        lines: const <String>[Messages.readerLoading],
        base: base,
      );
    } else {
      content = switch (shown) {
        TextTvShown(:final TextTvPage page) => _Page(
          blocks: buildReaderBlocks(page, part),
          settings: settings,
          palette: palette,
          onLink: onLink,
        ),
        TextTvNotBroadcast(:final int number) => _Message(
          lines: <String>[Messages.readerNotBroadcast(number)],
          base: base,
        ),
        TextTvFailed(:final String reason) => _Message(
          lines: <String>[reason],
          base: base,
          retry: _RetryButton(onTap: onRetry, palette: palette, base: base),
        ),
      };
    }
    return ColoredBox(
      key: textTvReaderViewKey,
      color: palette.background,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _widest),
          child: content,
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.blocks,
    required this.settings,
    required this.palette,
    required this.onLink,
  });

  final List<ReaderBlock> blocks;
  final ReaderSettings settings;
  final ReaderPalette palette;
  final ValueChanged<int> onLink;

  @override
  Widget build(BuildContext context) {
    final double size = settings.fontSize;
    final TextStyle body = readerTextStyle(size, palette.text);
    final TextStyle heading = readerTextStyle(
      size * 1.3,
      palette.text,
      weight: FontWeight.w700,
      height: 1.25,
    );
    final TextStyle dim = readerTextStyle(size * 0.75, palette.dim);

    Widget tappable(int page, String label, Widget child) => Semantics(
      button: true,
      label: '$label. ${Messages.pageLabel(page)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onLink(page),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ),
    );

    Widget text(List<ReaderSpan> spans, TextStyle style, {int? link}) =>
        _ReaderText(
          spans: spans,
          style: style,
          linkColor: palette.link,
          onLink: onLink,
          suffixPage: link,
        );

    final List<Widget> children = <Widget>[];
    for (final ReaderBlock block in blocks) {
      children.add(switch (block) {
        ReaderCaption(:final String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text, style: dim),
        ),
        ReaderHeading(:final List<ReaderSpan> spans, :final int? link) =>
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: link == null
                ? text(spans, heading)
                : tappable(
                    link,
                    spans.map((ReaderSpan s) => s.text).join(),
                    text(spans, heading, link: link),
                  ),
          ),
        ReaderParagraph(:final List<ReaderSpan> spans, :final int? link) =>
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: link == null
                ? text(spans, body)
                : tappable(
                    link,
                    spans.map((ReaderSpan s) => s.text).join(),
                    text(spans, body, link: link),
                  ),
          ),
        ReaderColumns(:final String left, :final String right) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 3, child: Text(left, style: body)),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(right, style: body, textAlign: TextAlign.end),
              ),
            ],
          ),
        ),
        ReaderNav(:final List<ReaderLink> links) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final ReaderLink link in links)
                _NavChip(
                  link: link,
                  style: body,
                  palette: palette,
                  onTap: () => onLink(link.page),
                ),
            ],
          ),
        ),
      });
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: children,
    );
  }
}

/// Text with links in it: a span with a page opens that page when tapped. The
/// recognisers it needs live as long as the text does.
class _ReaderText extends StatefulWidget {
  const _ReaderText({
    required this.spans,
    required this.style,
    required this.linkColor,
    required this.onLink,
    this.suffixPage,
  });

  final List<ReaderSpan> spans;
  final TextStyle style;
  final Color linkColor;
  final ValueChanged<int> onLink;

  /// A page number shown after the text as a link, for a block that is a
  /// link as a whole.
  final int? suffixPage;

  @override
  State<_ReaderText> createState() => _ReaderTextState();
}

class _ReaderTextState extends State<_ReaderText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];
  late TextSpan _span = _build();

  @override
  void didUpdateWidget(_ReaderText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _release();
    _span = _build();
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  void _release() {
    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TextSpan _build() {
    final TextStyle link = TextStyle(
      color: widget.linkColor,
      decoration: TextDecoration.underline,
      decorationColor: widget.linkColor,
    );
    return TextSpan(
      style: widget.style,
      children: <InlineSpan>[
        for (final ReaderSpan span in widget.spans)
          if (span.page case final int page)
            TextSpan(text: span.text, style: link, recognizer: _recognize(page))
          else
            TextSpan(text: span.text),
        if (widget.suffixPage case final int page)
          TextSpan(text: '  $page', style: link),
      ],
    );
  }

  TapGestureRecognizer _recognize(int page) {
    final TapGestureRecognizer recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onLink(page);
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) => Text.rich(_span);
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.link,
    required this.style,
    required this.palette,
    required this.onTap,
  });

  final ReaderLink link;
  final TextStyle style;
  final ReaderPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${link.label}. ${Messages.pageLabel(link.page)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: palette.link, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${link.label} ${link.page}',
            style: style.copyWith(color: palette.link),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.lines, required this.base, this.retry});

  final List<String> lines;
  final TextStyle base;
  final Widget? retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final String line in lines)
              Text(line, style: base, textAlign: TextAlign.center),
            if (retry != null) ...<Widget>[const SizedBox(height: 16), retry!],
          ],
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.onTap,
    required this.palette,
    required this.base,
  });

  final VoidCallback onTap;
  final ReaderPalette palette;
  final TextStyle base;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: textTvRetryKey,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: palette.link, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          Messages.readerTryAgain,
          style: base.copyWith(color: palette.link),
        ),
      ),
    );
  }
}
