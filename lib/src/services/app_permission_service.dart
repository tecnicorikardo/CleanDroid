import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_permission_status.dart';

class AppPermissionService {
  static const _channel = MethodChannel('br.com.cleandroid.app/permissions');

  Future<AppPermissionStatus> loadStatus() async {
    final allFilesAccess = Platform.isAndroid
        ? await Permission.manageExternalStorage.isGranted
        : true;

    return AppPermissionStatus(
      allFilesAccess: allFilesAccess,
      usageAccess: await hasUsageAccess(),
      queryAllPackagesDeclared: true,
    );
  }

  Future<bool> hasUsageAccess() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openAllFilesAccessSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>('openAllFilesAccessSettings');
  }

  Future<void> openUsageAccessSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>('openUsageAccessSettings');
  }

  Future<void> openAppDetailsSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>('openAppDetailsSettings');
  }
}
