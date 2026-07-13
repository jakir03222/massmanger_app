import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/monthly_settlement.dart';

class MonthlyReportPdfService {
  static const List<String> _enMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static pw.Font? _regular;
  static pw.Font? _bold;

  /// Loads bundled Noto Sans Bengali so Unicode Bangla renders offline
  /// without falling back to Helvetica (which breaks glyphs).
  Future<void> _ensureFonts() async {
    if (_regular != null && _bold != null) return;
    final regularData =
        await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
    final boldData =
        await rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf');
    _regular = pw.Font.ttf(regularData);
    _bold = pw.Font.ttf(boldData);
  }

  Future<Uint8List> generate(MonthlySettlementReport report) async {
    await _ensureFonts();
    final regular = _regular!;
    final bold = _bold!;

    final doc = pw.Document();
    final monthLabel =
        '${_enMonths[report.month.month - 1]} ${report.month.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        theme: pw.ThemeData.withFont(
          base: regular,
          bold: bold,
          fontFallback: [regular, bold],
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  '${report.mess.name} — $monthLabel',
                  style: pw.TextStyle(font: bold, fontSize: 10),
                ),
              ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(font: regular, fontSize: 8),
          ),
        ),
        build: (context) => [
          _buildTitle(report, monthLabel, regular, bold),
          pw.SizedBox(height: 10),
          _buildStatementTable(report, regular, bold),
          pw.SizedBox(height: 12),
          _buildNote(report, regular, bold),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildTitle(
    MonthlySettlementReport report,
    String monthLabel,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            '${report.mess.name} — Mess Statement for the Month of $monthLabel',
            style: pw.TextStyle(
              font: bold,
              fontSize: 14,
              color: PdfColors.red800,
            ),
          ),
        ),
        if (report.mess.location.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Center(
            child: pw.Text(
              report.mess.location,
              style: pw.TextStyle(font: regular, fontSize: 9),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildStatementTable(
    MonthlySettlementReport report,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(1.6),
        2: const pw.FlexColumnWidth(1.1),
        3: const pw.FlexColumnWidth(0.9),
        4: const pw.FlexColumnWidth(1.0),
        5: const pw.FlexColumnWidth(0.9),
        6: const pw.FlexColumnWidth(1.0),
        7: const pw.FlexColumnWidth(1.0),
        8: const pw.FlexColumnWidth(0.9),
        9: const pw.FlexColumnWidth(1.0),
        10: const pw.FlexColumnWidth(1.2),
        11: const pw.FlexColumnWidth(1.0),
      },
      children: [
        _headerRow(bold),
        ...report.members.map((row) => _memberRow(row, regular, bold)),
        _totalRow(report, bold),
      ],
    );
  }

  pw.TableRow _headerRow(pw.Font bold) {
    pw.Widget h(String text) => _cell(
          text,
          bold,
          align: pw.TextAlign.center,
          fontSize: 8,
        );
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF4CCCC)),
      children: [
        h('SL'),
        h('Name'),
        h('Consume meal for the month'),
        h('Meal rate (TK)'),
        h('Cost of meal'),
        h('Cook cost'),
        h('Total Due'),
        h('Deposit Money'),
        h('Eid Bonus'),
        h('Total Cost'),
        h('Net Payable/ Receivable'),
        h('Remarks'),
      ],
    );
  }

  pw.TableRow _memberRow(
    MemberMonthlySettlement row,
    pw.Font regular,
    pw.Font bold,
  ) {
    final net = row.netPayableReceivable;
    final isPayable = net < 0;
    return pw.TableRow(
      children: [
        _cell('${row.serial}', regular, align: pw.TextAlign.center),
        _cell(row.member.name, regular),
        _cell(_meals(row.consumeMeal), regular, align: pw.TextAlign.center),
        _cell(_money(row.mealRate), regular, align: pw.TextAlign.right),
        _cell(_money(row.costOfMeal), regular, align: pw.TextAlign.right),
        _cell(_money(row.cookCost), regular, align: pw.TextAlign.right),
        _cell(_money(row.totalDue), regular, align: pw.TextAlign.right),
        _cell(_money(row.depositMoney), regular, align: pw.TextAlign.right),
        _cell(
          row.eidBonus == 0 ? '' : _money(row.eidBonus),
          regular,
          align: pw.TextAlign.right,
        ),
        _cell(
          _money(row.totalCost),
          bold,
          align: pw.TextAlign.right,
        ),
        _cell(
          _money(net),
          bold,
          align: pw.TextAlign.right,
          color: isPayable ? PdfColors.red800 : PdfColors.green800,
          background: isPayable
              ? const PdfColor.fromInt(0xFFFCE4E4)
              : const PdfColor.fromInt(0xFFE6F4EA),
        ),
        _cell('', regular),
      ],
    );
  }

  pw.TableRow _totalRow(MonthlySettlementReport report, pw.Font bold) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFCE5CD)),
      children: [
        _cell('', bold),
        _cell('Total', bold, align: pw.TextAlign.center),
        _cell(_meals(report.totalConsumeMeal), bold, align: pw.TextAlign.center),
        _cell('', bold),
        _cell(_money(report.totalCostOfMeal), bold, align: pw.TextAlign.right),
        _cell(_money(report.totalCookCost), bold, align: pw.TextAlign.right),
        _cell(_money(report.totalDue), bold, align: pw.TextAlign.right),
        _cell(_money(report.totalDeposit), bold, align: pw.TextAlign.right),
        _cell(
          report.totalEidBonus == 0 ? '' : _money(report.totalEidBonus),
          bold,
          align: pw.TextAlign.right,
        ),
        _cell(_money(report.totalCost), bold, align: pw.TextAlign.right),
        _cell(
          _money(report.totalNet),
          bold,
          align: pw.TextAlign.right,
          color: report.totalNet < 0 ? PdfColors.red800 : PdfColors.green800,
        ),
        _cell('', bold),
      ],
    );
  }

  pw.Widget _buildNote(
    MonthlySettlementReport report,
    pw.Font regular,
    pw.Font bold,
  ) {
    final billLines = report.fixedBills
        .map((b) => '${b.type.bnLabel}: ${_money(b.amount)}')
        .join('  •  ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'হিসাবের নিয়ম (Calculation)',
          style: pw.TextStyle(font: bold, fontSize: 9),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Meal rate = মোট বাজার (${_money(report.totalCostOfMeal)}) ÷ মোট মিল (${_meals(report.totalConsumeMeal)}) = ${_money(report.mealRate)} টাকা।',
          style: pw.TextStyle(font: regular, fontSize: 8),
        ),
        pw.Text(
          'Cost of meal = মিল × রেট।  Cook cost = মাসিক বিলের সমান ভাগ।  Total Due = Cost of meal + Cook cost।',
          style: pw.TextStyle(font: regular, fontSize: 8),
        ),
        pw.Text(
          'Deposit Money = মেম্বারের অনুমোদিত বাজার জমা।  Net = Deposit − Total Cost।  ধনাত্মক = পাবে, ঋণাত্মক = দিবে।',
          style: pw.TextStyle(font: regular, fontSize: 8),
        ),
        if (billLines.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'এই মাসের মাসিক বিল — $billLines  (মোট: ${_money(report.totalCookCost)})',
            style: pw.TextStyle(font: regular, fontSize: 8),
          ),
        ],
      ],
    );
  }

  /// Never set [pw.FontWeight.bold] on Bangla text — that forces a Latin
  /// fallback font and garbles Unicode. Pass the real bold TTF instead.
  pw.Widget _cell(
    String text,
    pw.Font font, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    PdfColor? background,
    double fontSize = 8,
  }) {
    return pw.Container(
      color: background,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontFallback: [_regular!, _bold!],
          fontSize: fontSize,
          color: color,
        ),
      ),
    );
  }

  String _money(double n) => n.toStringAsFixed(2);

  String _meals(double n) => n.toStringAsFixed(1);
}
