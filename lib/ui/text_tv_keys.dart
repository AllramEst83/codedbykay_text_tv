import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:flutter/widgets.dart';

/// Keys so tests can find the parts.
const Key textTvOfflineKey = ValueKey<String>('text-tv-offline');
const Key textTvSettingsKey = ValueKey<String>('text-tv-settings');
const Key textTvSettingsBackKey = ValueKey<String>('text-tv-settings-back');
const Key textTvCrtSwitchKey = ValueKey<String>('text-tv-crt-switch');
const Key textTvCrtCurveKey = ValueKey<String>('text-tv-crt-curve');
const Key textTvCrtDepthKey = ValueKey<String>('text-tv-crt-depth');
const Key textTvCrtPeriodKey = ValueKey<String>('text-tv-crt-period');
const Key textTvCrtResetKey = ValueKey<String>('text-tv-crt-reset');
const Key textTvCrtPreviewKey = ValueKey<String>('text-tv-crt-preview');
const Key textTvReaderKey = ValueKey<String>('text-tv-reader');
const Key textTvReaderViewKey = ValueKey<String>('text-tv-reader-view');
const Key textTvReaderOptionsKey = ValueKey<String>('text-tv-reader-options');
const Key textTvReaderLineKey = ValueKey<String>('text-tv-reader-line');
const Key textTvReaderLetterKey = ValueKey<String>('text-tv-reader-letter');
const Key textTvReaderMarginKey = ValueKey<String>('text-tv-reader-margin');
const Key textTvReaderBoldKey = ValueKey<String>('text-tv-reader-bold');
const Key textTvReaderResetKey = ValueKey<String>('text-tv-reader-reset');
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
