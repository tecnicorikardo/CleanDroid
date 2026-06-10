import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/cleanup_report.dart';

class CleanupService {
  CleanupService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const _temporaryExtensions = {
    '.tmp',
    '.temp',
    '.log',
    '.bak',
    '.old',
    '.crdownload',
  };

  final DateTime Function() _now;

  Future<bool> hasStorageAccess() async {
    if (!Platform.isAndroid) {
      return true;
    }

    return Permission.manageExternalStorage.isGranted;
  }

  Future<bool> requestStorageAccess() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<CleanupReport> analyze() async {
    final startedAt = _now();
    final errors = <String>[];
    final candidates = <CleanupCandidate>[];

    for (final target in await _targets()) {
      try {
        if (!target.directory.existsSync()) {
          continue;
        }

        final stats = await _collectStats(target);
        candidates.add(
          CleanupCandidate(
            area: target.area,
            path: target.directory.path,
            bytes: stats.bytes,
            files: stats.files,
            directories: stats.directories,
            canDelete: stats.files > 0 || stats.directories > 0,
          ),
        );
      } on FileSystemException catch (error) {
        candidates.add(
          CleanupCandidate(
            area: target.area,
            path: target.directory.path,
            bytes: 0,
            files: 0,
            directories: 0,
            canDelete: false,
            reason: error.message,
          ),
        );
        errors.add('${target.directory.path}: ${error.message}');
      }
    }

    return CleanupReport(
      startedAt: startedAt,
      finishedAt: _now(),
      candidates: candidates,
      deletedBytes: 0,
      deletedFiles: 0,
      errors: errors,
    );
  }

  Future<CleanupReport> clean() async {
    final startedAt = _now();
    final errors = <String>[];
    final candidates = <CleanupCandidate>[];
    var deletedBytes = 0;
    var deletedFiles = 0;

    for (final target in await _targets()) {
      try {
        if (!target.directory.existsSync()) {
          continue;
        }

        final before = await _collectStats(target);
        final result = await _deleteTarget(target);
        final after = await _collectStats(target);

        deletedBytes += result.bytes;
        deletedFiles += result.files;
        errors.addAll(result.errors);
        candidates.add(
          CleanupCandidate(
            area: target.area,
            path: target.directory.path,
            bytes: after.bytes,
            files: after.files,
            directories: after.directories,
            canDelete: after.files > 0 || after.directories > 0,
            reason: before.files == 0 ? 'Nada para limpar' : null,
          ),
        );
      } on FileSystemException catch (error) {
        errors.add('${target.directory.path}: ${error.message}');
      }
    }

    return CleanupReport(
      startedAt: startedAt,
      finishedAt: _now(),
      candidates: candidates,
      deletedBytes: deletedBytes,
      deletedFiles: deletedFiles,
      errors: errors,
    );
  }

  Future<List<CleanupTarget>> _targets() async {
    final targets = <CleanupTarget>[];
    targets.add(
      CleanupTarget(
        area: CleanupArea.internalCache,
        directory: await getTemporaryDirectory(),
        mode: CleanupMode.deleteChildren,
      ),
    );

    final externalCacheDirectories = await getExternalCacheDirectories();
    for (final directory in externalCacheDirectories ?? <Directory>[]) {
      targets.add(
        CleanupTarget(
          area: CleanupArea.externalCache,
          directory: directory,
          mode: CleanupMode.deleteChildren,
        ),
      );
    }

    if (Platform.isAndroid && await hasStorageAccess()) {
      targets.add(
        CleanupTarget(
          area: CleanupArea.temporaryDownloads,
          directory: Directory('/storage/emulated/0/Download'),
          mode: CleanupMode.deleteTemporaryFiles,
        ),
      );
    }

    return targets;
  }

  Future<DirectoryStats> _collectStats(CleanupTarget target) async {
    var bytes = 0;
    var files = 0;
    var directories = 0;

    await for (final entity in _safeList(target.directory)) {
      if (entity is File && _isEligibleFile(entity, target.mode)) {
        final stat = await entity.stat();
        bytes += stat.size;
        files += 1;
      } else if (entity is Directory) {
        final childTarget = CleanupTarget(
          area: target.area,
          directory: entity,
          mode: target.mode,
        );
        final childStats = await _collectStats(childTarget);
        bytes += childStats.bytes;
        files += childStats.files;
        directories += childStats.directories;

        if (target.mode == CleanupMode.deleteChildren ||
            await _isEmpty(entity)) {
          directories += 1;
        }
      }
    }

    return DirectoryStats(bytes: bytes, files: files, directories: directories);
  }

  Future<DeleteResult> _deleteTarget(CleanupTarget target) async {
    final errors = <String>[];
    var bytes = 0;
    var files = 0;

    await for (final entity in _safeList(target.directory)) {
      if (entity is File && _isEligibleFile(entity, target.mode)) {
        try {
          final stat = await entity.stat();
          await entity.delete();
          bytes += stat.size;
          files += 1;
        } on FileSystemException catch (error) {
          errors.add('${entity.path}: ${error.message}');
        }
      } else if (entity is Directory) {
        final childResult = await _deleteTarget(
          CleanupTarget(
            area: target.area,
            directory: entity,
            mode: target.mode,
          ),
        );
        bytes += childResult.bytes;
        files += childResult.files;
        errors.addAll(childResult.errors);

        if (target.mode == CleanupMode.deleteChildren ||
            await _isEmpty(entity)) {
          try {
            await entity.delete();
          } on FileSystemException catch (_) {
            // Non-empty directories are preserved.
          }
        }
      }
    }

    return DeleteResult(bytes: bytes, files: files, errors: errors);
  }

  Stream<FileSystemEntity> _safeList(Directory directory) {
    try {
      return directory.list(followLinks: false);
    } on FileSystemException {
      return const Stream.empty();
    }
  }

  bool _isEligibleFile(File file, CleanupMode mode) {
    if (mode == CleanupMode.deleteChildren) {
      return true;
    }

    final lowerPath = file.path.toLowerCase();
    final isTemporary = _temporaryExtensions.any(lowerPath.endsWith);
    if (!isTemporary) {
      return false;
    }

    final modified = file.lastModifiedSync();
    return _now().difference(modified).inDays >= 7;
  }

  Future<bool> _isEmpty(Directory directory) async {
    try {
      return await directory.list(followLinks: false).isEmpty;
    } on FileSystemException {
      return false;
    }
  }
}
