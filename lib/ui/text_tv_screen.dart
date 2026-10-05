import 'dart:async';

import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/saved_time.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/services/text_tv_repository.dart';
import 'package:codedbykay_text_tv/ui/crt_screen.dart';
import 'package:codedbykay_text_tv/ui/reader_bar.dart';
import 'package:codedbykay_text_tv/ui/reader_view.dart';
import 'package:codedbykay_text_tv/ui/settings_screen.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_page_area.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

/// The Text TV viewer, the app's only screen: the page in [initial] under a
/// title bar, with previous/next page, a number pad, shortcuts to the pages people
/// read, tappable page links, and swipes between the parts of a page. The
/// system back button steps back through the pages read, then leaves the app.
/// [onSessionChanged] hears where the reader is after every move, so a later
/// run can start there.
DateTime _systemNow() => DateTime.now();

class TextTvScreen extends StatefulWidget {
  const TextTvScreen({
    super.key,
    required this.repository,
    this.initial = const TextTvSession(),
    this.onSessionChanged,
    this.reader = const ReaderSettings(),
    this.onReaderChanged,
    this.crt = CrtSettings.defaults,
    this.onCrtChanged,
    this.clock = _systemNow,
  });

  final TextTvRepository repository;
  final TextTvSession initial;
  final ValueChanged<TextTvSession>? onSessionChanged;

  /// Whether the page shows as reader text and how the reader looks, as of the
  /// last run; [onReaderChanged] hears every change to it.
  final ReaderSettings reader;
  final ValueChanged<ReaderSettings>? onReaderChanged;

  /// The CRT look of the teletext page (not of the reader's text), and the
  /// listener that hears when the settings page changes it.
  final CrtSettings crt;
  final ValueChanged<CrtSettings>? onCrtChanged;

  /// Today's date, for saying when a saved copy is from.
  final DateTime Function() clock;

  @override
  State<TextTvScreen> createState() => _TextTvScreenState();
}

class _TextTvScreenState extends State<TextTvScreen> {
  late int _number = widget.initial.page;
  late int _part = widget.initial.part;
  late ReaderSettings _reader = widget.reader;
  late CrtSettings _crtSettings = widget.crt;
  TextTvResult? _result;
  bool _loading = true;

  // The pages left behind, most recent last: what back returns to.
  late final List<int> _history = List<int>.of(widget.initial.history);

  bool _keypad = false;
  String _typed = '';

  // Only the answer to the latest request counts; a slow one that was
  // overtaken by a newer tap must not replace it.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load(_number, part: _part);
  }

  Widget _crt(Widget page) => _crtSettings.enabled
      ? CrtScreen(settings: _crtSettings, child: page)
      : page;

  void _setCrt(CrtSettings crt) {
    setState(() => _crtSettings = crt);
    widget.onCrtChanged?.call(crt);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            SettingsScreen(crt: _crtSettings, onChanged: _setCrt),
      ),
    );
  }

  void _setReader(ReaderSettings reader) {
    setState(() => _reader = reader);
    widget.onReaderChanged?.call(reader);
  }

  /// Tells the listener where the reader is now.
  void _report() => widget.onSessionChanged?.call(
    TextTvSession(page: _number, part: _part, history: List<int>.of(_history)),
  );

  Future<void> _load(int number, {bool fresh = false, int part = 0}) async {
    final int request = ++_request;
    setState(() {
      _number = number;
      _part = part;
      _loading = true;
      _keypad = false;
      _typed = '';
    });
    _report();
    final Future<TextTvResult> reading = widget.repository.page(
      number,
      fresh: fresh,
    );
    if (!fresh) {
      // Show the copy already held (saved on disk, say) while the current page
      // is read, unless the current one is already here.
      bool read = false;
      unawaited(reading.whenComplete(() => read = true));
      final TextTvShown? held = await widget.repository.cached(number);
      if (!mounted || request != _request) return;
      if (held != null && !read) {
        setState(() {
          _loading = false;
          _result = held;
          _part = _part.clamp(0, held.page.parts.length - 1);
        });
      }
    }
    final TextTvResult result = await reading;
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      _result = result;
      // A part remembered from an earlier run may no longer exist.
      _part = result is TextTvShown
          ? _part.clamp(0, result.page.parts.length - 1)
          : 0;
    });
    _report();
  }

  /// Goes to [number], remembering the page it leaves so back can return.
  void _open(int number) {
    if (number < textTvFirstPage || number > textTvLastPage) return;
    if (number == _number && !_loading && _result is TextTvShown) return;
    if (number != _number) {
      if (_history.length >= TextTvSession.maxHistory) _history.removeAt(0);
      _history.add(_number);
    }
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

  /// When the page on screen was saved, if it is an old copy shown because the
  /// site could not be reached.
  DateTime? get _savedAt {
    final TextTvResult? result = _result;
    return !_loading && result is TextTvShown ? result.cachedAt : null;
  }

  int get _parts => _page?.parts.length ?? 1;

  void _setPart(int part) {
    if (part < 0 || part >= _parts) return;
    setState(() => _part = part);
    _report();
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
              readerOn: _reader.enabled,
              onReader: () =>
                  _setReader(_reader.copyWith(enabled: !_reader.enabled)),
              onSettings: _openSettings,
            ),
            if (_reader.enabled)
              ReaderBar(settings: _reader, onChanged: _setReader),
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
                        child: _reader.enabled
                            ? ReaderView(
                                number: _number,
                                part: _part,
                                loading: _loading,
                                result: _result,
                                settings: _reader,
                                onLink: _open,
                                onRetry: () => _load(_number, fresh: true),
                              )
                            : _crt(
                                TvPageArea(
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
                    ),
                    if (_savedAt case final DateTime savedAt)
                      TvOfflineNote(
                        text: Messages.offlineSaved(
                          formatSavedAt(savedAt, widget.clock()),
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
