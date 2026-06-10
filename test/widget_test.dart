import 'dart:io';

import 'package:cleandroid/src/models/cleanup_report.dart';
import 'package:cleandroid/src/services/cleanup_scheduler.dart';
import 'package:cleandroid/src/services/cleanup_service.dart';
import 'package:cleandroid/src/services/cleanup_settings_service.dart';
import 'package:cleandroid/src/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra painel principal e acao de limpeza', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          cleanupService: _FakeCleanupService(),
          settingsService: _FakeSettingsService(),
          scheduler: _FakeScheduler(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('CleanDroid'), findsOneWidget);
    expect(find.text('Espaco recuperavel'), findsOneWidget);
    expect(find.text('Limpar agora'), findsOneWidget);
    expect(find.text('Limpeza automatica de cache'), findsOneWidget);
  });
}

class _FakeCleanupService implements CleanupService {
  @override
  Future<CleanupReport> analyze() async {
    return _report(deletedBytes: 0);
  }

  @override
  Future<CleanupReport> clean() async {
    return _report(deletedBytes: 128);
  }

  @override
  Future<bool> hasStorageAccess() async {
    return false;
  }

  @override
  Future<bool> requestStorageAccess() async {
    return true;
  }

  CleanupReport _report({required int deletedBytes}) {
    final now = DateTime(2026, 6, 10, 10);
    return CleanupReport(
      startedAt: now,
      finishedAt: now,
      candidates: [
        CleanupCandidate(
          area: CleanupArea.internalCache,
          path: Directory.systemTemp.path,
          bytes: 2048,
          files: 3,
          directories: 1,
          canDelete: true,
        ),
      ],
      deletedBytes: deletedBytes,
      deletedFiles: deletedBytes > 0 ? 1 : 0,
      errors: const [],
    );
  }
}

class _FakeSettingsService implements CleanupSettingsService {
  CleanupSettings _settings = const CleanupSettings(
    automaticCleanupEnabled: false,
    intervalHours: 24,
  );

  @override
  Future<CleanupSettings> load() async {
    return _settings;
  }

  @override
  Future<void> recordRun({required int deletedBytes}) async {
    _settings = _settings.copyWith(
      lastRunAt: DateTime(2026, 6, 10, 10),
      lastDeletedBytes: deletedBytes,
    );
  }

  @override
  Future<void> save(CleanupSettings settings) async {
    _settings = settings;
  }
}

class _FakeScheduler implements CleanupScheduler {
  @override
  Future<void> cancel() async {}

  @override
  Future<void> configure(CleanupSettings settings) async {}

  @override
  Future<void> initialize() async {}
}
