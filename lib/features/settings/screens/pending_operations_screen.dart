import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modus_pampa_v3/data/models/pending_operation_model.dart';
import 'package:modus_pampa_v3/features/settings/services/sync_service.dart';

class PendingOperationsScreen extends ConsumerStatefulWidget {
  const PendingOperationsScreen({super.key});

  @override
  ConsumerState<PendingOperationsScreen> createState() => _PendingOperationsScreenState();
}

class _PendingOperationsScreenState extends ConsumerState<PendingOperationsScreen> {
  bool _isSyncing = false;
  final List<String> _syncLogs = [];

  Future<void> _runSync() async {
    setState(() {
      _isSyncing = true;
      _syncLogs.clear();
    });
    
    final syncService = ref.read(syncServiceProvider);
    
    // 1. Empujar cambios locales al servidor
    final pushLogs = await syncService.pushChanges();
    setState(() { _syncLogs.addAll(pushLogs); });
    
    // 2. Descargar cambios del servidor
    final pullLogs = await syncService.pullChanges();
    setState(() { _syncLogs.addAll(pullLogs); });

    setState(() { _isSyncing = false; });

    // Refresca la lista de operaciones pendientes
    ref.invalidate(pendingOperationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final pendingOpsAsync = ref.watch(pendingOperationsProvider);
    final syncService = ref.read(syncServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Operaciones Pendientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _runSync,
                icon: const Icon(Icons.sync),
                label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar Ahora'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing
                    ? null
                    : () async {
                        // Mostrar un diálogo de confirmación antes de borrar todas
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar Borrado Total'),
                            content: const Text(
                                '¿Estás seguro de que quieres borrar TODAS las operaciones pendientes? Esta acción no se puede deshacer.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                child: const Text('Borrar Todas'),
                              ),
                            ],
                          ),
                        );
            
                        if (confirm == true) {
                          await syncService.clearAllPendingOperations(); // Llama al nuevo método para borrar todas
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Todas las operaciones pendientes han sido borradas.')),
                          );
                        }
                      },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Borrar todas las operaciones'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700, // Color rojo para indicar una acción destructiva
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          if (_syncLogs.isNotEmpty)
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ListView.builder(
                  itemCount: _syncLogs.length,
                  itemBuilder: (context, index) {
                    final log = _syncLogs[index];
                    return Text(
                      log,
                      style: TextStyle(
                        color:
                            log.startsWith('❌')
                                ? Colors.redAccent
                                : (log.startsWith('✔️')
                                    ? Colors.greenAccent
                                    : Colors.white),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            flex: 1,
            child: pendingOpsAsync.when(
              data: (ops) {
                if (ops.isEmpty) return const Center(child: Text('Todo está sincronizado.'));
                return ListView.builder(
                  itemCount: ops.length,
                  itemBuilder: (context, index) {
                    final op = ops[index];
                    return ListTile(
                      leading: Icon(op.operationType == OperationType.CREATE ? Icons.add : (op.operationType == OperationType.UPDATE ? Icons.edit : Icons.delete), size: 20),
                      title: Text('${op.operationType.name} en ${op.tableName}'),
                      subtitle: Text('Fecha: ${DateFormat.yMd().add_Hms().format(op.createdAt)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: _isSyncing
                            ? null
                            : () async {
                                // Mostrar un diálogo de confirmación antes de borrar una específica
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmar Borrado'),
                                    content: const Text(
                                        '¿Estás seguro de que quieres borrar esta operación pendiente?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                        child: const Text('Borrar'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && op.id != null) {
                                  await syncService.clearPendingOperation(op.id!); // Llama al nuevo método para borrar una específica
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Operación #${op.id} borrada.')),
                                  );
                                }
                              },
                      ),
                      dense: true,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }
}
