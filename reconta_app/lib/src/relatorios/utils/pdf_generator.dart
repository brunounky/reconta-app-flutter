// lib/src/relatorios/utils/pdf_generator.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generateAndSharePdf(
      String title, List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    final headers = ['Código Ref.', 'Nome do Produto', 'Diferença'];

    final tableData = data.map((item) {
      return [
        item['CodigoReferencia'].toString(),
        item['produtoNome'].toString(),
        item['diferenca'].toString(),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20.0),
            child: pw.Text(
              title,
              style: pw.Theme.of(context).defaultTextStyle.copyWith(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table.fromTextArray(
              headers: headers,
              data: tableData,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}