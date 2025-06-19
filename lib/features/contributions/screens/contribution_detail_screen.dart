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
  ConsumerState<ContributionDetailScreen> createState() => _ContributionDetailScreenState();
}

class _ContributionDetailScreenState extends ConsumerState<ContributionDetailScreen> {
  bool _isGeneratingReport = false;

  void _showEditAmountDialog(BuildContext context, WidgetRef ref, ContributionAffiliateLink link, Affiliate affiliate) {
    final amountController = TextEditingController(text: link.amountToPay.toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Asignar Monto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Afiliado: ${affiliate.fullName}'),
            const SizedBox(height: 16),
            TextFormField(controller: amountController, decoration: const InputDecoration(labelText: 'Nuevo Monto', prefixText: 'Bs. '), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async { 
              final amount = double.tryParse(amountController.text) ?? 0.0;
              await ref.read(contributionOperationProvider.notifier).updateContributionAmountForAffiliate(link, amount, affiliate);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      )
    );
  }

  void _showPayContributionDialog(BuildContext context, WidgetRef ref, ContributionAffiliateLink link, Affiliate affiliate) {
    final amountController = TextEditingController();
    final remainingDebt = link.amountToPay - link.amountPaid;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Pagar Aporte: ${widget.contribution.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Monto adeudado: Bs. ${remainingDebt.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monto a pagar', prefixText: 'Bs. ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () async { 
            final amount = double.tryParse(amountController.text) ?? 0.0;
            // --- VALIDACIÓN AÑADIDA ---
            if (amount > remainingDebt) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El monto a pagar no puede ser mayor que la deuda.'), backgroundColor: Colors.red));
              return; // No continuar
            }
            if (amount > 0) {
              await ref.read(contributionOperationProvider.notifier).payContribution(link, amount, affiliate);
              Navigator.of(dialogContext).pop();
            }
          }, child: const Text('Registrar Pago')),
        ],
      ),
    );
  }

  void _confirmDeleteContribution(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Eliminar Aporte"),
        content: Text("¿Está seguro de que desea eliminar el aporte '${widget.contribution.name}'? Esta acción no se puede deshacer y se ajustará la deuda de todos los afiliados asignados."),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancelar")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Cierra el diálogo de confirmación
              await ref.read(contributionOperationProvider.notifier).deleteContribution(widget.contribution.id!);
              Navigator.of(context).pop(); // Regresa a la lista de aportes
            },
            child: const Text("Eliminar"),
          )
        ],
      ),
    );
  }

  void _generateReport() async {
    setState(() { _isGeneratingReport = true; });
    try {
      final links = await ref.read(contributionDetailProvider(widget.contribution.id!).future);
      final allAffiliates = ref.read(affiliateListNotifierProvider.notifier).state.allAffiliates.asData?.value ?? [];
      final pdfService = ref.read(pdfServiceProvider);
      final pdfData = await pdfService.generateContributionReport(
        contribution: widget.contribution,
        links: links,
        allAffiliates: allAffiliates,
      );
      if (mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfViewerScreen(pdfData: pdfData, title: "Reporte Aporte")));
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al generar reporte: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() { _isGeneratingReport = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final affiliateLinksAsync = ref.watch(contributionDetailProvider(widget.contribution.id!));
    final allAffiliatesState = ref.watch(affiliateListNotifierProvider);
    
    ref.listen<ContributionOperationState>(contributionOperationProvider, (prev, next) {
      if (next is ContributionOperationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.green));
      } else if (next is ContributionOperationError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contribution.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _generateReport,
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
                      final affiliate = allAffiliates.firstWhere((a) => a.uuid == link.affiliateUuid, orElse: () => Affiliate(uuid: '', id: 'N/A', firstName: 'No encontrado', lastName: '', ci: ''));
                      final isPaid = link.isPaid;
                      
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: isPaid ? Colors.green : Theme.of(context).colorScheme.error, child: Icon(isPaid ? Icons.check : Icons.close, color: Colors.white)),
                        title: Text(affiliate.fullName),
                        subtitle: Text('Debe: Bs. ${link.amountToPay.toStringAsFixed(2)} | Pagado: Bs. ${link.amountPaid.toStringAsFixed(2)}'),
                        trailing: isPaid ? null : Wrap(
                          children: [
                            IconButton(icon: const Icon(Icons.edit_note), tooltip: 'Asignar Monto', onPressed: () => _showEditAmountDialog(context, ref, link, affiliate)),
                            IconButton(icon: const Icon(Icons.payment), tooltip: 'Pagar Aporte', onPressed: () => _showPayContributionDialog(context, ref, link, affiliate)),
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
        ],
      ),
    );
  }
}
