import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/contribution_model.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/contributions/providers/contribution_providers.dart';

class CreateContributionDialog extends ConsumerStatefulWidget {
  const CreateContributionDialog({super.key});

  @override
  ConsumerState<CreateContributionDialog> createState() => _CreateContributionDialogState();
}

class _CreateContributionDialogState extends ConsumerState<CreateContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _searchController = TextEditingController();

  List<Affiliate> _allAffiliates = [];
  List<Affiliate> _filteredAffiliates = [];
  Set<String> _selectedAffiliateUuids = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterAffiliates);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterAffiliates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAffiliates = _allAffiliates.where((aff) {
        return aff.fullName.toLowerCase().contains(query) || aff.id.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedAffiliateUuids = _allAffiliates.map((a) => a.uuid).toSet();
      } else {
        _selectedAffiliateUuids.clear();
      }
    });
  }

  void _createContribution() {
    if (_formKey.currentState!.validate() && _selectedAffiliateUuids.isNotEmpty) {
      final selectedAffiliates = _allAffiliates.where((aff) => _selectedAffiliateUuids.contains(aff.uuid)).toList();
      final newContribution = Contribution(
        name: _nameController.text,
        date: DateTime.now(),
        defaultAmount: double.tryParse(_amountController.text) ?? 0.0,
      );
      ref.read(contributionOperationProvider.notifier).createContribution(newContribution, selectedAffiliates);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final affiliateListState = ref.watch(affiliateListNotifierProvider);

    return AlertDialog(
      title: const Text('Crear Nuevo Aporte'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Evita que la columna principal se expanda infinitamente
                children: [
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre del Aporte'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  TextFormField(controller: _amountController, decoration: const InputDecoration(labelText: 'Monto Base', prefixText: 'Bs. '), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 16),
                  const Text('Aplicar a:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(controller: _searchController, decoration: const InputDecoration(labelText: 'Buscar por nombre o ID...', prefixIcon: Icon(Icons.search))),
                  const Divider(),
                  affiliateListState.allAffiliates.when(
                    data: (affiliates) {
                      if (_allAffiliates.isEmpty) {
                          _allAffiliates = affiliates;
                          _filteredAffiliates = affiliates;
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min, // --- CORRECCIÓN AQUÍ ---
                        children: [
                          CheckboxListTile(
                            title: const Text("Seleccionar Todos", style: TextStyle(fontWeight: FontWeight.bold)),
                            value: _selectedAffiliateUuids.length == _allAffiliates.length && _allAffiliates.isNotEmpty,
                            onChanged: _toggleSelectAll,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredAffiliates.length,
                              itemBuilder: (context, index) {
                                final affiliate = _filteredAffiliates[index];
                                return CheckboxListTile(
                                  title: Text(affiliate.fullName),
                                  subtitle: Text("ID: ${affiliate.id}"),
                                  value: _selectedAffiliateUuids.contains(affiliate.uuid),
                                  onChanged: (isSelected) {
                                    setState(() {
                                      if (isSelected!) {
                                        _selectedAffiliateUuids.add(affiliate.uuid);
                                      } else {
                                        _selectedAffiliateUuids.remove(affiliate.uuid);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())),
                    error: (e, s) => const Text('No se pudieron cargar los afiliados.'),
                  ),
                ],
              ),
            ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _createContribution, child: const Text('Crear')),
      ],
    );
  }
}
