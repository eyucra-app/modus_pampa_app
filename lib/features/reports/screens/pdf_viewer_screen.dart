import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PdfViewerScreen extends StatelessWidget {
  final Uint8List pdfData;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfData,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PdfPreview(
        build: (format) => pdfData,
        useActions: true, // Muestra los botones de compartir, imprimir, etc.
        canChangePageFormat: true,
        canChangeOrientation: true,
        allowSharing: true,
        allowPrinting: true,
      ),
    );
  }
}
