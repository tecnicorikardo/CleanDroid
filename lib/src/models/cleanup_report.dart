import 'dart:io';

enum CleanupArea { internalCache, externalCache, temporaryDownloads }

extension CleanupAreaLabel on CleanupArea {
  String get label {
    return switch (this) {
      CleanupArea.internalCache => 'Cache interno',
      CleanupArea.externalCache => 'Cache externo do app',
      CleanupArea.temporaryDownloads => 'Temporarios em Downloads',
    };
  }
}

class CleanupCandidate {
  const CleanupCandidate({
    required this.area,
    required this.path,
    required this.bytes,
    required this.files,
    required this.directories,
    required this.canDelete,
    this.reason,
  });

  final CleanupArea area;
  final String path;
  final int bytes;
  final int files;
  final int directories;
  final bool canDelete;
  final String? reason;
}

class CleanupReport {
  const CleanupReport({
    required this.startedAt,
    required this.finishedAt,
    required this.candidates,
    required this.deletedBytes,
    required this.deletedFiles,
    required this.errors,
  });

  final DateTime startedAt;
  final DateTime finishedAt;
  final List<CleanupCandidate> candidates;
  final int deletedBytes;
  final int deletedFiles;
  final List<String> errors;

  int get totalBytes => candidates.fold(0, (total, item) => total + item.bytes);

  int get totalFiles => candidates.fold(0, (total, item) => total + item.files);

  bool get hasErrors => errors.isNotEmpty;
}

class DirectoryStats {
  const DirectoryStats({
    required this.bytes,
    required this.files,
    required this.directories,
  });

  final int bytes;
  final int files;
  final int directories;

  static const empty = DirectoryStats(bytes: 0, files: 0, directories: 0);
}

class DeleteResult {
  const DeleteResult({
    required this.bytes,
    required this.files,
    required this.errors,
  });

  final int bytes;
  final int files;
  final List<String> errors;
}

class CleanupTarget {
  const CleanupTarget({
    required this.area,
    required this.directory,
    required this.mode,
  });

  final CleanupArea area;
  final Directory directory;
  final CleanupMode mode;
}

enum CleanupMode { deleteChildren, deleteTemporaryFiles }
