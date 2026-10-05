import 'package:workmanager/workmanager.dart';

/// Names of the one periodic job the app runs in the background.
const String backgroundUniqueName = 'texttv-background-refresh';
const String backgroundTaskName = 'refresh';

/// The phone's background scheduler, as little as it can be:
/// [WorkmanagerScheduler] is the real one; tests use a fake. Nothing here
/// throws: a phone that will not schedule work just never refreshes.
abstract interface class BackgroundScheduler {
  /// Runs the background job about every [every] (never sooner than the
  /// system allows), replacing a schedule there was.
  Future<void> schedule(Duration every);

  /// Stops the background job.
  Future<void> cancel();
}

/// [BackgroundScheduler] on the `workmanager` plugin (Android WorkManager).
/// The job needs a connection and does not wait for charging.
class WorkmanagerScheduler implements BackgroundScheduler {
  const WorkmanagerScheduler();

  @override
  Future<void> schedule(Duration every) async {
    try {
      await Workmanager().registerPeriodicTask(
        backgroundUniqueName,
        backgroundTaskName,
        frequency: every,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } on Object {
      // No background work on this phone.
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await Workmanager().cancelByUniqueName(backgroundUniqueName);
    } on Object {
      // Nothing to stop.
    }
  }
}
