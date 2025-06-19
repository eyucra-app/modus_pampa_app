import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/features/affiliates/search/affiliate_search_delegate.dart';
import 'package:modus_pampa_v3/features/affiliates/widgets/affiliate_card.dart';
import 'package:modus_pampa_v3/features/fines/providers/fines_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:modus_pampa_v3/features/fines/widgets/create_fine_dialog.dart';
import 'package:modus_pampa_v3/features/fines/widgets/fines_details_dialog.dart';

class FinesScreen extends ConsumerWidget {
  const FinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final affiliatesWithFinesAsync = ref.watch(affiliatesWithFinesProvider);

    ref.listen<FineOperationState>(fineOperationProvider, (prev, next) {
      if (next is FineOperationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.green));
        ref.invalidate(affiliatesWithFinesProvider);
      } else if (next is FineOperationError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Afiliados con Multas'),
        actions: [
          affiliatesWithFinesAsync.when(
            data: (affiliates) => IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                // Se espera (await) el resultado que devuelve el SearchDelegate
                final selected = await showSearch<Affiliate?>(
                  context: context,
                  delegate: AffiliateSearchDelegate(allAffiliates: affiliates),
                );

                // Si se seleccionó un afiliado, se muestra el diálogo de multas
                if (selected != null && context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => FinesDetailsDialog(affiliate: selected),
                  );
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Crear Multa Manual',
            onPressed: () {
              showDialog(context: context, builder: (_) => const CreateFineDialog());
            },
          )
        ],
      ),
      body: affiliatesWithFinesAsync.when(
        data: (affiliates) {
          if (affiliates.isEmpty) {
            return Center(child: const Text('Ningún afiliado tiene multas pendientes.').animate().fade());
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(affiliatesWithFinesProvider.future),
            child: ListView.builder(
              itemCount: affiliates.length,
              itemBuilder: (context, index) {
                final affiliate = affiliates[index];
                return AffiliateCard(
                  affiliate: affiliate,
                  onTap: () {
                    showDialog(context: context, builder: (_) => FinesDetailsDialog(affiliate: affiliate));
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
