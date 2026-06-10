import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/file_scan_result.dart';
import 'cleanup_service.dart';

class FileScannerService {
  FileScannerService({
    CleanupService? cleanupService,
    Future<List<Directory>> Function()? rootsProvider,
    DateTime Function()? now,
  }) : _cleanupService = cleanupService ?? CleanupService(),
       _rootsProvider = rootsProvider,
       _now = now ?? DateTime.now;

  static const _temporaryExtensions = {'.tmp', '.temp'};

  final CleanupService _cleanupService;
  final Future<List<Directory>> Function()? _rootsProvider;
  final DateTime Function() _now;

  Future<FileScanResult> scan() async {
    final startedAt = _now();
    final roots = await _resolveRoots();
    final items = <FileScanItem>[];
    final errors = <String>[];

    for (final root in roots) {
      if (!root.existsSync()) {
        continue;
      }

      await _scanDirectory(root, items, errors);
    }

    items.sort((a, b) => b.bytes.compareTo(a.bytes));

    return FileScanResult(
      startedAt: startedAt,
      finishedAt: _now(),
      roots: roots.map((root) => root.path).toList(growable: false),
      items: items,
      errors: errors,
    );
  }

  Future<List<Directory>> _resolveRoots() async {
    if (_rootsProvider != null) {
      return _deduplicate(await _rootsProvider());
    }

    final roots = <Directory>[await getTemporaryDirectory()];
    final externalCacheDirectories = await getExternalCacheDirectories();
    roots.addAll(externalCacheDirectories ?? <Directory>[]);

    if (Platform.isAndroid && await _cleanupService.hasStorageAccess()) {
      roots.add(Directory('/storage/emulated/0/Download'));
    }

    return _deduplicate(roots);
  }

  List<Directory> _deduplicate(List<Directory> directories) {
    final seen = <String>{};
    final unique = <Directory>[];

    for (final directory in directories) {
      final path = directory.absolute.path;
      if (seen.add(path)) {
        unique.add(directory);
      }
    }

    return unique;
  }

  Future<void> _scanDirectory(
    Directory directory,
    List<FileScanItem> items,
    List<String> errors,
  ) async {
    Stream<FileSystemEntity> children;
    try {
      children = directory.list(followLinks: false);
    } on FileSystemException catch (error) {
      errors.add('${directory.path}: ${error.message}');
      return;
    }

    try {
      await for (final entity in children) {
        if (entity is Directory) {
          await _scanDirectory(entity, items, errors);
          continue;
        }

        if (entity is! File) {
          continue;
        }

        try {
          final stat = await entity.stat();
          final reasons = _reasonsFor(entity, stat);
          if (reasons.isEmpty) {
            continue;
          }

          items.add(
            FileScanItem(
              path: entity.path,
              bytes: stat.size,
              modifiedAt: stat.modified,
              reasons: reasons,
            ),
          );
        } on FileSystemException catch (error) {
          errors.add('${entity.path}: ${error.message}');
        }
      }
    } on FileSystemException catch (error) {
      errors.add('${directory.path}: ${error.message}');
    }
  }

  Set<FileScanReason> _reasonsFor(File file, FileStat stat) {
    final reasons = <FileScanReason>{};
    final lowerPath = file.path.toLowerCase();

    if (_temporaryExtensions.any(lowerPath.endsWith)) {
      reasons.add(FileScanReason.temporaryExtension);
    }

    if (lowerPath.endsWith('.log')) {
      reasons.add(FileScanReason.logExtension);
    }

    if (stat.size == 0) {
      reasons.add(FileScanReason.emptyFile);
    }

    return reasons;
  }
}
