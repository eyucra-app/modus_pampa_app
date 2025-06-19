import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/fine_model.dart';
import 'package:modus_pampa_v3/features/fines/providers/fines_providers.dart';

class FinesDetailsDialog extends ConsumerWidget {
  final Affiliate affiliate;
  const FinesDetailsDialog({super.key, required this.affiliate});

  void _showPayFineDialog(BuildContext context, WidgetRef ref, Fine fine) {
    final amountController = TextEditingController();
    final remainingDebt = fine.amount - fine.amountPaid;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar Pago de Multa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Multa: ${fine.description}'),
            Text('Monto adeudado: Bs. ${remainingDebt.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto a pagar',
                prefixText: 'Bs. ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              // --- VALIDACIÓN AÑADIDA ---
              if (amount > remainingDebt) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El monto a pagar no puede ser mayor que la deuda.'), backgroundColor: Colors.red));
                return; // No continuar
              }
              if (amount > 0) {
                await ref.read(fineOperationProvider.notifier).payFine(fine, amount, affiliate);
                Navigator.of(dialogContext).pop(); 
              }
            },
            child: const Text('Pagar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFine(BuildContext context, WidgetRef ref, Fine fine) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Multa'),
        content: Text('¿Está seguro de que desea eliminar la multa "${fine.description}"? Esta acción ajustará la deuda del afiliado.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              await ref.read(fineOperationProvider.notifier).deleteFine(fine, affiliate);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finesAsync = ref.watch(finesByAffiliateProvider(affiliate.uuid));

    ref.listen(finesByAffiliateProvider(affiliate.uuid), (prev, next) {
      if (next.hasValue && next.value!.every((f) => f.isPaid)) {
        if(Navigator.of(context).canPop()) {
           Navigator.of(context).pop();
        }
      }
    });

    return AlertDialog(
      title: Text('Multas de ${affiliate.firstName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: finesAsync.when(
          data: (fines) {
            final pendingFines = fines.where((f) => !f.isPaid).toList();
            if (pendingFines.isEmpty) {
              return const Center(child: Text('Sin multas pendientes.'));
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: pendingFines.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final fine = pendingFines[index];
                return ListTile(
                  title: Text(fine.description),
                  subtitle: Text('Fecha: ${DateFormat.yMd().format(fine.date)}'),
                  trailing: Wrap(
                    spacing: 0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Bs. ${(fine.amount - fine.amountPaid).toStringAsFixed(2)}'),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 22),
                        onPressed: () => _confirmDeleteFine(context, ref, fine),
                        tooltip: "Eliminar Multa",
                      ),
                    ],
                  ),
                  onTap: () => _showPayFineDialog(context, ref, fine),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => const Center(child: Text('Error al cargar multas.')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        )
      ],
    );
  }
}
