import 'dart:async';

import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/model/fastext.dart';
import 'package:codedbykay_text_tv/model/prefetch.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/refresh_settings.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/saved_time.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/services/shortcut_service.dart';
import 'package:codedbykay_text_tv/services/text_tv_repository.dart';
import 'package:codedbykay_text_tv/ui/crt_screen.dart';
import 'package:codedbykay_text_tv/ui/page_turn.dart';
import 'package:codedbykay_text_tv/ui/reader_bar.dart';
import 'package:codedbykay_text_tv/ui/reader_view.dart';
import 'package:codedbykay_text_tv/ui/recent_pages_sheet.dart';
import 'package:codedbykay_text_tv/ui/search_sheet.dart';
import 'package:codedbykay_text_tv/ui/settings_screen.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_page_area.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

DateTime _systemNow() => DateTime.now();

/// The Text TV viewer, the app's only screen: the page in [initial] under a
/// title bar, with previous/next page, a number pad, shortcuts to the pages people
/// read, tappable page links, and swipes between the parts of a page. The
/// system back button steps back through the pages read, then leaves the app.
/// [onSessionChanged] hears where the reader is after every move, so a later
/// run can start there.
///
/// The page on show can be read again quietly (the old one stays until the new
/// one is here): by pulling it down, when the app comes back after a while,
/// and, if the settings say so, every so often.
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
    this.refresh = const RefreshSettings(),
    this.onRefreshChanged,
    this.controls = ControlsSettings.defaults,
    this.onControlsChanged,
    this.saved = const SavedPages(),
    this.onSavedChanged,
    this.shortcuts,
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

  /// Whether the page refreshes by itself, and the listener for the settings
  /// page changing it.
  final RefreshSettings refresh;
  final ValueChanged<RefreshSettings>? onRefreshChanged;

  /// How the controls under the page work (the always-on pad and colour keys,
  /// or the tap-the-number pad), and the listener for the settings page
  /// changing it.
  final ControlsSettings controls;
  final ValueChanged<ControlsSettings>? onControlsChanged;

  /// The reader's favourite pages, and the listener that hears when they
  /// change (starring a page, or resetting them in the settings page).
  final SavedPages saved;
  final ValueChanged<SavedPages>? onSavedChanged;

  /// The app icon's long-press shortcuts: kept in step with the first
  /// favourites, and a page chosen from one is opened here.
  final ShortcutService? shortcuts;

  /// Today's date, for saying when a saved copy is from.
  final DateTime Function() clock;

  @override
  State<TextTvScreen> createState() => _TextTvScreenState();
}

class _TextTvScreenState extends State<TextTvScreen>
    with WidgetsBindingObserver {
  late int _number = widget.initial.page;
  late int _part = widget.initial.part;
  late ReaderSettings _reader = widget.reader;
  late CrtSettings _crtSettings = widget.crt;
  late RefreshSettings _refresh = widget.refresh;
  late ControlsSettings _controls = widget.controls;
  late SavedPages _saved = widget.saved;
  TextTvResult? _result;
  bool _loading = true;

  // The pages left behind, most recent last: what back returns to.
  late final List<int> _history = List<int>.of(widget.initial.history);

  // The digits typed towards a page number, and the timer that forgets them
  // if the third never comes (a real set does the same).
  String _typed = '';
  Timer? _typedTimer;

  // The classic number pad, open or not (only with the quick pad off).
  bool _keypad = false;
  static const Duration _typedTimeout = Duration(seconds: 4);

  // Only the answer to the latest request counts; a slow one that was
  // overtaken by a newer tap must not replace it.
  int _request = 0;

  // Quiet refreshes: one at a time, on a timer if the settings ask for it.
  bool _refreshing = false;
  Timer? _autoTimer;
  StreamSubscription<int>? _shortcutSubscription;

  // Pages read ahead of being asked for: a short queue, worked through one page
  // at a time with a pause between, and dropped the moment the reader moves.
  final List<int> _readAhead = <int>[];
  Timer? _readAheadTimer;
  static const Duration _readAheadWait = Duration(milliseconds: 700);
  static const Duration _readAheadGap = Duration(milliseconds: 400);

  // Which way the last page turn went: 1 to a later page, -1 to an earlier one.
  int _turn = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load(_number, part: _part);
    _startAuto();
    final ShortcutService? shortcuts = widget.shortcuts;
    if (shortcuts != null) {
      _shortcutSubscription = shortcuts.opened.listen(_open);
      unawaited(shortcuts.update(_saved.favourites));
    }
  }

  /// Sets up reading ahead for the page just read, when the settings say so.
  /// Only a page read from the site counts: an old saved copy shown because
  /// the site could not be reached says the site is not answering.
  void _scheduleReadAhead(TextTvShown shown) {
    _stopReadAhead();
    if (!_refresh.prefetch || shown.cachedAt != null) return;
    _readAhead.addAll(prefetchTargets(shown.page, _part));
    if (_readAhead.isNotEmpty) {
      _readAheadTimer = Timer(_readAheadWait, _readNextAhead);
    }
  }

  void _stopReadAhead() {
    _readAheadTimer?.cancel();
    _readAhead.clear();
  }

  Future<void> _readNextAhead() async {
    if (!mounted || _readAhead.isEmpty) return;
    final int number = _readAhead.removeAt(0);
    await widget.repository.prefetch(number);
    if (mounted && _readAhead.isNotEmpty) {
      _readAheadTimer = Timer(_readAheadGap, _readNextAhead);
    }
  }

  /// Whether the page on show may be read again without being asked: it is
  /// there, nothing else is being read, and this screen is the one in front
  /// (not the settings page over it).
  bool get _canRefreshQuietly =>
      mounted &&
      !_loading &&
      !_refreshing &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  void _startAuto() {
    _autoTimer?.cancel();
    final Duration? every = _refresh.interval;
    if (every == null) return;
    _autoTimer = Timer.periodic(every, (Timer _) {
      if (_canRefreshQuietly) unawaited(_refreshQuietly());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      // Nothing is read while the app is out of sight.
      _autoTimer?.cancel();
      _stopReadAhead();
      return;
    }
    _startAuto();
    final DateTime? at = _readAt;
    if (_canRefreshQuietly &&
        at != null &&
        widget.clock().difference(at) >= refreshAfterResume) {
      unawaited(_refreshQuietly());
    }
  }

  /// Reads page [_number] again from the site, for a refresh nobody is
  /// waiting at the screen for. Null when the answer is no longer wanted: the
  /// reader has moved on, or the screen is gone.
  Future<TextTvResult?> _fetchQuietly() async {
    final int request = _request;
    _refreshing = true;
    final TextTvResult result = await widget.repository.page(
      _number,
      fresh: true,
    );
    _refreshing = false;
    return mounted && request == _request ? result : null;
  }

  /// Only a page just read from the site replaces the one on show: an old
  /// saved copy or a failure must not take a good page's place.
  Future<void> _refreshQuietly() async {
    final TextTvResult? result = await _fetchQuietly();
    if (result is TextTvShown && result.cachedAt == null) _show(result);
  }

  /// A pull is asked for, so its answer is shown, with one exception: a
  /// failure does not wipe the page on show, it says why in a message.
  Future<void> _pullRefresh() async {
    final TextTvResult? result = await _fetchQuietly();
    if (result == null || !mounted) return;
    if (result is TextTvFailed && _result is TextTvShown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Messages.failure(result.failure).toUpperCase(),
            style: tvText(10, TvColors.white),
          ),
          backgroundColor: TvColors.black,
          shape: const Border.fromBorderSide(
            BorderSide(color: TvColors.border, width: TvMetrics.border),
          ),
        ),
      );
      return;
    }
    _show(result);
  }

  void _show(TextTvResult result, {bool readAhead = false}) {
    if (readAhead && result is TextTvShown) {
      _scheduleReadAhead(result);
      // A page read (not a failure, not one that is not in broadcast) is one
      // worth coming back to.
      _setSaved(_saved.visited(_number));
    }
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

  void _setRefresh(RefreshSettings refresh) {
    setState(() => _refresh = refresh);
    _startAuto();
    if (!refresh.prefetch) _stopReadAhead();
    widget.onRefreshChanged?.call(refresh);
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
        builder: (BuildContext context) => SettingsScreen(
          controls: _controls,
          onControlsChanged: _setControls,
          saved: _saved,
          onSavedChanged: _setSaved,
          crt: _crtSettings,
          onChanged: _setCrt,
          refresh: _refresh,
          onRefreshChanged: _setRefresh,
        ),
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
    _stopReadAhead();
    _turn = number == _number ? 0 : (number > _number ? 1 : -1);
    setState(() {
      _number = number;
      _part = part;
      _loading = true;
      _typed = '';
      _keypad = false;
    });
    _typedTimer?.cancel();
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
    _show(result, readAhead: true);
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
    } else if (_typed.isNotEmpty) {
      _clearTyped();
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

  /// When the page on show was read from the site, if it is known.
  DateTime? get _readAt {
    final TextTvResult? result = _result;
    return result is TextTvShown ? result.readAt : null;
  }

  /// [_readAt] for a page that is up to date as far as the app knows: not an
  /// old saved copy shown because the site could not be reached.
  DateTime? get _updatedAt {
    final TextTvResult? result = _result;
    return !_loading && result is TextTvShown && result.cachedAt == null
        ? result.readAt
        : null;
  }

  /// The coloured keys of the page on screen; none while it is loading.
  List<FastextLink> get _fastext {
    final TextTvPage? page = _page;
    return page == null || _loading || !_controls.quickEntry
        ? const <FastextLink>[]
        : fastextLinks(page, _part);
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
    // The quick pad forgets a half-typed number; the classic one has a DEL key
    // and an X, and keeps it until they are used.
    if (_controls.quickEntry) {
      _typedTimer?.cancel();
      _typedTimer = Timer(_typedTimeout, _clearTyped);
    }
    setState(() => _typed = typed);
  }

  void _deleteDigit() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  /// What the number box says: the page, or the digits typed so far.
  String get _numberText {
    final bool typing = _controls.quickEntry ? _typed.isNotEmpty : _keypad;
    return typing ? _typed.padRight(3, '-') : '$_number';
  }

  bool get _numberActive => _controls.quickEntry ? _typed.isNotEmpty : _keypad;

  /// A tap on the number box: clears what was typed on the quick pad, and
  /// opens or puts away the classic one.
  void _numberTapped() {
    if (_controls.quickEntry) {
      _clearTyped();
      return;
    }
    setState(() {
      _keypad = !_keypad;
      _typed = '';
    });
  }

  static bool _sameFavourites(List<Favourite> a, List<Favourite> b) =>
      a.length == b.length &&
      Iterable<int>.generate(a.length).every((int i) => a[i] == b[i]);

  void _openSearch() {
    showSearchSheet(context, search: widget.repository.search, onOpen: _open);
  }

  void _openRecents() {
    showRecentPages(
      context,
      // Not the page on show: it is not somewhere to go back to.
      recents: <int>[
        for (final int page in _saved.recents)
          if (page != _number) page,
      ],
      favourites: _saved.favourites,
      onOpen: _open,
      onClear: () => _setSaved(_saved.clearRecents()),
    );
  }

  void _setSaved(SavedPages saved) {
    if (saved == _saved) return;
    final bool favouritesChanged = !_sameFavourites(
      saved.favourites,
      _saved.favourites,
    );
    setState(() => _saved = saved);
    // Only the favourites are shortcuts: a page read is no reason to tell
    // the system again.
    if (favouritesChanged) {
      unawaited(widget.shortcuts?.update(saved.favourites));
    }
    widget.onSavedChanged?.call(saved);
  }

  void _setControls(ControlsSettings controls) {
    if (controls == _controls) return;
    _typedTimer?.cancel();
    setState(() {
      _controls = controls;
      _keypad = false;
      _typed = '';
    });
    widget.onControlsChanged?.call(controls);
  }

  void _clearTyped() {
    _typedTimer?.cancel();
    if (_typed.isNotEmpty) setState(() => _typed = '');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_shortcutSubscription?.cancel());
    _autoTimer?.cancel();
    _readAheadTimer?.cancel();
    _typedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _history.isEmpty && _typed.isEmpty && !_keypad,
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
              onSearch: _openSearch,
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
                        // A new page comes in with a short slide from the side it
                        // was turned to (a new key for each page number).
                        child: PageTurn(
                          key: ValueKey<int>(_number),
                          direction: _turn,
                          child: _reader.enabled
                              ? ReaderView(
                                  number: _number,
                                  part: _part,
                                  loading: _loading,
                                  result: _result,
                                  settings: _reader,
                                  onLink: _open,
                                  onRetry: () => _load(_number, fresh: true),
                                  onPull: _pullRefresh,
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
                                    onPull: _pullRefresh,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (_savedAt case final DateTime savedAt)
                      TvOfflineNote(
                        text: Messages.offlineSaved(
                          formatSavedAt(savedAt, widget.clock()),
                        ),
                      )
                    else if (_updatedAt case final DateTime updatedAt)
                      TvUpdatedNote(
                        text: Messages.updated(
                          formatSavedAt(updatedAt, widget.clock()),
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
                        TvIconButton(
                          key: textTvStarKey,
                          icon: (Color colour) => Icon(
                            _saved.isFavourite(_number)
                                ? Icons.star
                                : Icons.star_border,
                            color: colour,
                            size: 26,
                          ),
                          selected: _saved.isFavourite(_number),
                          semanticLabel: _saved.isFavourite(_number)
                              ? Messages.removeFavourite
                              : Messages.addFavourite,
                          onTap: () =>
                              _setSaved(_saved.toggleFavourite(_number)),
                        ),
                        const SizedBox(width: TvMetrics.gutter),
                        Expanded(
                          child: TvNumberBox(
                            key: textTvNumberKey,
                            text: _numberText,
                            active: _numberActive,
                            onTap: _numberTapped,
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
                    if (_controls.quickEntry) ...<Widget>[
                      if (_fastext.isNotEmpty) ...<Widget>[
                        TvFastext(links: _fastext, onOpen: _open),
                        const SizedBox(height: TvMetrics.gutter),
                      ],
                      TvDigitPad(typed: _typed, onDigit: _digit),
                      const SizedBox(height: TvMetrics.gutter),
                      TvShortcuts(
                        favourites: _saved.favourites,
                        current: _number,
                        onOpen: _open,
                        onRecents: _openRecents,
                      ),
                    ] else if (_keypad)
                      TvKeypad(
                        onDigit: _digit,
                        onDelete: _deleteDigit,
                        onClose: _back,
                      )
                    else
                      TvShortcuts(
                        favourites: _saved.favourites,
                        current: _number,
                        onOpen: _open,
                        onRecents: _openRecents,
                      ),
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
