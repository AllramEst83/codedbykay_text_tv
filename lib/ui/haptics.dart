import 'dart:async';

import 'package:flutter/services.dart';

/// The app's haptic feedback, in three strengths. Android applies the phone's
/// own "touch feedback" setting, so someone who has vibration off feels nothing.
/// None of these waits or throws: a missing vibrator is not the reader's problem.
///
/// A light tick for a key or a step within a page (a digit, DEL, a part).
void tvTick() => _fire(HapticFeedback.selectionClick);

/// A firmer tap when the reader moves to another page.
void tvPress() => _fire(HapticFeedback.lightImpact);

/// The strongest, for a page number completed on the pad.
void tvConfirm() => _fire(HapticFeedback.mediumImpact);

void _fire(Future<void> Function() feedback) {
  unawaited(feedback().catchError((Object _) {}));
}
