class AppPermissionStatus {
  const AppPermissionStatus({
    required this.allFilesAccess,
    required this.usageAccess,
    required this.queryAllPackagesDeclared,
  });

  final bool allFilesAccess;
  final bool usageAccess;
  final bool queryAllPackagesDeclared;
}
