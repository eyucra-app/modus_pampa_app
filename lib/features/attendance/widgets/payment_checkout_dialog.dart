import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/contribution_model.dart';
import 'package:modus_pampa_v3/data/models/fine_model.dart';
import 'package:modus_pampa_v3/features/contributions/providers/contribution_providers.dart';
import 'package:modus_pampa_v3/features/fines/providers/fines_providers.dart';

class PaymentCheckoutDialog extends ConsumerStatefulWidget {
  final Affiliate affiliate;
  const PaymentCheckoutDialog({super.key, required this.affiliate});

  @override
  ConsumerState<PaymentCheckoutDialog> createState() =>
      _PaymentCheckoutDialogState();
}

class _PaymentCheckoutDialogState extends ConsumerState<PaymentCheckoutDialog> {
  void _showPayFineDialog(Fine fine) {
    final amountController = TextEditingController();
    final remainingDebt = fine.amount - fine.amountPaid;
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isPaying = false;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Pagar Multa'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(fine.description,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Monto adeudado: Bs. ${remainingDebt.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Monto a pagar'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true))
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancelar")),
              FilledButton(
                onPressed: isPaying
                    ? null
                    : () async {
                        setState(() {
                          isPaying = true;
                        });
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount > (remainingDebt + 0.001)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('El monto excede la deuda.'),
                                  backgroundColor: Colors.red));
                           setState(() { isPaying = false; });
                          return;
                        }
                        if (amount > 0) {
                          await ref
                              .read(fineOperationProvider.notifier)
                              .payFine(fine, amount, widget.affiliate);
                          if(mounted) Navigator.pop(dialogContext);
                          ref.invalidate(
                              finesByAffiliateProvider(widget.affiliate.uuid));
                        } else {
                           setState(() { isPaying = false; });
                        }
                      },
                child: isPaying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Pagar"),
              )
            ],
          );
        });
      },
    );
  }

  void _showPayContributionDialog(ContributionAffiliateLink link) {
    final amountController = TextEditingController();
    final remainingDebt = link.amountToPay - link.amountPaid;
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isPaying = false;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Pagar Aporte'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Aporte (UUID: ${link.contributionUuid})'),
              Text('Monto adeudado: Bs. ${remainingDebt.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Monto a pagar'),
                  keyboardType: TextInputType.number)
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancelar")),
              FilledButton(
                onPressed: isPaying
                    ? null
                    : () async {
                        setState(() => isPaying = true);
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount > (remainingDebt + 0.001)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('El monto excede la deuda.'),
                                  backgroundColor: Colors.red));
                           setState(() => isPaying = false);
                          return;
                        }
                        if (amount > 0) {
                          await ref
                              .read(contributionOperationProvider.notifier)
                              .payContribution(link, amount, widget.affiliate);
                          if(mounted) Navigator.pop(dialogContext);
                          ref.invalidate(pendingContributionsProvider(
                              widget.affiliate.uuid));
                        } else {
                           setState(() => isPaying = false);
                        }
                      },
                child: isPaying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Pagar"),
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingFinesAsync =
        ref.watch(finesByAffiliateProvider(widget.affiliate.uuid));
    final pendingContributionsAsync =
        ref.watch(pendingContributionsProvider(widget.affiliate.uuid));

    return AlertDialog(
      title: Text('Cobranza: ${widget.affiliate.fullName}'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Multas Pendientes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              pendingFinesAsync.when(
                data: (fines) {
                  final pending = fines.where((f) => !f.isPaid).toList();
                  if (pending.isEmpty) {
                    return const ListTile(title: Text('Ninguna.'), dense: true);
                  }
                  return Column(
                      children: pending
                          .map((f) => ListTile(
                              title: Text(f.description),
                              subtitle: Text(
                                  'Debe: Bs. ${(f.amount - f.amountPaid).toStringAsFixed(2)}'),
                              trailing: ElevatedButton(
                                  child: const Text("Pagar"),
                                  onPressed: () => _showPayFineDialog(f))))
                          .toList());
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Error al cargar multas.'),
              ),
              const Divider(height: 20),
              const Text('Aportes Pendientes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              pendingContributionsAsync.when(
                data: (contribs) {
                  final pending = contribs.where((c) => !c.isPaid).toList();
                  if (pending.isEmpty) {
                    return const ListTile(
                        title: Text('Ninguno.'), dense: true);
                  }
                  return Column(
                      children: pending
                          .map((c) => ListTile(
                              title: Text('Aporte ID: ${c.contributionUuid}'),
                              subtitle: Text(
                                  'Debe: Bs. ${(c.amountToPay - c.amountPaid).toStringAsFixed(2)}'),
                              trailing: ElevatedButton(
                                  child: const Text("Pagar"),
                                  onPressed: () =>
                                      _showPayContributionDialog(c))))
                          .toList());
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Error al cargar aportes.'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar')),
      ],
    );
  }
}