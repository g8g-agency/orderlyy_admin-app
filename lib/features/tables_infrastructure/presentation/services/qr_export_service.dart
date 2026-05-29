import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/dtos/table_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final qrExportServiceProvider = Provider<QRExportService>((ref) {
  return QRExportService();
});

class QRExportService {
  /// Generates a PDF containing a grid of QR codes for the provided tables
  Future<Uint8List> generateBatchQrSheet(
    List<TableDto> tables,
    String branchName, {
    required Future<String?> Function(String) getQrToken,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final doc = pw.Document();

    // Fetch all tokens first
    final List<Map<String, dynamic>> tokenDataList = [];
    for (final table in tables) {
      final token = await getQrToken(table.id);
      if (token != null) {
        tokenDataList.add({'table': table, 'token': token});
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32), // bleed-safe margins
        build: (pw.Context context) {
          final List<pw.Widget> gridItems = tokenDataList.map((data) {
            final TableDto table = data['table'];
            final String token = data['token'];
            final qrUrl = 'https://orderlli.com/qr/$token';

            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    branchName,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Table ${table.tableNumber}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (table.displayName != null &&
                      table.displayName!.isNotEmpty)
                    pw.Text(
                      table.displayName!,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  pw.SizedBox(height: 12),
                  // Vector barcode rendering
                  pw.BarcodeWidget(
                    data: qrUrl,
                    barcode: pw.Barcode.qrCode(),
                    width: 100,
                    height: 100,
                    drawText: false,
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Scan to Order',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ],
              ),
            );
          }).toList();

          final isRoll = format.width == PdfPageFormat.roll80.width;

          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'QR Codes - $branchName',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (isRoll)
              pw.Column(
                children: gridItems
                    .map(
                      (item) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 24),
                        child: item,
                      ),
                    )
                    .toList(),
              )
            else
              pw.GridView(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: gridItems,
              ),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// Opens a print/share dialog for the generated PDF
  Future<void> printOrSharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }
}
