import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:modus_pampa_v3/features/affiliates/search/affiliate_search_delegate.dart';
import 'package:modus_pampa_v3/features/affiliates/widgets/affiliate_card.dart';
import 'package:modus_pampa_v3/features/affiliates/screens/affiliate_form_screen.dart';

class AffiliatesScreen extends ConsumerWidget {
  const AffiliatesScreen({super.key});

  void _navigateToForm(BuildContext context, {Affiliate? affiliate}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => AffiliateFormScreen(affiliate: affiliate)));
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    final listState = ref.read(affiliateListNotifierProvider);
    final allAffiliates = listState.allAffiliates.asData?.value ?? [];
    final allTags = allAffiliates.expand((aff) => aff.tags).toSet().toList();
    final activeTags = listState.activeTags;

    showDialog(
      context: context,
      builder: (context) {
        return _FilterDialog(
          allTags: allTags,
          initialSelectedTags: activeTags,
          onApply: (selectedTags) {
            ref.read(affiliateListNotifierProvider.notifier).filterByTags(selectedTags);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final affiliateListState = ref.watch(affiliateListNotifierProvider);
    final filteredAffiliatesAsync = affiliateListState.filteredAffiliates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Afiliados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final affiliates = affiliateListState.allAffiliates.asData?.value;
              if (affiliates != null && context.mounted) {
                // Se espera el resultado de la búsqueda
                final selected = await showSearch<Affiliate?>(
                  context: context,
                  delegate: AffiliateSearchDelegate(allAffiliates: affiliates),
                );
                // Si se selecciona un afiliado, se navega a su formulario
                if (selected != null && context.mounted) {
                  _navigateToForm(context, affiliate: selected);
                }
              }
            },
          ),
          IconButton(
            icon: Icon(affiliateListState.activeTags.isEmpty ? Icons.filter_list_off_outlined : Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      body: filteredAffiliatesAsync.when(
        data: (affiliates) {
          if (affiliates.isEmpty) {
            return Center(child: Text(affiliateListState.activeTags.isEmpty ? 'No hay afiliados registrados.' : 'No hay afiliados con los tags seleccionados.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(affiliateListNotifierProvider.notifier).loadAffiliates(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
              itemCount: affiliates.length,
              itemBuilder: (context, index) {
                final affiliate = affiliates[index];
                return AffiliateCard(affiliate: affiliate, onTap: () => _navigateToForm(context, affiliate: affiliate));
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Afiliado'),
      ).animate().slideY(begin: 2, duration: 400.ms, curve: Curves.easeInOut),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final List<String> allTags;
  final Set<String> initialSelectedTags;
  final void Function(Set<String> selectedTags) onApply;

  const _FilterDialog({
    required this.allTags,
    required this.initialSelectedTags,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = Set.from(widget.initialSelectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrar por Tags'),
      content: SingleChildScrollView(
        child: widget.allTags.isEmpty
            ? const Text('No hay tags para filtrar.')
            : Wrap(
                spacing: 8.0,
                children: widget.allTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => widget.onApply(_selectedTags),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
