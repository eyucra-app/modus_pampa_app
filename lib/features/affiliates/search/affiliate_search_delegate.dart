import 'package:flutter/material.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/features/affiliates/widgets/affiliate_card.dart';

class AffiliateSearchDelegate extends SearchDelegate<Affiliate?> {
  final List<Affiliate> allAffiliates;

  AffiliateSearchDelegate({required this.allAffiliates});

  @override
  String get searchFieldLabel => 'Buscar por nombre, ID o CI...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Ingrese un término de búsqueda.'));
    }

    final String lowercasedQuery = query.toLowerCase();

    final filteredAffiliates = allAffiliates.where((affiliate) {
      if (query.length < 4) {
        return affiliate.id.toLowerCase().contains(lowercasedQuery);
      } else {
        return affiliate.fullName.toLowerCase().contains(lowercasedQuery) ||
               affiliate.ci.contains(query);
      }
    }).toList();

    if (filteredAffiliates.isEmpty) {
      return Center(
        child: Text('No se encontraron afiliados para "$query"'),
      );
    }

    return ListView.builder(
      itemCount: filteredAffiliates.length,
      itemBuilder: (context, index) {
        final affiliate = filteredAffiliates[index];
        return AffiliateCard(
          affiliate: affiliate,
          onTap: () {
            // La única responsabilidad al tocar es cerrar y devolver el resultado.
            close(context, affiliate);
          },
        );
      },
    );
  }
}
