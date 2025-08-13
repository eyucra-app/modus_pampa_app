import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AffiliateCard extends StatelessWidget {
  final Affiliate affiliate;
  final VoidCallback onTap;

  const AffiliateCard({
    super.key,
    required this.affiliate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- LÓGICA DE IMAGEN CORREGIDA ---
    ImageProvider? imageProvider;
    final photoPath = affiliate.profilePhotoUrl;

    if (photoPath != null && photoPath.isNotEmpty) {
      if (kIsWeb) {
        // En web, asumir que todas las rutas son URLs de red
        imageProvider = CachedNetworkImageProvider(photoPath);
      } else {
        // En plataformas nativas, verificar si es archivo local
        if (File(photoPath).existsSync()) {
          imageProvider = FileImage(File(photoPath));
        } else {
          imageProvider = CachedNetworkImageProvider(photoPath);
        }
      }
    }
    // --- FIN DE LA LÓGICA DE IMAGEN ---

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.surface,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        (affiliate.firstName.isNotEmpty && affiliate.lastName.isNotEmpty)
                            ? '${affiliate.firstName[0]}${affiliate.lastName[0]}'
                            : '?',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      affiliate.fullName,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${affiliate.id} | CI: ${affiliate.ci}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMoneyIndicator(context, 'Pagado', affiliate.totalPaid, Colors.green.shade700),
                        const SizedBox(width: 12),
                        _buildMoneyIndicator(context, 'Adeudado', affiliate.totalDebt, theme.colorScheme.error),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    ).animate().fade().slideX(begin: -0.1, duration: 400.ms);
  }

  Widget _buildMoneyIndicator(BuildContext context, String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        Text('Bs. ${amount.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
