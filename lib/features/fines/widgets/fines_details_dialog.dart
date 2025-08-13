import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/fine_model.dart';
import 'package:modus_pampa_v3/features/fines/providers/fines_providers.dart';

// 1. Convertido a ConsumerStatefulWidget
class FinesDetailsDialog extends ConsumerStatefulWidget {
  final Affiliate affiliate;
  const FinesDetailsDialog({super.key, required this.affiliate});

  @override
  ConsumerState<FinesDetailsDialog> createState() => _FinesDetailsDialogState();
}

// 2. Se crea la clase State correspondiente
class _FinesDetailsDialogState extends ConsumerState<FinesDetailsDialog> {
  void _showPayFineDialog(Fine fine) {
    final amountController = TextEditingController();
    final remainingDebt = fine.amount - fine.amountPaid;
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isPaying = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Registrar Pago de Multa'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Multa: ${fine.description}'),
                  Text(
                      'Monto adeudado: Bs. ${remainingDebt.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto a pagar',
                      prefixText: 'Bs. ',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar')),
                FilledButton(
                  onPressed: isPaying
                      ? null
                      : () async {
                          setState(() {
                            isPaying = true;
                          });
                          final amount =
                              double.tryParse(amountController.text) ?? 0.0;
                          if (amount > remainingDebt) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'El monto a pagar no puede ser mayor que la deuda.'),
                                    backgroundColor: Colors.red));
                            setState(() {
                              isPaying = false;
                            });
                            return;
                          }
                          if (amount > 0) {
                            await ref
                                .read(fineOperationProvider.notifier)
                                .payFine(fine, amount, widget.affiliate);
                            // 3. 'mounted' ahora es válido aquí
                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } else {
                            setState(() {
                              isPaying = false;
                            });
                          }
                        },
                  child: isPaying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Pagar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteFine(Fine fine) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Eliminar Multa'),
              content: Text(
                  '¿Está seguro de que desea eliminar la multa "${fine.description}"? Esta acción ajustará la deuda del afiliado.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar')),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setState(() {
                            isDeleting = true;
                          });
                          await ref
                              .read(fineOperationProvider.notifier)
                              .deleteFine(fine, widget.affiliate);
                          if (mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final finesAsync = ref.watch(finesByAffiliateProvider(widget.affiliate.uuid));

    ref.listen(finesByAffiliateProvider(widget.affiliate.uuid), (prev, next) {
      if (next.hasValue && next.value!.every((f) => f.isPaid)) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    return AlertDialog(
      title: Text('Multas de ${widget.affiliate.firstName}'),
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
                  subtitle:
                      Text('Fecha: ${DateFormat.yMd().format(fine.date)}'),
                  trailing: Wrap(
                    spacing: 0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                          'Bs. ${(fine.amount - fine.amountPaid).toStringAsFixed(2)}'),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 22),
                        onPressed: () => _confirmDeleteFine(fine),
                        tooltip: "Eliminar Multa",
                      ),
                    ],
                  ),
                  onTap: () => _showPayFineDialog(fine),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) =>
              const Center(child: Text('Error al cargar multas.')),
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