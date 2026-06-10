import 'package:workmanager/workmanager.dart';

import 'cleanup_service.dart';
import 'cleanup_settings_service.dart';

const automaticCleanupTaskName = 'automaticCacheCleanup';

@pragma('vm:entry-point')
void cleanupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != automaticCleanupTaskName) {
      return true;
    }

    final settingsService = CleanupSettingsService();
    final settings = await settingsService.load();
    if (!settings.automaticCleanupEnabled) {
      return true;
    }

    final report = await CleanupService().clean();
    await settingsService.recordRun(deletedBytes: report.deletedBytes);
    return !report.hasErrors;
  });
}

class CleanupScheduler {
  Future<void> initialize() async {
    await Workmanager().initialize(cleanupCallbackDispatcher);
  }

  Future<void> configure(CleanupSettings settings) async {
    if (!settings.automaticCleanupEnabled) {
      await cancel();
      return;
    }

    await Workmanager().registerPeriodicTask(
      automaticCleanupTaskName,
      automaticCleanupTaskName,
      frequency: Duration(hours: settings.intervalHours),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: false,
      ),
    );
  }

  Future<void> cancel() {
    return Workmanager().cancelByUniqueName(automaticCleanupTaskName);
  }
}
