import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:flutter/widgets.dart';

/// Keys so tests can find the parts.
const Key textTvOfflineKey = ValueKey<String>('text-tv-offline');
const Key textTvReaderKey = ValueKey<String>('text-tv-reader');
const Key textTvReaderViewKey = ValueKey<String>('text-tv-reader-view');
const Key textTvReaderSmallerKey = ValueKey<String>('text-tv-reader-smaller');
const Key textTvReaderLargerKey = ValueKey<String>('text-tv-reader-larger');
Key textTvReaderThemeKey(ReaderTheme theme) =>
    ValueKey<String>('text-tv-reader-theme-${theme.name}');
const Key textTvRefreshKey = ValueKey<String>('text-tv-refresh');
const Key textTvNumberKey = ValueKey<String>('text-tv-number');
const Key textTvPrevKey = ValueKey<String>('text-tv-prev');
const Key textTvNextKey = ValueKey<String>('text-tv-next');
const Key textTvPartPrevKey = ValueKey<String>('text-tv-part-prev');
const Key textTvPartNextKey = ValueKey<String>('text-tv-part-next');
const Key textTvRetryKey = ValueKey<String>('text-tv-retry');
const Key textTvDeleteKey = ValueKey<String>('text-tv-delete');
const Key textTvKeypadCloseKey = ValueKey<String>('text-tv-keypad-close');
Key textTvDigitKey(int digit) => ValueKey<String>('text-tv-digit-$digit');
Key textTvChipKey(int page) => ValueKey<String>('text-tv-chip-$page');
