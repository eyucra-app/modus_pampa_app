// Provider para el servicio
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/features/settings/services/cloudinary_service.dart';
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});