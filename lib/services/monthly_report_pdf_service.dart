import 'package:bangla_pdf/bangla_pdf.dart' as bn;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/monthly_meal_chart.dart';
import '../models/monthly_settlement.dart';
import 'monthly_meal_chart_pdf_service.dart';

/// Mess statement PDF — full settlement table matching classic Excel layout
/// + Super Admin signature area.
class MonthlyReportPdfService {
  static pw.Font? _latinRegular;
  static pw.Font? _latinBold;
  static pw.MemoryImage? _appLogo;

  static const _appName = 'Mass Manager';
  static const _peach = PdfColor.fromInt(0xFFFCE4D6);
  static const _netColBg = PdfColor.fromInt(0xFFFCE4EC);
  static const _payableBg = PdfColor.fromInt(0xFFFFC7CE);
  static const _payableText = PdfColor.fromInt(0xFF9C0006);
  static const _receivableBg = PdfColor.fromInt(0xFFC6EFCE);
  static const _receivableText = PdfColor.fromInt(0xFF006100);
  static const _titleRed = PdfColor.fromInt(0xFFC00000);
  static const _border = PdfColors.black;
  static const _textDark = PdfColor.fromInt(0xFF212121);
  static const _zebra = PdfColor.fromInt(0xFFFFF8F5);
  static const _brandGreen = PdfColor.fromInt(0xFF2E7D32);

  Future<void> _ensureAssets() async {
    if (_latinRegular != null && _appLogo != null) return;
    final results = await Future.wait([
      rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
      rootBundle.load('assets/images/app_icon.png'),
    ]);
    _latinRegular = pw.Font.ttf(results[0]);
    _latinBold = pw.Font.ttf(results[1]);
    _appLogo = pw.MemoryImage(results[2].buffer.asUint8List());
  }

  pw.Widget _bnText(
    String text, {
    double fontSize = 8,
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
    bool softWrap = true,
  }) {
    final c = color ?? _textDark;
    final weight = bold ? pw.FontWeight.bold : pw.FontWeight.normal;
    return bn.Text(
      text,
      fontSize: fontSize,
      fontWeight: weight,
      color: c,
      textAlign: align,
      softWrap: softWrap,
      style: pw.TextStyle(
        font: bold ? _latinBold : _latinRegular,
        fontSize: fontSize,
        fontWeight: weight,
        color: c,
      ),
      banglaStyle: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: weight,
        color: c,
      ),
    );
  }

  Future<Uint8List> generate(
    MonthlySettlementReport report, {
    MonthlyMealChart? mealChart,
    bool includeMealChart = true,
  }) async {
    await _ensureAssets();

    final monthName = DateFormat('MMMM yyyy').format(report.month);
    final title = 'Invoice Report for the Month of $monthName.';
    final superAdminName = _superAdminName(report);
    final members = report.members.map((m) => m.member).toList();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(18, 16, 18, 18),
        theme: pw.ThemeData.withFont(
          base: _latinRegular!,
          bold: _latinBold!,
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 6),
          child: _bnText(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            fontSize: 8,
            color: PdfColors.grey700,
          ),
        ),
        build: (context) => [
          _brandHeader(
            messName: report.mess.name,
            messLocation: report.mess.location,
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: _bnText(
              title,
              bold: true,
              fontSize: 15,
              color: _titleRed,
              align: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildStatementTable(report),
          pw.SizedBox(height: 10),
          _buildNote(report),
          pw.SizedBox(height: 28),
          _buildSignatureBlock(superAdminName),
        ],
      ),
    );

    // All-member meal chart (B/L/D) after the statement.
    if (includeMealChart && members.isNotEmpty) {
      try {
        final chart = mealChart ??
            await MonthlyMealChartBuilder().buildForMess(
              messId: report.mess.id,
              members: members,
              month: report.month,
            );
        await MonthlyMealChartPdfService().addToDocument(
          doc,
          chart,
          messName: report.mess.name,
          messLocation: report.mess.location,
          superAdminName: superAdminName,
        );
      } catch (_) {
        // Invoice statement still downloads even if meal chart fails.
      }
    }

    return doc.save();
  }

  pw.Widget _brandHeader({
    required String messName,
    String messLocation = '',
  }) {
    final location = messLocation.trim();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE8F5E9),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _brandGreen, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (_appLogo != null)
            pw.Container(
              width: 36,
              height: 36,
              margin: const pw.EdgeInsets.only(right: 10),
              child: pw.Image(_appLogo!, fit: pw.BoxFit.contain),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _bnText(
                  _appName,
                  bold: true,
                  fontSize: 13,
                  color: _brandGreen,
                ),
                if (messName.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  _bnText(
                    messName.trim(),
                    bold: true,
                    fontSize: 11,
                  ),
                ],
                if (location.isNotEmpty)
                  _bnText(
                    location,
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _superAdminName(MonthlySettlementReport report) {
    for (final row in report.members) {
      if (row.member.isSuperAdmin) return row.member.name;
    }
    final createdBy = report.mess.createdBy;
    if (createdBy != null && createdBy.isNotEmpty) {
      for (final row in report.members) {
        if (row.member.uid == createdBy) return row.member.name;
      }
    }
    return '';
  }

  pw.Widget _buildStatementTable(MonthlySettlementReport report) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.7),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FlexColumnWidth(0.4),
        1: pw.FlexColumnWidth(1.45),
        2: pw.FlexColumnWidth(0.95),
        3: pw.FlexColumnWidth(0.85),
        4: pw.FlexColumnWidth(0.95),
        5: pw.FlexColumnWidth(0.85),
        6: pw.FlexColumnWidth(0.9),
        7: pw.FlexColumnWidth(0.95),
        8: pw.FlexColumnWidth(0.8),
        9: pw.FlexColumnWidth(0.95),
        10: pw.FlexColumnWidth(1.15),
        11: pw.FlexColumnWidth(0.85),
      },
      children: [
        _headerRow(),
        for (var i = 0; i < report.members.length; i++)
          _memberRow(report.members[i], zebra: i.isOdd),
        _totalRow(report),
      ],
    );
  }

  pw.TableRow _headerRow() {
    pw.Widget h(String text) => _cell(
          text,
          bold: true,
          align: pw.TextAlign.center,
          fontSize: 7,
          background: _peach,
          softWrap: true,
        );
    return pw.TableRow(
      children: [
        h('SL'),
        h('Name'),
        h('Consume meal\nfor the month'),
        h('Meal rate\n(TK)'),
        h('Cost of meal'),
        h('Cook cost'),
        h('Total Due'),
        h('Deposit Money'),
        h('Eid Bonus'),
        h('Total Cost'),
        h('Net Payable/\nReceivable'),
        h('Remarks'),
      ],
    );
  }

  pw.TableRow _memberRow(MemberMonthlySettlement row, {required bool zebra}) {
    final net = row.netPayableReceivable;
    final isPayable = net < 0;
    final isReceivable = net > 0;
    final remark = isReceivable
        ? 'Receivable'
        : isPayable
            ? 'Payable'
            : 'Settled';
    final bg = zebra ? _zebra : null;

    return pw.TableRow(
      children: [
        _cell(
          '${row.serial}',
          align: pw.TextAlign.center,
          background: bg,
          softWrap: false,
        ),
        _cell(row.member.name, background: bg, softWrap: false),
        _cell(
          _meals(row.consumeMeal),
          align: pw.TextAlign.center,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.mealRate),
          align: pw.TextAlign.center,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.costOfMeal),
          align: pw.TextAlign.center,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.cookCost),
          align: pw.TextAlign.center,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.totalDue),
          align: pw.TextAlign.center,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.depositMoney),
          align: pw.TextAlign.center,
          background: bg,
          softWrap: false,
        ),
        _cell(
          row.eidBonus == 0 ? '' : _money(row.eidBonus),
          align: pw.TextAlign.center,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.totalCost),
          bold: true,
          align: pw.TextAlign.center,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(net),
          bold: true,
          align: pw.TextAlign.center,
          color: isPayable
              ? _payableText
              : (isReceivable ? _receivableText : _textDark),
          background: isPayable
              ? _payableBg
              : (isReceivable ? _receivableBg : _netColBg),
          softWrap: false,
        ),
        _cell(
          remark,
          bold: true,
          align: pw.TextAlign.center,
          color: isPayable
              ? _payableText
              : (isReceivable ? _receivableText : _textDark),
          background: bg,
          softWrap: false,
          fontSize: 7,
        ),
      ],
    );
  }

  pw.TableRow _totalRow(MonthlySettlementReport report) {
    final net = report.totalNet;
    return pw.TableRow(
      children: [
        _cell('', bold: true, background: _peach),
        _cell(
          'TOTAL',
          bold: true,
          align: pw.TextAlign.center,
          background: _peach,
          fontSize: 8.5,
        ),
        _cell(
          _meals(report.totalConsumeMeal),
          bold: true,
          align: pw.TextAlign.center,
          background: _peach,
          softWrap: false,
        ),
        _cell('', bold: true, background: _peach),
        _cell(
          _money(report.totalCostOfMeal),
          bold: true,
          align: pw.TextAlign.center,
          background: _peach,
          softWrap: false,
        ),
        _cell(
          _money(report.totalCookCost),
          bold: true,
          align: pw.TextAlign.center,
          background: _peach,
          softWrap: false,
        ),
        _cell(
          _money(report.totalDue),
          bold: true,
          align: pw.TextAlign.center,
          background: _peach,
          softWrap: false,
        ),
        _cell(
          _money(report.totalDeposit),
          bold: true,
          align: pw.TextAlign.center,
          background: _peach,
          softWrap: false,
        ),
        _cell(
          report.totalEidBonus == 0 ? '' : _money(report.totalEidBonus),
          bold: true,
          align: pw.TextAlign.center,
          background: _peach,
          softWrap: false,
        ),
        _cell(
          _money(report.totalCost),
          bold: true,
          align: pw.TextAlign.center,
          background: _peach,
          softWrap: false,
        ),
        _cell(
          _money(net),
          bold: true,
          align: pw.TextAlign.center,
          color: net < 0 ? _payableText : (net > 0 ? _receivableText : _textDark),
          background: _peach,
          softWrap: false,
        ),
        _cell('', bold: true, background: _peach),
      ],
    );
  }

  pw.Widget _buildNote(MonthlySettlementReport report) {
    final billLines = report.fixedBills
        .map((b) => '${b.type.label(bn: false)}: ${_money(b.amount)} TK')
        .join('  •  ');

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _bnText('Calculation notes', bold: true, fontSize: 8),
          pw.SizedBox(height: 3),
          _bnText(
            'Meal rate = Total bazaar (${_money(report.totalCostOfMeal)} TK) ÷ Total meals (${_meals(report.totalConsumeMeal)}) = ${_money(report.mealRate)} TK',
            fontSize: 7.5,
          ),
          _bnText(
            'Cost of meal = Meals × Rate  ·  Total Due = Cost of meal + Cook cost  ·  Total Cost = Total Due − Eid Bonus  ·  Net = Deposit − Total Cost',
            fontSize: 7.5,
          ),
          _bnText(
            'Positive Net = Receivable  ·  Negative Net = Payable',
            fontSize: 7.5,
          ),
          if (billLines.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            _bnText(
              'Monthly bills — $billLines  (Cook total: ${_money(report.totalCookCost)} TK)',
              fontSize: 7.5,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSignatureBlock(String superAdminName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _bnText(
                'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
              pw.SizedBox(height: 2),
              _bnText(
                'Mass Manager',
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ],
          ),
        ),
        pw.Container(
          width: 220,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 36),
              pw.Container(
                width: 180,
                height: 1,
                color: _border,
              ),
              pw.SizedBox(height: 6),
              _bnText(
                'Super Admin Signature',
                bold: true,
                fontSize: 9,
                align: pw.TextAlign.center,
              ),
              if (superAdminName.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                _bnText(
                  superAdminName,
                  fontSize: 8,
                  align: pw.TextAlign.center,
                  color: PdfColors.grey800,
                ),
              ],
            ],
          ),
        ),
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
    bool softWrap = true,
  }) {
    return pw.Container(
      color: background,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 5),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : align == pw.TextAlign.right
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
      child: _bnText(
        text,
        bold: bold,
        fontSize: fontSize,
        color: color,
        align: align,
        softWrap: softWrap,
      ),
    );
  }

  String _money(double n) => n.toStringAsFixed(2);

  String _meals(double n) => n.toStringAsFixed(1);
}
