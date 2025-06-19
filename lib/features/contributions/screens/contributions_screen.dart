import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modus_pampa_v3/features/contributions/providers/contribution_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:modus_pampa_v3/features/contributions/screens/contribution_detail_screen.dart';
import 'package:modus_pampa_v3/features/contributions/widgets/create_contribution_dialog.dart';

class ContributionsScreen extends ConsumerWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributionsAsync = ref.watch(contributionListProvider);

    ref.listen<ContributionOperationState>(contributionOperationProvider, (prev, next) {
      if (next is ContributionOperationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.green));
      } else if (next is ContributionOperationError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aportes Generales'),
      ),
      body: contributionsAsync.when(
        data: (contributions) {
          if (contributions.isEmpty) {
            return Center(child: const Text('No hay aportes creados.').animate().fade());
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(contributionListProvider.future),
            child: ListView.builder(
              itemCount: contributions.length,
              itemBuilder: (context, index) {
                final contribution = contributions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                    title: Text(contribution.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(contribution.description ?? 'Sin descripción'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Bs. ${contribution.defaultAmount.toStringAsFixed(2)}'),
                        Text(DateFormat.yMMMd('es_ES').format(contribution.date)),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ContributionDetailScreen(contribution: contribution),
                        ),
                      );
                    },
                  ),
                ).animate().fade(delay: (100 * index).ms);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar aportes: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (_) => const CreateContributionDialog());
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Aporte'),
      ),
    );
  }
}
