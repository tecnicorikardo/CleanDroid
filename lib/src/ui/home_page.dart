import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cleanup_report.dart';
import '../models/file_scan_result.dart';
import '../services/cleanup_scheduler.dart';
import '../services/cleanup_service.dart';
import '../services/cleanup_settings_service.dart';
import '../services/file_scanner_service.dart';
import 'permissions_page.dart';

class HomePage extends StatefulWidget {
  HomePage({
    super.key,
    CleanupService? cleanupService,
    CleanupSettingsService? settingsService,
    CleanupScheduler? scheduler,
    FileScannerService? fileScannerService,
  }) : cleanupService = cleanupService ?? CleanupService(),
       settingsService = settingsService ?? CleanupSettingsService(),
       scheduler = scheduler ?? CleanupScheduler(),
       fileScannerService = fileScannerService ?? FileScannerService();

  final CleanupService cleanupService;
  final CleanupSettingsService settingsService;
  final CleanupScheduler scheduler;
  final FileScannerService fileScannerService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CleanupReport? _report;
  FileScanResult? _scanResult;
  CleanupSettings _settings = const CleanupSettings(
    automaticCleanupEnabled: false,
    intervalHours: 24,
  );
  bool _loading = true;
  bool _cleaning = false;
  bool _hasStorageAccess = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final settings = await widget.settingsService.load();
    final storageAccess = await widget.cleanupService.hasStorageAccess();
    final report = await widget.cleanupService.analyze();
    final scanResult = await widget.fileScannerService.scan();

    if (!mounted) {
      return;
    }

    setState(() {
      _settings = settings;
      _hasStorageAccess = storageAccess;
      _report = report;
      _scanResult = scanResult;
      _loading = false;
    });
  }

  Future<void> _cleanNow() async {
    setState(() => _cleaning = true);
    final report = await widget.cleanupService.clean();
    await widget.settingsService.recordRun(deletedBytes: report.deletedBytes);
    final settings = await widget.settingsService.load();

    if (!mounted) {
      return;
    }

    setState(() {
      _report = report;
      _settings = settings;
      _cleaning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_formatBytes(report.deletedBytes)} liberados')),
    );
  }

  Future<void> _requestStorageAccess() async {
    final granted = await widget.cleanupService.requestStorageAccess();
    if (!mounted) {
      return;
    }

    setState(() => _hasStorageAccess = granted);
    await _load();
  }

  Future<void> _openPermissionsPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => PermissionsPage()));
    await _load();
  }

  Future<void> _setAutomaticCleanup(bool enabled) async {
    final next = _settings.copyWith(automaticCleanupEnabled: enabled);
    await widget.settingsService.save(next);
    await widget.scheduler.configure(next);

    if (!mounted) {
      return;
    }

    setState(() => _settings = next);
  }

  Future<void> _setInterval(int hours) async {
    final next = _settings.copyWith(intervalHours: hours);
    await widget.settingsService.save(next);
    await widget.scheduler.configure(next);

    if (!mounted) {
      return;
    }

    setState(() => _settings = next);
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CleanDroid'),
        actions: [
          IconButton(
            tooltip: 'Permissoes necessarias',
            onPressed: _openPermissionsPage,
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar analise',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SummaryPanel(
              loading: _loading,
              bytes: _scanResult?.totalBytes ?? 0,
              files: _scanResult?.totalFiles ?? 0,
              lastRunAt: _settings.lastRunAt,
              lastDeletedBytes: _settings.lastDeletedBytes,
            ),
            const SizedBox(height: 16),
            if (_scanResult == null)
              const LinearProgressIndicator()
            else
              _FileScanPanel(result: _scanResult!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading || _cleaning ? null : _cleanNow,
              icon: _cleaning
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cleaning_services),
              label: Text(_cleaning ? 'Limpando...' : 'Limpar agora'),
            ),
            const SizedBox(height: 16),
            _AutomaticCleanupPanel(
              settings: _settings,
              onEnabledChanged: _setAutomaticCleanup,
              onIntervalChanged: _setInterval,
            ),
            const SizedBox(height: 16),
            _StorageAccessPanel(
              hasStorageAccess: _hasStorageAccess,
              onRequestAccess: _requestStorageAccess,
              onOpenPermissions: _openPermissionsPage,
            ),
            const SizedBox(height: 16),
            if (report == null)
              const LinearProgressIndicator()
            else
              _CleanupAreasList(candidates: report.candidates),
            if ((report?.hasErrors ?? false) ||
                (_scanResult?.errors.isNotEmpty ?? false)) ...[
              const SizedBox(height: 16),
              _ErrorsList(
                errors: [...?report?.errors, ...?_scanResult?.errors],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.loading,
    required this.bytes,
    required this.files,
    required this.lastRunAt,
    required this.lastDeletedBytes,
  });

  final bool loading;
  final int bytes;
  final int files;
  final DateTime? lastRunAt;
  final int lastDeletedBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arquivos encontrados', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loading
                  ? const LinearProgressIndicator()
                  : Text(
                      _formatBytes(bytes),
                      key: ValueKey(bytes),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text('$files arquivos temporarios, logs ou vazios'),
            const SizedBox(height: 12),
            Text(
              lastRunAt == null
                  ? 'Nenhuma limpeza registrada'
                  : 'Ultima limpeza: ${DateFormat('dd/MM HH:mm').format(lastRunAt!)} '
                        '(${_formatBytes(lastDeletedBytes)})',
            ),
          ],
        ),
      ),
    );
  }
}

class _AutomaticCleanupPanel extends StatelessWidget {
  const _AutomaticCleanupPanel({
    required this.settings,
    required this.onEnabledChanged,
    required this.onIntervalChanged,
  });

  final CleanupSettings settings;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onIntervalChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Limpeza automatica de cache'),
          subtitle: const Text(
            'Executa em segundo plano quando o Android permitir',
          ),
          value: settings.automaticCleanupEnabled,
          onChanged: onEnabledChanged,
        ),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 24,
              icon: Icon(Icons.today),
              label: Text('Diaria'),
            ),
            ButtonSegment(
              value: 72,
              icon: Icon(Icons.date_range),
              label: Text('3 dias'),
            ),
            ButtonSegment(
              value: 168,
              icon: Icon(Icons.calendar_month),
              label: Text('Semanal'),
            ),
          ],
          selected: {settings.intervalHours},
          onSelectionChanged: settings.automaticCleanupEnabled
              ? (values) => onIntervalChanged(values.first)
              : null,
        ),
      ],
    );
  }
}

class _FileScanPanel extends StatelessWidget {
  const _FileScanPanel({required this.result});

  final FileScanResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = result.items.take(30).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scanner de arquivos', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricChip(
              icon: Icons.description_outlined,
              label: 'TMP',
              value: result.temporaryFiles.toString(),
            ),
            _MetricChip(
              icon: Icons.article_outlined,
              label: 'LOG',
              value: result.logFiles.toString(),
            ),
            _MetricChip(
              icon: Icons.insert_drive_file_outlined,
              label: 'Vazios',
              value: result.emptyFiles.toString(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Raizes analisadas: ${result.roots.length}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (result.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Nenhum arquivo .tmp, .log ou vazio encontrado.'),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (final item in items)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.reasons.map((reason) => reason.label).join(', ')}\n${item.path}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(_formatBytes(item.bytes)),
                  ),
                if (result.items.length > items.length)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Mais ${result.items.length - items.length} arquivos encontrados.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text('$label: $value'));
  }
}

class _StorageAccessPanel extends StatelessWidget {
  const _StorageAccessPanel({
    required this.hasStorageAccess,
    required this.onRequestAccess,
    required this.onOpenPermissions,
  });

  final bool hasStorageAccess;
  final VoidCallback onRequestAccess;
  final VoidCallback onOpenPermissions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              hasStorageAccess ? Icons.folder_open : Icons.lock_outline,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasStorageAccess
                    ? 'Acesso amplo ativado para temporarios em Downloads.'
                    : 'Sem acesso amplo, o app limpa apenas caches proprios.',
              ),
            ),
            TextButton(
              onPressed: hasStorageAccess ? null : onRequestAccess,
              child: const Text('Permitir'),
            ),
            IconButton(
              tooltip: 'Ver permissoes',
              onPressed: onOpenPermissions,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _CleanupAreasList extends StatelessWidget {
  const _CleanupAreasList({required this.candidates});

  final List<CleanupCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhuma area acessivel encontrada.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Areas analisadas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final candidate in candidates)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_delete_outlined),
            title: Text(candidate.area.label),
            subtitle: Text(
              candidate.path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(_formatBytes(candidate.bytes)),
          ),
      ],
    );
  }
}

class _ErrorsList extends StatelessWidget {
  const _ErrorsList({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.warning_amber),
      title: const Text('Avisos da limpeza'),
      children: [
        for (final error in errors) ListTile(dense: true, title: Text(error)),
      ],
    );
  }
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  if (unitIndex == 0) {
    return '${value.toStringAsFixed(0)} ${units[unitIndex]}';
  }

  return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
}
