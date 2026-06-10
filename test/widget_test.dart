import 'dart:io';

import 'package:cleandroid/src/models/cleanup_report.dart';
import 'package:cleandroid/src/models/app_permission_status.dart';
import 'package:cleandroid/src/models/file_scan_result.dart';
import 'package:cleandroid/src/services/app_permission_service.dart';
import 'package:cleandroid/src/services/cleanup_scheduler.dart';
import 'package:cleandroid/src/services/cleanup_service.dart';
import 'package:cleandroid/src/services/cleanup_settings_service.dart';
import 'package:cleandroid/src/services/file_scanner_service.dart';
import 'package:cleandroid/src/ui/home_page.dart';
import 'package:cleandroid/src/ui/permissions_page.dart';
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
          fileScannerService: _FakeFileScannerService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('CleanDroid'), findsOneWidget);
    expect(find.text('Arquivos encontrados'), findsOneWidget);
    expect(find.text('Scanner de arquivos'), findsOneWidget);
    expect(find.text('Limpar agora'), findsOneWidget);
    expect(find.text('Limpeza automatica de cache'), findsOneWidget);
  });

  test('scanner localiza arquivos tmp, log e vazios reais', () async {
    final root = await Directory.systemTemp.createTemp('cleandroid_scan_test');
    addTearDown(() => root.delete(recursive: true));

    await File(
      '${root.path}${Platform.pathSeparator}cache.tmp',
    ).writeAsString('abc');
    await File(
      '${root.path}${Platform.pathSeparator}system.log',
    ).writeAsString('log');
    await File('${root.path}${Platform.pathSeparator}empty.txt').create();
    await File(
      '${root.path}${Platform.pathSeparator}photo.jpg',
    ).writeAsString('image');

    final result = await FileScannerService(
      rootsProvider: () async => [root],
      now: () => DateTime(2026, 6, 10),
    ).scan();

    expect(result.totalFiles, 3);
    expect(result.temporaryFiles, 1);
    expect(result.logFiles, 1);
    expect(result.emptyFiles, 1);
    expect(result.items.map((item) => item.name), isNot(contains('photo.jpg')));
    expect(result.totalBytes, 6);
  });

  testWidgets('tela de permissoes mostra status especiais', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionsPage(permissionService: _FakeAppPermissionService()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Permissoes necessarias'), findsOneWidget);
    expect(find.text('Acesso a todos os arquivos'), findsOneWidget);
    expect(find.text('Acesso ao uso'), findsOneWidget);
    expect(find.text('Consultar aplicativos instalados'), findsOneWidget);
    expect(find.text('Permitida'), findsNWidgets(2));
    expect(find.text('Nao permitida'), findsOneWidget);
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

class _FakeFileScannerService extends FileScannerService {
  @override
  Future<FileScanResult> scan() async {
    final now = DateTime(2026, 6, 10, 10);
    return FileScanResult(
      startedAt: now,
      finishedAt: now,
      roots: [Directory.systemTemp.path],
      items: [
        FileScanItem(
          path:
              '${Directory.systemTemp.path}${Platform.pathSeparator}cache.tmp',
          bytes: 1024,
          modifiedAt: now,
          reasons: const {FileScanReason.temporaryExtension},
        ),
      ],
      errors: const [],
    );
  }
}

class _FakeAppPermissionService extends AppPermissionService {
  @override
  Future<AppPermissionStatus> loadStatus() async {
    return const AppPermissionStatus(
      allFilesAccess: false,
      usageAccess: true,
      queryAllPackagesDeclared: true,
    );
  }

  @override
  Future<void> openAllFilesAccessSettings() async {}

  @override
  Future<void> openUsageAccessSettings() async {}

  @override
  Future<void> openAppDetailsSettings() async {}
}
