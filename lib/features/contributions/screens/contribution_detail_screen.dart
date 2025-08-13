import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/contribution_model.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/contributions/providers/contribution_providers.dart';
import 'package:modus_pampa_v3/features/reports/providers/pdf_service_provider.dart';
import 'package:modus_pampa_v3/features/reports/screens/pdf_viewer_screen.dart';

class ContributionDetailScreen extends ConsumerStatefulWidget {
  final Contribution contribution;
  const ContributionDetailScreen({super.key, required this.contribution});

  @override
  ConsumerState<ContributionDetailScreen> createState() =>
      _ContributionDetailScreenState();
}

class _ContributionDetailScreenState
    extends ConsumerState<ContributionDetailScreen> {
  bool _isGeneratingReport = false;

  void _showEditAmountDialog(
      BuildContext context,
      WidgetRef ref,
      ContributionAffiliateLink link,
      Affiliate affiliate) {
    final amountController =
        TextEditingController(text: link.amountToPay.toString());
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Asignar Monto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Afiliado: ${affiliate.fullName}'),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                          labelText: 'Nuevo Monto', prefixText: 'Bs. '),
                      keyboardType: TextInputType.number),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar')),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() {
                            isSaving = true;
                          });
                          final amount =
                              double.tryParse(amountController.text) ?? 0.0;
                          
                          // --- VALIDACIÓN AÑADIDA ---
                          if (amount < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('El monto a asignar no puede ser negativo.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() {
                              isSaving = false;
                            });
                            return; // Detiene la ejecución
                          }

                          await ref
                              .read(contributionOperationProvider.notifier)
                              .updateContributionAmountForAffiliate(
                                  link, amount, affiliate);
                          if (mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPayContributionDialog(
      BuildContext context,
      WidgetRef ref,
      ContributionAffiliateLink link,
      Affiliate affiliate) {
    final amountController = TextEditingController();
    final remainingDebt = link.amountToPay - link.amountPaid;
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isPaying = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Pagar Aporte: ${widget.contribution.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Monto adeudado: Bs. ${remainingDebt.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Monto a pagar', prefixText: 'Bs. ')),
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
                                .read(contributionOperationProvider.notifier)
                                .payContribution(link, amount, affiliate);
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
                      : const Text('Registrar Pago'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteContribution(BuildContext context, WidgetRef ref) {
    showDialog<bool>( // Especifica que el diálogo puede devolver un booleano
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Eliminar Aporte"),
            content: Text(
                "¿Está seguro de que desea eliminar el aporte '${widget.contribution.name}'? Esta acción no se puede deshacer y se ajustará la deuda de todos los afiliados asignados."),
            actions: [
              TextButton(
                  // Devuelve 'false' si se cancela
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text("Cancelar")),
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
                            .read(contributionOperationProvider.notifier)
                            .deleteContribution(widget.contribution.uuid);
                        if (mounted) {
                          // Devuelve 'true' si se completó la eliminación
                          Navigator.of(dialogContext).pop(true);
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text("Eliminar"),
              )
            ],
          );
        });
      },
    ).then((wasDeleted) { // Maneja el resultado del diálogo aquí
      // Si wasDeleted es true, significa que se eliminó correctamente.
      if (wasDeleted == true && mounted) {
        Navigator.of(context).pop(); // Ahora es seguro hacer pop en la pantalla de detalles.
      }
    });
  }

  void _generateReport() async {
    setState(() {
      _isGeneratingReport = true;
    });
    try {
      final links = await ref
          .read(contributionDetailProvider(widget.contribution.uuid).future);
      final allAffiliates = ref
              .read(affiliateListNotifierProvider.notifier)
              .state
              .allAffiliates
              .asData
              ?.value ??
          [];
      final pdfService = ref.read(pdfServiceProvider);
      final pdfData = await pdfService.generateContributionReport(
        contribution: widget.contribution,
        links: links,
        allAffiliates: allAffiliates,
      );
      if (mounted) {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                PdfViewerScreen(pdfData: pdfData, title: "Reporte Aporte")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error al generar reporte: $e"),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final affiliateLinksAsync =
        ref.watch(contributionDetailProvider(widget.contribution.uuid));
    final allAffiliatesState = ref.watch(affiliateListNotifierProvider);

    ref.listen<ContributionOperationState>(contributionOperationProvider,
        (prev, next) {
      if (next is ContributionOperationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.message), backgroundColor: Colors.green));
      } else if (next is ContributionOperationError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.message), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contribution.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _generateReport,
            tooltip: "Generar Reporte PDF",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteContribution(context, ref),
            tooltip: "Eliminar Aporte",
          )
        ],
      ),
      body: Stack(
        children: [
          affiliateLinksAsync.when(
            data: (links) {
              return allAffiliatesState.allAffiliates.when(
                data: (allAffiliates) {
                  return ListView.separated(
                    itemCount: links.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final link = links[index];
                      final affiliate = allAffiliates.firstWhere(
                          (a) => a.uuid == link.affiliateUuid,
                          orElse: () => Affiliate(
                                uuid: '',
                                id: 'N/A',
                                firstName: 'No encontrado',
                                lastName: '',
                                ci: '',
                                createdAt: DateTime.now(),
                              ));
                      final isPaid = link.isPaid;

                      return ListTile(
                        leading: CircleAvatar(
                            backgroundColor: isPaid
                                ? Colors.green
                                : Theme.of(context).colorScheme.error,
                            child: Icon(isPaid ? Icons.check : Icons.close,
                                color: Colors.white)),
                        title: Text(affiliate.fullName),
                        subtitle: Text(
                            'Debe: Bs. ${link.amountToPay.toStringAsFixed(2)} | Pagado: Bs. ${link.amountPaid.toStringAsFixed(2)}'),
                        trailing: isPaid
                            ? null
                            : Wrap(
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.edit_note),
                                      tooltip: 'Asignar Monto',
                                      onPressed: () => _showEditAmountDialog(
                                          context, ref, link, affiliate)),
                                  IconButton(
                                      icon: const Icon(Icons.payment),
                                      tooltip: 'Pagar Aporte',
                                      onPressed: () =>
                                          _showPayContributionDialog(
                                              context, ref, link, affiliate)),
                                ],
                              ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Text('Error cargando afiliados'),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Text('Error cargando detalles'),
          ),
          if (_isGeneratingReport)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}