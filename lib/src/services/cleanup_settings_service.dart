import 'package:shared_preferences/shared_preferences.dart';

class CleanupSettings {
  const CleanupSettings({
    required this.automaticCleanupEnabled,
    required this.intervalHours,
    this.lastRunAt,
    this.lastDeletedBytes = 0,
  });

  final bool automaticCleanupEnabled;
  final int intervalHours;
  final DateTime? lastRunAt;
  final int lastDeletedBytes;

  CleanupSettings copyWith({
    bool? automaticCleanupEnabled,
    int? intervalHours,
    DateTime? lastRunAt,
    int? lastDeletedBytes,
  }) {
    return CleanupSettings(
      automaticCleanupEnabled:
          automaticCleanupEnabled ?? this.automaticCleanupEnabled,
      intervalHours: intervalHours ?? this.intervalHours,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      lastDeletedBytes: lastDeletedBytes ?? this.lastDeletedBytes,
    );
  }
}

class CleanupSettingsService {
  static const _automaticCleanupEnabledKey = 'automaticCleanupEnabled';
  static const _intervalHoursKey = 'intervalHours';
  static const _lastRunAtKey = 'lastRunAt';
  static const _lastDeletedBytesKey = 'lastDeletedBytes';

  Future<CleanupSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final lastRunValue = preferences.getString(_lastRunAtKey);

    return CleanupSettings(
      automaticCleanupEnabled:
          preferences.getBool(_automaticCleanupEnabledKey) ?? false,
      intervalHours: preferences.getInt(_intervalHoursKey) ?? 24,
      lastRunAt: lastRunValue == null ? null : DateTime.tryParse(lastRunValue),
      lastDeletedBytes: preferences.getInt(_lastDeletedBytesKey) ?? 0,
    );
  }

  Future<void> save(CleanupSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      _automaticCleanupEnabledKey,
      settings.automaticCleanupEnabled,
    );
    await preferences.setInt(_intervalHoursKey, settings.intervalHours);
    await preferences.setInt(_lastDeletedBytesKey, settings.lastDeletedBytes);

    if (settings.lastRunAt == null) {
      await preferences.remove(_lastRunAtKey);
    } else {
      await preferences.setString(
        _lastRunAtKey,
        settings.lastRunAt!.toIso8601String(),
      );
    }
  }

  Future<void> recordRun({required int deletedBytes}) async {
    final current = await load();
    await save(
      current.copyWith(
        lastRunAt: DateTime.now(),
        lastDeletedBytes: deletedBytes,
      ),
    );
  }
}
