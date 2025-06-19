import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modus_pampa_v3/features/attendance/providers/attendance_providers.dart';
import 'package:modus_pampa_v3/data/models/attendance_model.dart';
import 'package:modus_pampa_v3/features/attendance/screens/attendance_detail_screen.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  void _showCreateListDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Crear Lista de Asistencia'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre o Detalle del Evento')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (nameController.text.isNotEmpty) {
              ref.read(attendanceNotifierProvider.notifier).createAttendanceList(nameController.text);
              Navigator.of(dialogContext).pop();
            }
          }, child: const Text('Crear')),
        ],
      ),
    );
  }

  void _confirmDeleteList(BuildContext context, WidgetRef ref, AttendanceList list) {
    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text("Eliminar Lista"),
      content: Text("¿Está seguro de que desea eliminar la lista '${list.name}'? Esta acción es permanente."),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancelar")),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () {
            ref.read(attendanceNotifierProvider.notifier).deleteAttendanceList(list);
            Navigator.of(dialogContext).pop();
          }, child: const Text("Eliminar")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceListsAsync = ref.watch(attendanceListProvider);

    ref.listen<AttendanceOperationState>(attendanceNotifierProvider, (prev, next) {
      if (next is AttendanceOperationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.green));
      } else if (next is AttendanceOperationError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Listas de Asistencia')),
      body: attendanceListsAsync.when(
        data: (lists) {
          if (lists.isEmpty) return const Center(child: Text('No hay listas de asistencia creadas.'));
          return RefreshIndicator(
            onRefresh: () => ref.refresh(attendanceListProvider.future),
            child: ListView.builder(
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(_getStatusIcon(list.status))),
                    title: Text(list.name),
                    subtitle: Text('Creada: ${DateFormat.yMd().add_jm().format(list.createdAt)}'),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(list.status.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _confirmDeleteList(context, ref, list),
                        )
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttendanceDetailScreen(attendanceList: list)));
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showCreateListDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Nueva Lista')),
    );
  }

  IconData _getStatusIcon(AttendanceListStatus status) { switch (status) { case AttendanceListStatus.PREPARADA: return Icons.hourglass_top_outlined; case AttendanceListStatus.INICIADA: return Icons.play_arrow_outlined; case AttendanceListStatus.TERMINADA: return Icons.timer_outlined; case AttendanceListStatus.FINALIZADA: return Icons.check_circle_outline; } }
}
