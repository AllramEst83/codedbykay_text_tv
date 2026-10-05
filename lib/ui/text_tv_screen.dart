import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv_repository.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_page_area.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

/// The Text TV viewer, the app's only screen: [start]'s page under a title
/// bar, with previous/next page, a number pad, shortcuts to the pages people
/// read, tappable page links, and swipes between the parts of a page. The
/// system back button steps back through the pages read, then leaves the app.
class TextTvScreen extends StatefulWidget {
  const TextTvScreen({
    super.key,
    required this.repository,
    this.start = textTvFirstPage,
  });

  final TextTvRepository repository;
  final int start;

  @override
  State<TextTvScreen> createState() => _TextTvScreenState();
}

class _TextTvScreenState extends State<TextTvScreen> {
  late int _number = widget.start;
  int _part = 0;
  TextTvResult? _result;
  bool _loading = true;

  // The pages left behind, most recent last: what back returns to.
  final List<int> _history = <int>[];

  bool _keypad = false;
  String _typed = '';

  // Only the answer to the latest request counts; a slow one that was
  // overtaken by a newer tap must not replace it.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load(_number);
  }

  Future<void> _load(int number, {bool fresh = false}) async {
    final int request = ++_request;
    setState(() {
      _number = number;
      _part = 0;
      _loading = true;
      _keypad = false;
      _typed = '';
    });
    final TextTvResult result = await widget.repository.page(
      number,
      fresh: fresh,
    );
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      _result = result;
    });
  }

  /// Goes to [number], remembering the page it leaves so back can return.
  void _open(int number) {
    if (number < textTvFirstPage || number > textTvLastPage) return;
    if (number == _number && !_loading && _result is TextTvShown) return;
    if (number != _number) _history.add(_number);
    _load(number);
  }

  void _back() {
    if (_keypad) {
      setState(() {
        _keypad = false;
        _typed = '';
      });
    } else if (_history.isNotEmpty) {
      _load(_history.removeLast());
    }
  }

  TextTvPage? get _page {
    final TextTvResult? result = _result;
    return result is TextTvShown ? result.page : null;
  }

  int? get _previous {
    final int number = _page?.previous ?? _number - 1;
    return number >= textTvFirstPage && number <= textTvLastPage
        ? number
        : null;
  }

  int? get _next {
    final int number = _page?.next ?? _number + 1;
    return number >= textTvFirstPage && number <= textTvLastPage
        ? number
        : null;
  }

  int get _parts => _page?.parts.length ?? 1;

  void _setPart(int part) {
    if (part < 0 || part >= _parts) return;
    setState(() => _part = part);
  }

  // A swipe left reads on (the next part, or past the last, the next page); a
  // swipe right goes back a part (or, from the first, to the previous page).
  void _swiped(double velocity) {
    if (velocity.abs() < 200) return;
    if (velocity < 0) {
      if (_part < _parts - 1) {
        _setPart(_part + 1);
      } else if (_next case final int next) {
        _open(next);
      }
    } else {
      if (_part > 0) {
        _setPart(_part - 1);
      } else if (_previous case final int previous) {
        _open(previous);
      }
    }
  }

  void _digit(int digit) {
    // A page number starts with 1 to 8.
    if (_typed.isEmpty && (digit < 1 || digit > 8)) return;
    final String typed = '$_typed$digit';
    if (typed.length == 3) {
      _open(int.parse(typed));
      return;
    }
    setState(() => _typed = typed);
  }

  void _deleteDigit() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _history.isEmpty && !_keypad,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: TvColors.black,
        body: Column(
          children: <Widget>[
            TvTopBar(
              onRefresh: _loading ? null : () => _load(_number, fresh: true),
            ),
            Expanded(
              child: ColoredBox(
                color: TvColors.black,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragEnd: (DragEndDetails d) =>
                            _swiped(d.primaryVelocity ?? 0),
                        child: TvPageArea(
                          number: _number,
                          part: _part,
                          loading: _loading,
                          result: _result,
                          onLink: (String command) {
                            final int? page = int.tryParse(command);
                            if (page != null) _open(page);
                          },
                          onRetry: () => _load(_number, fresh: true),
                        ),
                      ),
                    ),
                    if (_parts > 1)
                      TvPartBar(
                        part: _part,
                        parts: _parts,
                        onPrevious: _part > 0
                            ? () => _setPart(_part - 1)
                            : null,
                        onNext: _part < _parts - 1
                            ? () => _setPart(_part + 1)
                            : null,
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(TvMetrics.gutter),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        TvButton(
                          key: textTvPrevKey,
                          label: '<',
                          onTap: _previous == null
                              ? null
                              : () => _open(_previous!),
                        ),
                        const SizedBox(width: TvMetrics.gutter),
                        Expanded(
                          child: TvNumberBox(
                            key: textTvNumberKey,
                            text: _keypad
                                ? _typed.padRight(3, '-')
                                : '$_number',
                            active: _keypad,
                            onTap: () => setState(() {
                              _keypad = !_keypad;
                              _typed = '';
                            }),
                          ),
                        ),
                        const SizedBox(width: TvMetrics.gutter),
                        TvButton(
                          key: textTvNextKey,
                          label: '>',
                          onTap: _next == null ? null : () => _open(_next!),
                        ),
                      ],
                    ),
                    const SizedBox(height: TvMetrics.gutter),
                    if (_keypad)
                      TvKeypad(
                        onDigit: _digit,
                        onDelete: _deleteDigit,
                        onClose: _back,
                      )
                    else
                      TvShortcuts(current: _number, onOpen: _open),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
