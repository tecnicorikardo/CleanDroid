import 'dart:io';

enum FileScanReason { temporaryExtension, logExtension, emptyFile }

extension FileScanReasonLabel on FileScanReason {
  String get label {
    return switch (this) {
      FileScanReason.temporaryExtension => 'Arquivo temporario',
      FileScanReason.logExtension => 'Log',
      FileScanReason.emptyFile => 'Arquivo vazio',
    };
  }
}

class FileScanItem {
  const FileScanItem({
    required this.path,
    required this.bytes,
    required this.modifiedAt,
    required this.reasons,
  });

  final String path;
  final int bytes;
  final DateTime modifiedAt;
  final Set<FileScanReason> reasons;

  String get name => path.split(Platform.pathSeparator).last;
}

class FileScanResult {
  const FileScanResult({
    required this.startedAt,
    required this.finishedAt,
    required this.roots,
    required this.items,
    required this.errors,
  });

  final DateTime startedAt;
  final DateTime finishedAt;
  final List<String> roots;
  final List<FileScanItem> items;
  final List<String> errors;

  int get totalBytes => items.fold(0, (total, item) => total + item.bytes);

  int get totalFiles => items.length;

  int get temporaryFiles => items
      .where((item) => item.reasons.contains(FileScanReason.temporaryExtension))
      .length;

  int get logFiles => items
      .where((item) => item.reasons.contains(FileScanReason.logExtension))
      .length;

  int get emptyFiles => items
      .where((item) => item.reasons.contains(FileScanReason.emptyFile))
      .length;
}
