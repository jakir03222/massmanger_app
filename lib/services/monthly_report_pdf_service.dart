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

  static pw.Font? _latinRegular;
  static pw.Font? _latinBold;
  static pw.Font? _bnRegular;
  static pw.Font? _bnBold;

  /// Latin (Noto Sans) + Bangla (Noto Sans Bengali) so mixed text
  /// doesn't fall back to Helvetica tofu boxes.
  Future<void> _ensureFonts() async {
    if (_latinRegular != null) return;
    final results = await Future.wait([
      rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
      rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf'),
      rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf'),
    ]);
    _latinRegular = pw.Font.ttf(results[0]);
    _latinBold = pw.Font.ttf(results[1]);
    _bnRegular = pw.Font.ttf(results[2]);
    _bnBold = pw.Font.ttf(results[3]);
  }

  List<pw.Font> get _fallback => [_bnRegular!, _bnBold!, _latinRegular!, _latinBold!];

  pw.TextStyle _style({
    required bool bold,
    double fontSize = 8,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: bold ? _latinBold : _latinRegular,
      fontFallback: _fallback,
      fontSize: fontSize,
      color: color,
    );
  }

  Future<Uint8List> generate(MonthlySettlementReport report) async {
    await _ensureFonts();

    final doc = pw.Document();
    final monthLabel =
        '${_enMonths[report.month.month - 1]} ${report.month.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        theme: pw.ThemeData.withFont(
          base: _latinRegular!,
          bold: _latinBold!,
          fontFallback: _fallback,
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  '${report.mess.name} — $monthLabel',
                  style: _style(bold: true, fontSize: 10),
                ),
              ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: _style(bold: false, fontSize: 8),
          ),
        ),
        build: (context) => [
          _buildTitle(report, monthLabel),
          pw.SizedBox(height: 10),
          _buildStatementTable(report),
          pw.SizedBox(height: 12),
          _buildNote(report),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildTitle(
    MonthlySettlementReport report,
    String monthLabel,
  ) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            '${report.mess.name} — Mess Statement for the Month of $monthLabel',
            style: _style(bold: true, fontSize: 14, color: PdfColors.red800),
          ),
        ),
        if (report.mess.location.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Center(
            child: pw.Text(
              report.mess.location,
              style: _style(bold: false, fontSize: 9),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildStatementTable(MonthlySettlementReport report) {
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
        _headerRow(),
        ...report.members.map(_memberRow),
        _totalRow(report),
      ],
    );
  }

  pw.TableRow _headerRow() {
    pw.Widget h(String text) => _cell(
          text,
          bold: true,
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

  pw.TableRow _memberRow(MemberMonthlySettlement row) {
    final net = row.netPayableReceivable;
    final isPayable = net < 0;
    return pw.TableRow(
      children: [
        _cell('${row.serial}', align: pw.TextAlign.center),
        _cell(row.member.name),
        _cell(_meals(row.consumeMeal), align: pw.TextAlign.center),
        _cell(_money(row.mealRate), align: pw.TextAlign.right),
        _cell(_money(row.costOfMeal), align: pw.TextAlign.right),
        _cell(_money(row.cookCost), align: pw.TextAlign.right),
        _cell(_money(row.totalDue), align: pw.TextAlign.right),
        _cell(_money(row.depositMoney), align: pw.TextAlign.right),
        _cell(
          row.eidBonus == 0 ? '' : _money(row.eidBonus),
          align: pw.TextAlign.right,
        ),
        _cell(_money(row.totalCost), bold: true, align: pw.TextAlign.right),
        _cell(
          _money(net),
          bold: true,
          align: pw.TextAlign.right,
          color: isPayable ? PdfColors.red800 : PdfColors.green800,
          background: isPayable
              ? const PdfColor.fromInt(0xFFFCE4E4)
              : const PdfColor.fromInt(0xFFE6F4EA),
        ),
        _cell(''),
      ],
    );
  }

  pw.TableRow _totalRow(MonthlySettlementReport report) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFCE5CD)),
      children: [
        _cell('', bold: true),
        _cell('Total', bold: true, align: pw.TextAlign.center),
        _cell(
          _meals(report.totalConsumeMeal),
          bold: true,
          align: pw.TextAlign.center,
        ),
        _cell('', bold: true),
        _cell(
          _money(report.totalCostOfMeal),
          bold: true,
          align: pw.TextAlign.right,
        ),
        _cell(
          _money(report.totalCookCost),
          bold: true,
          align: pw.TextAlign.right,
        ),
        _cell(_money(report.totalDue), bold: true, align: pw.TextAlign.right),
        _cell(
          _money(report.totalDeposit),
          bold: true,
          align: pw.TextAlign.right,
        ),
        _cell(
          report.totalEidBonus == 0 ? '' : _money(report.totalEidBonus),
          bold: true,
          align: pw.TextAlign.right,
        ),
        _cell(_money(report.totalCost), bold: true, align: pw.TextAlign.right),
        _cell(
          _money(report.totalNet),
          bold: true,
          align: pw.TextAlign.right,
          color: report.totalNet < 0 ? PdfColors.red800 : PdfColors.green800,
        ),
        _cell('', bold: true),
      ],
    );
  }

  pw.Widget _buildNote(MonthlySettlementReport report) {
    final billLines = report.fixedBills
        .map((b) => '${b.type.bnLabel}: ${_money(b.amount)}')
        .join('  •  ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'হিসাবের নিয়ম (Calculation)',
          style: _style(bold: true, fontSize: 9),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Meal rate = মোট বাজার (${_money(report.totalCostOfMeal)}) ÷ মোট মিল (${_meals(report.totalConsumeMeal)}) = ${_money(report.mealRate)} টাকা।',
          style: _style(bold: false, fontSize: 8),
        ),
        pw.Text(
          'Cost of meal = মিল × রেট।  Cook cost = মাসিক বিলের সমান ভাগ (ঈদ বোনাস ছাড়া)।  Total Due = Cost of meal + Cook cost।',
          style: _style(bold: false, fontSize: 8),
        ),
        pw.Text(
          'Deposit Money = মেম্বারের অনুমোদিত বাজার জমা।  Eid Bonus = ঈদ বোনাস বিলের সমান ভাগ।  Net = Deposit − (Total Due − Eid Bonus)।  ধনাত্মক = পাবে, ঋণাত্মক = দিবে।',
          style: _style(bold: false, fontSize: 8),
        ),
        if (billLines.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'এই মাসের মাসিক বিল — $billLines  (মোট: ${_money(report.totalCookCost)})',
            style: _style(bold: false, fontSize: 8),
          ),
        ],
      ],
    );
  }

  pw.Widget _cell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    PdfColor? background,
    bool bold = false,
    double fontSize = 8,
  }) {
    return pw.Container(
      color: background,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: _style(bold: bold, fontSize: fontSize, color: color),
      ),
    );
  }

  String _money(double n) => n.toStringAsFixed(2);

  String _meals(double n) => n.toStringAsFixed(1);
}
