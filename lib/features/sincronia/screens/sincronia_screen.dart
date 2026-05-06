import 'package:flutter/material.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/sync_service.dart';

class SincroniaScreen extends StatelessWidget {
  const SincroniaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importação e Sincronia')),
      body: ListenableBuilder(
        listenable: SyncService.instance,
        builder: (context, _) {
          final sync = SyncService.instance;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Google Drive ───────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Google Drive',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!sync.isConnected) ...[
                        const Text(
                          'Conecte sua conta do Google para sincronizar '
                          'automaticamente os dados entre dispositivos.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => sync.signIn(),
                          icon: const Icon(Icons.login),
                          label: const Text('Conectar com Google'),
                        ),
                      ] else ...[
                        _infoRow(
                          context,
                          'Conta',
                          sync.account!.email,
                          Icons.account_circle,
                        ),
                        const SizedBox(height: 4),
                        _infoRow(
                          context,
                          'Última sincronização',
                          sync.lastSync != null
                              ? _formatDateTime(sync.lastSync!)
                              : 'Nunca',
                          Icons.history,
                        ),
                        if (sync.lastError != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sync.lastError!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: sync.status == SyncStatus.syncing
                                  ? null
                                  : () => sync.syncNow(),
                              icon: sync.status == SyncStatus.syncing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.sync),
                              label: Text(
                                sync.status == SyncStatus.syncing
                                    ? 'Sincronizando…'
                                    : 'Sincronizar agora',
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => sync.signOut(),
                              icon: const Icon(Icons.logout),
                              label: const Text('Desconectar'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Backup manual ─────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storage, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Backup manual',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Exporte ou importe os dados manualmente via arquivo JSON.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _exportar(context),
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Exportar JSON'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _importar(context),
                              icon: const Icon(Icons.download),
                              label: const Text('Importar JSON'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Nota de configuração ──────────────────────────────────────
              if (!sync.isConnected) ...[
                const SizedBox(height: 16),
                const _DriveSetupNote(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _exportar(BuildContext context) async {
    try {
      await BackupService.instance.exportar();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }

  Future<void> _importar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar dados'),
        content: const Text(
          'Isso substituirá TODOS os dados atuais pelo conteúdo do arquivo. '
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    try {
      final erro = await BackupService.instance.importar();
      if (context.mounted) {
        if (erro == null) SyncService.instance.onDataImported?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro ?? 'Dados importados com sucesso!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar: $e')),
        );
      }
    }
  }
}

class _DriveSetupNote extends StatelessWidget {
  const _DriveSetupNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16),
              SizedBox(width: 6),
              Text('Configuração necessária',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Para usar a sincronização com Google Drive, é necessário '
            'cadastrar a impressão digital SHA-1 do app no Google Cloud '
            'Console e adicionar o arquivo google-services.json ao projeto. '
            'Consulte a documentação do google_sign_in para mais detalhes.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
