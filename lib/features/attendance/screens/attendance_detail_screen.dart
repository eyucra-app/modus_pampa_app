import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/features/reports/providers/pdf_service_provider.dart';
import 'package:modus_pampa_v3/features/reports/screens/pdf_viewer_screen.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/attendance_model.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/affiliates/search/affiliate_search_delegate.dart';
import 'package:modus_pampa_v3/features/attendance/providers/attendance_providers.dart';
import 'package:modus_pampa_v3/features/attendance/widgets/payment_checkout_dialog.dart';
import 'package:intl/intl.dart';

class AttendanceDetailScreen extends ConsumerStatefulWidget {
  final AttendanceList attendanceList;
  const AttendanceDetailScreen({super.key, required this.attendanceList});

  @override
  ConsumerState<AttendanceDetailScreen> createState() =>
      _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState
    extends ConsumerState<AttendanceDetailScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessingQr = false;
  bool _isGeneratingReport = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _showDebtDialog(Affiliate affiliate) async {
    await ref.read(affiliateListNotifierProvider.notifier).loadAffiliates();
    final updatedAffiliates =
        ref.read(affiliateListNotifierProvider).allAffiliates.asData?.value ??
        [];
    final updatedAffiliate = updatedAffiliates.firstWhere(
      (a) => a.uuid == affiliate.uuid,
      orElse: () => affiliate,
    );
    if (mounted && updatedAffiliate.totalDebt > 0) {
      showDialog(
        context: context,
        builder: (_) => PaymentCheckoutDialog(affiliate: updatedAffiliate),
      );
    }
  }

  Future<void> _processRegistration(Affiliate affiliate) async {
    // Se pasa el ID de la lista en lugar del objeto completo
    await ref
        .read(attendanceNotifierProvider.notifier)
        .registerAffiliate(widget.attendanceList.id!, affiliate);
    await _showDebtDialog(affiliate);
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessingQr || scanData.code == null) return;
      setState(() {
        _isProcessingQr = true;
      });
      final Uri? uri = Uri.tryParse(scanData.code!);
      if (uri != null && uri.queryParameters.containsKey('id')) {
        final affiliateId = uri.queryParameters['id'];
        final allAffiliates =
            ref
                .read(affiliateListNotifierProvider)
                .allAffiliates
                .asData
                ?.value ??
            [];
        final affiliate = allAffiliates.firstWhere(
          (a) => a.id == affiliateId,
          orElse:
              () => Affiliate(
                uuid: '',
                id: '',
                firstName: 'NoEncontrado',
                lastName: '',
                ci: '',
              ),
        );
        if (affiliate.uuid.isNotEmpty) {
          await _processRegistration(affiliate);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Afiliado con ID '$affiliateId' no encontrado."),
              ),
            );
          }
        }
      }
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        _isProcessingQr = false;
      });
    });
  }

  void _manualRegister() async {
    final allAffiliates =
        ref.read(affiliateListNotifierProvider).allAffiliates.asData?.value ??
        [];
    final selected = await showSearch<Affiliate?>(
      context: context,
      delegate: AffiliateSearchDelegate(allAffiliates: allAffiliates),
    );
    if (selected != null) {
      await _processRegistration(selected);
    }
  }

  void _changeStatus(AttendanceListStatus newStatus) {
    ref
        .read(attendanceNotifierProvider.notifier)
        .updateListStatus(widget.attendanceList.id!, newStatus);
  }

  void _finalizeList() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text("Finalizar Lista"),
            content: const Text(
              "¿Está seguro? Esta acción generará multas por falta a los no registrados y cerrará la lista permanentemente.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancelar"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  ref
                      .read(attendanceNotifierProvider.notifier)
                      .finalizeList(widget.attendanceList);
                  Navigator.pop(dialogContext);
                },
                child: const Text("Finalizar"),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteRecord(AttendanceRecord record, Affiliate affiliate) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text("Eliminar Registro"),
            content: Text(
              "¿Está seguro de que desea eliminar el registro de ${affiliate.fullName}? Si este registro generó una multa por retraso, también será eliminada.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancelar"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  ref
                      .read(attendanceNotifierProvider.notifier)
                      .deleteAttendanceRecord(record, affiliate);
                  Navigator.pop(dialogContext);
                },
                child: const Text("Eliminar"),
              ),
            ],
          ),
    );
  }

  void _generateReport() async {
    setState(() {
      _isGeneratingReport = true;
    });
    try {
      final records = await ref.read(
        attendanceRecordsProvider(widget.attendanceList.id!).future,
      );
      final allAffiliates =
          ref
              .read(affiliateListNotifierProvider.notifier)
              .state
              .allAffiliates
              .asData
              ?.value ??
          [];
      final pdfService = ref.read(pdfServiceProvider);

      final pdfData = await pdfService.generateAttendanceReport(
        attendanceList: widget.attendanceList,
        records: records,
        allAffiliates: allAffiliates,
      );

      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => PdfViewerScreen(
                  pdfData: pdfData,
                  title: "Reporte Asistencia",
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al generar reporte: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentListAsync = ref
        .watch(attendanceListProvider)
        .whenData(
          (lists) => lists.firstWhere(
            (l) => l.id == widget.attendanceList.id,
            orElse: () => widget.attendanceList,
          ),
        );
    final recordsAsync = ref.watch(
      attendanceRecordsProvider(widget.attendanceList.id!),
    );
    final allAffiliatesState = ref.watch(affiliateListNotifierProvider);

    return currentListAsync.when(
      data:
          (currentList) => Scaffold(
            appBar: AppBar(
              title: Text(widget.attendanceList.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: _generateReport,
                  tooltip: "Generar Reporte PDF",
                ),
                if (currentList.status == AttendanceListStatus.INICIADA)
                  TextButton(
                    onPressed:
                        () => _changeStatus(AttendanceListStatus.TERMINADA),
                    child: const Text("TERMINAR"),
                  ),
                if (currentList.status == AttendanceListStatus.TERMINADA)
                  TextButton(
                    onPressed: _finalizeList,
                    child: const Text("FINALIZAR"),
                  ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    if (currentList.status != AttendanceListStatus.FINALIZADA)
                      SizedBox(
                        height: 250,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            QRView(
                              key: qrKey,
                              onQRViewCreated: _onQRViewCreated,
                              overlay: QrScannerOverlayShape(
                                borderColor: Theme.of(context).colorScheme.primary,
                                borderRadius: 10,
                                borderLength: 30,
                                borderWidth: 10,
                                cutOutSize: 200,
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: FutureBuilder<bool?>(
                                        future: controller?.getFlashStatus(),
                                        builder:
                                            (context, snapshot) => Icon(
                                              snapshot.data == true
                                                  ? Icons.flash_on
                                                  : Icons.flash_off,
                                              color: Colors.white,
                                            ),
                                      ),
                                      onPressed:
                                          () async => await controller
                                              ?.toggleFlash()
                                              .then((_) => setState(() {})),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.flip_camera_ios,
                                        color: Colors.white,
                                      ),
                                      onPressed:
                                          () async => await controller
                                              ?.flipCamera()
                                              .then((_) => setState(() {})),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "Registrados",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: recordsAsync.when(
                        data: (records) {
                          if (records.isEmpty) {
                            return const Center(
                              child: Text('Aún no hay registros.'),
                            );
                          }
                          return allAffiliatesState.allAffiliates.when(
                            data:
                                (allAffiliates) => ListView.builder(
                                  itemCount: records.length,
                                  itemBuilder: (context, index) {
                                    final record = records.reversed.toList()[index];
                                    final affiliate = allAffiliates.firstWhere(
                                      (a) => a.uuid == record.affiliateUuid,
                                      orElse:
                                          () => Affiliate(
                                            uuid: '',
                                            id: 'N/A',
                                            firstName: 'No encontrado',
                                            lastName: '',
                                            ci: '',
                                          ),
                                    );
                                    return ListTile(
                                      leading: Icon(
                                        record.status ==
                                                AttendanceRecordStatus.PRESENTE
                                            ? Icons.check_circle
                                            : Icons.warning_amber_rounded,
                                        color:
                                            record.status ==
                                                    AttendanceRecordStatus.PRESENTE
                                                ? Colors.green
                                                : Colors.orange,
                                      ),
                                      title: Text(affiliate.fullName),
                                      subtitle: Text(
                                        'Registrado: ${DateFormat.jms().format(record.registeredAt)}',
                                      ),
                                      trailing: Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          if (affiliate.totalDebt > 0)
                                            IconButton(
                                              icon: Icon(
                                                Icons.receipt_long,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                              ),
                                              onPressed:
                                                  () => _showDebtDialog(affiliate),
                                              tooltip: 'Ver deudas pendientes',
                                            ),
                                          Text(
                                            record.status.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (currentList.status !=
                                              AttendanceListStatus.FINALIZADA)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  () => _confirmDeleteRecord(
                                                    record,
                                                    affiliate,
                                                  ),
                                              tooltip: 'Eliminar Registro',
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            loading:
                                () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            error:
                                (_, __) => const Text('Error cargando afiliados'),
                          );
                        },
                        loading:
                            () => const Center(child: CircularProgressIndicator()),
                        error: (err, st) => Text('Error al cargar registros: $err'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            floatingActionButton:
                (currentList.status != AttendanceListStatus.FINALIZADA)
                    ? FloatingActionButton(
                      onPressed: _manualRegister,
                      tooltip: 'Registro Manual',
                      child: const Icon(Icons.person_add_alt_1),
                    )
                    : null,
          ),
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }
}
