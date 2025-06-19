import 'dart:typed_data';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/attendance_model.dart';
import 'package:modus_pampa_v3/data/models/contribution_model.dart';
import 'package:modus_pampa_v3/data/models/fine_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {

  // --- REPORTES POR AFILIADO ---

  Future<Uint8List> generateAffiliateSummaryReport({required Affiliate affiliate, required List<Fine> fines, required List<ContributionAffiliateLink> contributions}) async {
    final doc = pw.Document();
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    final pageFormat = isMobile ? PdfPageFormat.roll80 : PdfPageFormat.letter;
    final posStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isMobile ? 8 : 10);
    final cellStyle = isMobile ? posStyle : const pw.TextStyle(fontSize: 9);

    final content = [
      _buildHeader(isMobile, posStyle, 'REPORTE DE AFILIADO', affiliate.fullName.toUpperCase()),
      pw.Text('ID: ${affiliate.id} | CI: ${affiliate.ci}', textAlign: pw.TextAlign.center, style: cellStyle),
      pw.Divider(height: 20),
      _buildSectionTitle('Resumen Financiero', isMobile, posStyle),
      _buildFinancialSummary(affiliate, isMobile, cellStyle),
      pw.SizedBox(height: 10),
      _buildSectionTitle('Multas Pendientes', isMobile, posStyle),
      _buildFinesTable(fines.where((f) => !f.isPaid).toList(), isMobile, cellStyle),
      pw.SizedBox(height: 10),
      _buildSectionTitle('Aportes Pendientes', isMobile, posStyle),
      _buildContributionsTable(contributions.where((c) => !c.isPaid).toList(), isMobile, cellStyle),
    ];
    
    if (isMobile) {
      doc.addPage(pw.Page(margin: const pw.EdgeInsets.all(10), pageFormat: pageFormat, build: (pw.Context pwContext) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: content)));
    } else {
      doc.addPage(pw.MultiPage(margin: const pw.EdgeInsets.all(25), pageFormat: pageFormat, build: (pw.Context pwContext) => content));
    }

    return doc.save();
  }

  Future<Uint8List> generateAffiliateFinesReport({required Affiliate affiliate, required List<Fine> fines}) async {
    final doc = pw.Document();
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    final pageFormat = isMobile ? PdfPageFormat.roll80 : PdfPageFormat.letter;
    final posStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isMobile ? 8 : 10);
    doc.addPage(pw.Page(margin: const pw.EdgeInsets.all(10), pageFormat: pageFormat, build: (pw.Context pwContext) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildHeader(isMobile, posStyle, 'HISTORIAL DE MULTAS', affiliate.fullName.toUpperCase()),
        pw.SizedBox(height: 10),
        _buildFinesTable(fines, isMobile, posStyle, showStatus: true),
    ])));
    return doc.save();
  }

  Future<Uint8List> generateAffiliateContributionsReport({required Affiliate affiliate, required List<ContributionAffiliateLink> links, required List<Contribution> allContributions}) async {
    final doc = pw.Document();
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    final pageFormat = isMobile ? PdfPageFormat.roll80 : PdfPageFormat.letter;
    final posStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isMobile ? 8 : 10);
    doc.addPage(pw.Page(margin: const pw.EdgeInsets.all(10), pageFormat: pageFormat, build: (pw.Context pwContext) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildHeader(isMobile, posStyle, 'HISTORIAL DE APORTES', affiliate.fullName.toUpperCase()),
        pw.SizedBox(height: 10),
        _buildContributionsTable(links, isMobile, posStyle, showStatus: true, allContributions: allContributions),
    ])));
    return doc.save();
  }

  Future<Uint8List> generateAffiliateAttendanceReport({required Affiliate affiliate, required List<AttendanceRecord> records, required List<AttendanceList> allLists}) async {
    final doc = pw.Document();
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    final pageFormat = isMobile ? PdfPageFormat.roll80 : PdfPageFormat.letter;
    final posStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isMobile ? 8 : 10);
    final cellStyle = isMobile ? posStyle : const pw.TextStyle(fontSize: 9);

    doc.addPage(pw.Page(margin: const pw.EdgeInsets.all(10), pageFormat: pageFormat, build: (pw.Context pwContext) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildHeader(isMobile, posStyle, 'HISTORIAL DE ASISTENCIAS', affiliate.fullName.toUpperCase()),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
            columnWidths: const { 0: pw.FlexColumnWidth(1.5), 1: pw.FlexColumnWidth(3), 2: pw.FlexColumnWidth(2.5) },
            headerStyle: posStyle,
            cellStyle: cellStyle,
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            headers: ['Fecha', 'Lista', 'Estado'],
            data: records.map((r) {
              final list = allLists.firstWhere((l) => l.id == r.listId, orElse: () => AttendanceList(name: 'N/A', createdAt: DateTime.now()));
              return [DateFormat('dd/MM/yy').format(r.registeredAt), list.name, r.status.name];
            }).toList()
        ),
    ])));
    return doc.save();
  }

  // --- REPORTES GENERALES ---

  Future<Uint8List> generateContributionReport({ required Contribution contribution, required List<ContributionAffiliateLink> links, required List<Affiliate> allAffiliates }) async {
    final doc = pw.Document();
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    final pageFormat = isMobile ? PdfPageFormat.roll80 : PdfPageFormat.letter;
    final posStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isMobile ? 8 : 10);
    final cellStyle = isMobile ? posStyle : const pw.TextStyle(fontSize: 9);

    doc.addPage(pw.Page(margin: const pw.EdgeInsets.all(10), pageFormat: pageFormat, build: (pw.Context pwContext) { return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [ _buildHeader(isMobile, posStyle, 'REPORTE DE APORTE', contribution.name.toUpperCase()), pw.SizedBox(height: 10), pw.Table.fromTextArray(
      columnWidths: const { 0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(3), 2: pw.FlexColumnWidth(1.5), 3: pw.FlexColumnWidth(1.5), 4: pw.FlexColumnWidth(2.5) },
      headerStyle: posStyle,
      cellStyle: cellStyle,
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300), 
      headers: ['ID', 'Afiliado', 'Monto', 'Pagado', 'Estado'], 
      data: links.map((link) { final affiliate = allAffiliates.firstWhere((a) => a.uuid == link.affiliateUuid, orElse: () => Affiliate(uuid: '', id: 'N/A', firstName: 'No Encontrado', lastName: '', ci: '')); return [affiliate.id, affiliate.fullName, 'Bs. ${link.amountToPay.toStringAsFixed(2)}', 'Bs. ${link.amountPaid.toStringAsFixed(2)}', link.isPaid ? 'PAGADO' : 'PENDIENTE']; }).toList()), ]); }, ),); return doc.save(); }
  
  Future<Uint8List> generateAttendanceReport({ required AttendanceList attendanceList, required List<AttendanceRecord> records, required List<Affiliate> allAffiliates }) async {
    final doc = pw.Document();
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    final pageFormat = isMobile ? PdfPageFormat.roll80 : PdfPageFormat.letter;
    final posStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isMobile ? 8 : 10);
    final cellStyle = isMobile ? posStyle : const pw.TextStyle(fontSize: 9);

    final presentAndLate = records.where((r) => r.status != AttendanceRecordStatus.FALTA).toList();
    doc.addPage(pw.Page(margin: const pw.EdgeInsets.all(10), pageFormat: pageFormat, build: (pw.Context pwContext) { return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [ _buildHeader(isMobile, posStyle, 'REPORTE DE ASISTENCIA', attendanceList.name.toUpperCase()), pw.SizedBox(height: 10), pw.Table.fromTextArray(
      columnWidths: const { 0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(2.5), 2: pw.FlexColumnWidth(2.5), 3: pw.FlexColumnWidth(2.5) },
      headerStyle: posStyle,
      cellStyle: cellStyle,
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headers: ['ID', 'Afiliado', 'Hora', 'Estado'], 
      data: presentAndLate.map((record) { final affiliate = allAffiliates.firstWhere((a) => a.uuid == record.affiliateUuid, orElse: () => Affiliate(uuid: '', id: 'N/A', firstName: 'No Encontrado', lastName: '', ci: '')); return [affiliate.id, affiliate.fullName, DateFormat.Hms().format(record.registeredAt), record.status.name.toUpperCase()]; }).toList()), ]); }, ),); return doc.save(); }
  
  // --- Widgets de construcción de PDF (ACTUALIZADOS) ---

  pw.Widget _buildFinesTable(List<Fine> fines, bool isMobile, pw.TextStyle style, {bool showStatus = false}) {
    if (fines.isEmpty) return pw.Text('Sin registros.', style: style);
    
    final headerStyle = style.copyWith(fontWeight: pw.FontWeight.bold);

    List<String> headers = ['Fecha', 'Descripción', 'Pagado', 'Adeudado'];
    if (!showStatus) headers = ['Fecha', 'Descripción', 'Monto Adeudado'];

    return pw.Table.fromTextArray(
      border: null,
      headerStyle: headerStyle,
      cellStyle: style,
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      headers: headers,
      data: fines.map((f) {
        final debt = f.amount - f.amountPaid;
        if (showStatus) {
          return [DateFormat('dd/MM/yy').format(f.date), f.description, 'Bs. ${f.amountPaid.toStringAsFixed(2)}', 'Bs. ${debt.toStringAsFixed(2)}'];
        }
        return [DateFormat('dd/MM/yy').format(f.date), f.description, 'Bs. ${debt.toStringAsFixed(2)}'];
      }).toList()
    );
  }

  pw.Widget _buildContributionsTable(List<ContributionAffiliateLink> links, bool isMobile, pw.TextStyle style, {bool showStatus = false, List<Contribution>? allContributions}) {
    if (links.isEmpty) return pw.Text('Sin registros.', style: style);
    
    final headerStyle = style.copyWith(fontWeight: pw.FontWeight.bold);

    List<String> headers = ['Aporte', 'Pagado', 'Adeudado'];
    if (!showStatus) headers = ['Aporte', 'Monto Adeudado'];

    return pw.Table.fromTextArray(
      border: null,
      headerStyle: headerStyle,
      cellStyle: style,
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      headers: headers,
      data: links.map((c) {
        String contributionName = allContributions?.firstWhere((contrib) => contrib.id == c.contributionId, orElse: () => Contribution(id:0, name:'ID: ${c.contributionId}', date:DateTime.now(), defaultAmount:0)).name ?? c.contributionId.toString();
        final debt = c.amountToPay - c.amountPaid;
        if (showStatus) {
           return [contributionName, 'Bs. ${c.amountPaid.toStringAsFixed(2)}', 'Bs. ${debt.toStringAsFixed(2)}'];
        }
        return [contributionName, 'Bs. ${debt.toStringAsFixed(2)}'];
      }).toList()
    );
  }

  pw.Widget _buildHeader(bool isMobile, pw.TextStyle posStyle, String title, String subtitle) { final style = isMobile ? posStyle.copyWith(fontSize: 10) : pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold); return pw.Center(child: pw.Column(children: [ pw.Text(title, style: style), pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), style: isMobile ? posStyle.copyWith(fontSize: 8) : const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 10), pw.Text(subtitle, style: style.copyWith(fontSize: isMobile ? 9 : 16))])); }
  pw.Widget _buildSectionTitle(String title, bool isMobile, pw.TextStyle posStyle) { final style = isMobile ? posStyle : pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14); return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8), child: pw.Text(title.toUpperCase(), style: style)); }
  pw.Widget _buildFinancialSummary(Affiliate affiliate, bool isMobile, pw.TextStyle style) { return pw.Table(border: pw.TableBorder.all(), columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1.5)}, children: [_buildTableRow('Total Pagado:', 'Bs. ${affiliate.totalPaid.toStringAsFixed(2)}', style), _buildTableRow('Total Adeudado:', 'Bs. ${affiliate.totalDebt.toStringAsFixed(2)}', style, color: PdfColors.red100)]); }
  pw.TableRow _buildTableRow(String key, String value, pw.TextStyle style, {PdfColor? color}) { return pw.TableRow(decoration: pw.BoxDecoration(color: color), children: [pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(key, style: style)), pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(value, style: style, textAlign: pw.TextAlign.right))]); }
}