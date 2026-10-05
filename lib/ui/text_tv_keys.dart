import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:flutter/widgets.dart';

/// Keys so tests can find the parts.
const Key textTvOfflineKey = ValueKey<String>('text-tv-offline');
const Key textTvUpdatedKey = ValueKey<String>('text-tv-updated');
const Key textTvPrefetchKey = ValueKey<String>('text-tv-prefetch');
const Key textTvAutoRefreshKey = ValueKey<String>('text-tv-auto-refresh');
Key textTvSettingsGroupKey(String id) =>
    ValueKey<String>('text-tv-settings-group-$id');
Key textTvSettingsHeaderKey(String id) =>
    ValueKey<String>('text-tv-settings-header-$id');
const Key textTvRecentsKey = ValueKey<String>('text-tv-recents');
const Key textTvRecentsEmptyKey = ValueKey<String>('text-tv-recents-empty');
const Key textTvRecentsClearKey = ValueKey<String>('text-tv-recents-clear');
Key textTvRecentKey(int page) => ValueKey<String>('text-tv-recent-$page');
const Key textTvStarKey = ValueKey<String>('text-tv-star');
const Key textTvFavouritesResetKey = ValueKey<String>(
  'text-tv-favourites-reset',
);
const Key textTvFavouritesHintKey = ValueKey<String>('text-tv-favourites-hint');
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
const Key textTvQuickEntryKey = ValueKey<String>('text-tv-quick-entry');
Key textTvFastextKey(int index) => ValueKey<String>('text-tv-fastext-$index');
Key textTvDigitKey(int digit) => ValueKey<String>('text-tv-digit-$digit');
Key textTvChipKey(int page) => ValueKey<String>('text-tv-chip-$page');
const Key textTvSearchKey = ValueKey<String>('text-tv-search');
const Key textTvSearchFieldKey = ValueKey<String>('text-tv-search-field');
const Key textTvSearchGoKey = ValueKey<String>('text-tv-search-go');
const Key textTvSearchEmptyKey = ValueKey<String>('text-tv-search-empty');
Key textTvSearchHitKey(int page) =>
    ValueKey<String>('text-tv-search-hit-$page');
const Key textTvShareKey = ValueKey<String>('text-tv-share');
const Key textTvCopyTextKey = ValueKey<String>('text-tv-copy-text');
const Key textTvShareTextKey = ValueKey<String>('text-tv-share-text');
const Key textTvShareLinkKey = ValueKey<String>('text-tv-share-link');
