import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/features/reports/services/pdf_service.dart';

/// Provider que expone una instancia única del [PdfService].
final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});
