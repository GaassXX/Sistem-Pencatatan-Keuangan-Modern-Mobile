import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../utils/category_helper.dart';

class ReportExportService {
  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String _money(num value) {
    final text = value.round().toString();
    return 'Rp ${text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  static String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')} ${_monthNames[date.month - 1]} ${date.year}';
  }

  static String _description(dynamic tx) {
    final description = tx['description']?.toString().trim();
    return description == null || description.isEmpty ? '-' : description;
  }

  static Future<File> createReport({
    required List<dynamic> transactions,
    required int year,
    int? month,
    required String format,
  }) async {
    final monthTransactions = transactions.where((tx) {
      final date = DateTime.tryParse(tx['date']?.toString() ?? '');
      return date != null &&
          date.year == year &&
          (month == null || date.month == month);
    }).toList()
      ..sort((a, b) =>
          (DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(1900))
              .compareTo(DateTime.tryParse(b['date']?.toString() ?? '') ??
                  DateTime(1900)));

    double income = 0;
    double expense = 0;
    final categories = <String, double>{};
    for (final tx in monthTransactions) {
      final amount = amountValue(tx['amount']);
      final type = tx['type']?.toString().toLowerCase();
      if (type == 'income' || type == 'pemasukan') {
        income += amount;
      } else if (type == 'expense' || type == 'pengeluaran') {
        expense += amount;
        final category = categoryName(tx);
        categories[category] = (categories[category] ?? 0) + amount;
      }
    }
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final period =
        month == null ? 'Tahun $year' : '${_monthNames[month - 1]} $year';
    final directory = await getApplicationDocumentsDirectory();
    final safePeriod =
        month == null ? 'Tahun_$year' : '${_monthNames[month - 1]}_$year';

    if (format.toLowerCase() == 'excel' || format.toLowerCase() == 'xlsx') {
      return _createExcel(
        transactions: monthTransactions,
        categories: sortedCategories,
        income: income,
        expense: expense,
        period: period,
        file: File('${directory.path}/FinChat_Laporan_$safePeriod.xlsx'),
      );
    }
    return _createPdf(
      transactions: monthTransactions,
      categories: sortedCategories,
      income: income,
      expense: expense,
      period: period,
      file: File('${directory.path}/FinChat_Laporan_$safePeriod.pdf'),
    );
  }

  static Future<File> _createPdf({
    required List<dynamic> transactions,
    required List<MapEntry<String, double>> categories,
    required double income,
    required double expense,
    required String period,
    required File file,
  }) async {
    final pdf = pw.Document();
    final net = income - expense;
    final insight = categories.isEmpty
        ? 'Belum ada pengeluaran pada periode ini.'
        : 'Pengeluaran terbesar: ${categories.first.key} (${_money(categories.first.value)}, ${expense == 0 ? 0 : (categories.first.value / expense * 100).round()}% dari total pengeluaran).';

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.indigo, width: 2))),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('FinChat',
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo)),
              pw.Text('LAPORAN KEUANGAN',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ]),
      ),
      build: (_) => [
        pw.SizedBox(height: 16),
        pw.Text(period,
            style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _pdfSummaryCell('PEMASUKAN', PdfColors.green800),
                  _pdfSummaryCell('PENGELUARAN', PdfColors.red800),
                  _pdfSummaryCell('SALDO BERSIH',
                      net >= 0 ? PdfColors.indigo : PdfColors.red800),
                ]),
            pw.TableRow(children: [
              _pdfSummaryCell(_money(income), PdfColors.green800, large: true),
              _pdfSummaryCell(_money(expense), PdfColors.red800, large: true),
              _pdfSummaryCell(
                  _money(net), net >= 0 ? PdfColors.indigo : PdfColors.red800,
                  large: true),
            ]),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: const pw.BoxDecoration(
              color: PdfColors.indigo50,
              border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.indigo, width: 3))),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('INSIGHT KEUANGAN',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo)),
                pw.SizedBox(height: 5),
                pw.Text(insight, style: const pw.TextStyle(fontSize: 10)),
                if (income > 0)
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                          'Pengeluaran menggunakan ${(expense / income * 100).round()}% dari pemasukan.',
                          style: const pw.TextStyle(fontSize: 10))),
              ]),
        ),
        pw.SizedBox(height: 20),
        pw.Text('Rincian Transaksi',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (transactions.isEmpty)
          pw.Container(
              padding: const pw.EdgeInsets.all(14),
              child: pw.Text('Tidak ada transaksi pada periode ini.',
                  style: const pw.TextStyle(color: PdfColors.grey600)))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Tanggal', 'Deskripsi', 'Kategori', 'Jenis', 'Jumlah'],
            data: transactions
                .map((tx) => [
                      _date(tx['date']),
                      _description(tx),
                      categoryName(tx),
                      (tx['type']?.toString().toLowerCase() == 'income' ||
                              tx['type']?.toString().toLowerCase() ==
                                  'pemasukan')
                          ? 'Pemasukan'
                          : 'Pengeluaran',
                      _money(amountValue(tx['amount'])),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey300),
              bottom: pw.BorderSide(color: PdfColors.grey300),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.3),
              1: const pw.FlexColumnWidth(2.2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.5)
            },
          ),
      ],
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
    ));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _pdfSummaryCell(String text, PdfColor color,
          {bool large = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(9),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: large ? 11 : 8,
                fontWeight: pw.FontWeight.bold,
                color: color)),
      );

  static Future<File> _createExcel({
    required List<dynamic> transactions,
    required List<MapEntry<String, double>> categories,
    required double income,
    required double expense,
    required String period,
    required File file,
  }) async {
    final workbook = xlsio.Workbook(2);
    final summary = workbook.worksheets[0]..name = 'Ringkasan';
    final detail = workbook.worksheets[1]..name = 'Transaksi';

    summary.getRangeByName('A1:D1').merge();
    summary.getRangeByName('A1').setText('FINCHAT | LAPORAN KEUANGAN');
    summary.getRangeByName('A1:D1').cellStyle
      ..bold = true
      ..fontSize = 16
      ..fontColor = '#FFFFFF'
      ..backColor = '#5B4DFF'
      ..hAlign = xlsio.HAlignType.left
      ..vAlign = xlsio.VAlignType.center;
    summary.getRangeByName('A2').setText('Periode');
    summary.getRangeByName('B2:D2').merge();
    summary.getRangeByName('B2').setText(period);
    summary.getRangeByName('A4:C4').setText('Ringkasan');
    final summaryRows = [
      ['Jenis', 'Jumlah'],
      ['Pemasukan', income],
      ['Pengeluaran', expense],
      ['Saldo Bersih', income - expense],
    ];
    for (var row = 0; row < summaryRows.length; row++) {
      summary.getRangeByIndex(row + 5, 1).setValue(summaryRows[row][0]);
      summary.getRangeByIndex(row + 5, 2).setValue(summaryRows[row][1]);
    }
    summary.getRangeByName('A5:B5').cellStyle
      ..bold = true
      ..fontColor = '#FFFFFF'
      ..backColor = '#334155';
    summary.getRangeByName('B6:B8').numberFormat = '"Rp" #,##0';
    summary.getRangeByName('A11').setText('Pengeluaran per Kategori');
    summary.getRangeByName('A12').setText('Kategori');
    summary.getRangeByName('B12').setText('Jumlah');
    summary.getRangeByName('C12').setText('Visual');
    summary.getRangeByName('D12').setText('Porsi');
    summary.getRangeByName('A12:D12').cellStyle
      ..bold = true
      ..fontColor = '#FFFFFF'
      ..backColor = '#334155';
    if (categories.isNotEmpty) {
      for (var index = 0; index < categories.length; index++) {
        summary.getRangeByIndex(13 + index, 1).setText(categories[index].key);
        summary
            .getRangeByIndex(13 + index, 2)
            .setNumber(categories[index].value);
        final share = expense == 0 ? 0.0 : categories[index].value / expense;
        summary
            .getRangeByIndex(13 + index, 3)
            .setText('■' * (share * 20).round().clamp(1, 20));
        summary.getRangeByIndex(13 + index, 4).setNumber(share);
      }
      summary.getRangeByIndex(13, 2, 12 + categories.length, 2).numberFormat =
          '"Rp" #,##0';
      summary.getRangeByIndex(13, 4, 12 + categories.length, 4).numberFormat =
          '0%';
      summary.getRangeByName('C:C').columnWidth = 22;
      summary.getRangeByName('D:D').columnWidth = 12;
      summary
          .getRangeByIndex(13, 3, 12 + categories.length, 3)
          .cellStyle
          .fontColor = '#5B4DFF';
    }

    detail.getRangeByName('A1:F1').setText('Rincian Transaksi');
    detail.getRangeByName('A1:F1').cellStyle
      ..bold = true
      ..fontSize = 14
      ..fontColor = '#FFFFFF'
      ..backColor = '#5B4DFF';
    final headers = [
      'Tanggal',
      'Deskripsi',
      'Kategori',
      'Jenis',
      'Jumlah',
      'Sumber'
    ];
    for (var column = 0; column < headers.length; column++) {
      detail.getRangeByIndex(2, column + 1).setText(headers[column]);
    }
    detail.getRangeByName('A2:F2').cellStyle
      ..bold = true
      ..fontColor = '#FFFFFF'
      ..backColor = '#334155';
    if (transactions.isNotEmpty) {
      for (var index = 0; index < transactions.length; index++) {
        final tx = transactions[index];
        final type = tx['type']?.toString().toLowerCase();
        final row = index + 3;
        detail
            .getRangeByIndex(row, 1)
            .setValue(DateTime.tryParse(tx['date']?.toString() ?? '') ?? '');
        detail.getRangeByIndex(row, 2).setText(_description(tx));
        detail.getRangeByIndex(row, 3).setText(categoryName(tx));
        detail.getRangeByIndex(row, 4).setText(
            (type == 'income' || type == 'pemasukan')
                ? 'Pemasukan'
                : 'Pengeluaran');
        detail.getRangeByIndex(row, 5).setNumber(amountValue(tx['amount']));
        detail.getRangeByIndex(row, 6).setText(tx['source']?.toString() ?? '-');
      }
      detail.getRangeByIndex(3, 1, transactions.length + 2, 1).numberFormat =
          'dd mmm yyyy';
      detail.getRangeByIndex(3, 5, transactions.length + 2, 5).numberFormat =
          '"Rp" #,##0';
    }
    detail.getRangeByName('A:F').autoFitColumns();
    detail.getRangeByName('B:B').columnWidth = 30;
    detail.getRangeByName('C:C').columnWidth = 22;
    summary.getRangeByName('A:B').autoFitColumns();
    summary.getRangeByName('B:B').columnWidth = 20;

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
