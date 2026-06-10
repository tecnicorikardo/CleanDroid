import 'package:flutter/material.dart';

import '../models/app_permission_status.dart';
import '../services/app_permission_service.dart';

class PermissionsPage extends StatefulWidget {
  PermissionsPage({super.key, AppPermissionService? permissionService})
    : permissionService = permissionService ?? AppPermissionService();

  final AppPermissionService permissionService;

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage>
    with WidgetsBindingObserver {
  AppPermissionStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final status = await widget.permissionService.loadStatus();

    if (!mounted) {
      return;
    }

    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _openAllFilesAccess() async {
    await widget.permissionService.openAllFilesAccessSettings();
  }

  Future<void> _openUsageAccess() async {
    await widget.permissionService.openUsageAccessSettings();
  }

  Future<void> _openAppDetails() async {
    await widget.permissionService.openAppDetailsSettings();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissoes necessarias'),
        actions: [
          IconButton(
            tooltip: 'Atualizar permissoes',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_loading && status == null)
            const LinearProgressIndicator()
          else ...[
            _PermissionTile(
              icon: Icons.folder_open,
              title: 'Acesso a todos os arquivos',
              description:
                  'Permite analisar Downloads e outras pastas acessiveis do armazenamento.',
              granted: status?.allFilesAccess ?? false,
              actionLabel: 'Abrir ajuste',
              onPressed: _openAllFilesAccess,
            ),
            const SizedBox(height: 12),
            _PermissionTile(
              icon: Icons.query_stats,
              title: 'Acesso ao uso',
              description:
                  'Permite consultar informacoes de uso de aplicativos quando essa fase for implementada.',
              granted: status?.usageAccess ?? false,
              actionLabel: 'Abrir ajuste',
              onPressed: _openUsageAccess,
            ),
            const SizedBox(height: 12),
            _PermissionTile(
              icon: Icons.apps,
              title: 'Consultar aplicativos instalados',
              description:
                  'Declarada no Manifest. O Android nao mostra uma chave para ativar esta permissao.',
              granted: status?.queryAllPackagesDeclared ?? false,
              actionLabel: 'Detalhes do app',
              onPressed: _openAppDetails,
            ),
          ],
          const SizedBox(height: 20),
          _PermissionHelpBox(
            allFilesAccess: status?.allFilesAccess ?? false,
            usageAccess: status?.usageAccess ?? false,
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = granted
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(description),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  granted ? Icons.check_circle : Icons.cancel,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    granted ? 'Permitida' : 'Nao permitida',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(onPressed: onPressed, child: Text(actionLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionHelpBox extends StatelessWidget {
  const _PermissionHelpBox({
    required this.allFilesAccess,
    required this.usageAccess,
  });

  final bool allFilesAccess;
  final bool usageAccess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = allFilesAccess && usageAccess;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ready
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          ready
              ? 'Permissoes especiais principais ativadas. Atualize a analise para usar os novos acessos.'
              : 'Se a tela comum de permissoes mostrar apenas Notificacoes, esta tudo certo: as permissoes especiais ficam em Acesso especial do Android.',
        ),
      ),
    );
  }
}
