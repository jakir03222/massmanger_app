import 'package:bangla_pdf/bangla_pdf.dart' as bn;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/monthly_settlement.dart';
import '../utils/bn_date_format.dart';

/// Smart monthly settlement PDF — Bangla via [bangla_pdf] (Kalpurush).
class MonthlyReportPdfService {
  static pw.Font? _latinRegular;
  static pw.Font? _latinBold;

  static const _green = PdfColor.fromInt(0xFF2E7D32);
  static const _greenDark = PdfColor.fromInt(0xFF1B5E20);
  static const _greenSoft = PdfColor.fromInt(0xFFE8F5E9);
  static const _headerBg = PdfColor.fromInt(0xFFFFF59D);
  static const _totalBg = PdfColor.fromInt(0xFFFFD54F);
  static const _zebra = PdfColor.fromInt(0xFFF5F5F5);
  static const _payableBg = PdfColor.fromInt(0xFFFCE4E4);
  static const _receivableBg = PdfColor.fromInt(0xFFE6F4EA);
  static const _border = PdfColor.fromInt(0xFF9E9E9E);
  static const _textDark = PdfColor.fromInt(0xFF212121);

  Future<void> _ensureFonts() async {
    if (_latinRegular != null) return;
    final results = await Future.wait([
      rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    ]);
    _latinRegular = pw.Font.ttf(results[0]);
    _latinBold = pw.Font.ttf(results[1]);
  }

  /// bangla_pdf Text — Kalpurush for Bangla, Noto Sans for English/digits.
  pw.Widget _bnText(
    String text, {
    double fontSize = 8,
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
    bool? softWrap,
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

  Future<Uint8List> generate(MonthlySettlementReport report) async {
    await _ensureFonts();

    final doc = pw.Document();
    final monthLabel = formatBnMonthTitle(report.month);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(18, 18, 18, 20),
        theme: pw.ThemeData.withFont(
          base: _latinRegular!,
          bold: _latinBold!,
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _greenSoft,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: _green, width: 0.6),
                  ),
                  child: _bnText(
                    'মাসিক হিসাব — ${report.mess.name} — $monthLabel',
                    bold: true,
                    fontSize: 9,
                    color: _greenDark,
                  ),
                ),
              ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 6),
          child: _bnText(
            'পৃষ্ঠা ${context.pageNumber}/${context.pagesCount}',
            fontSize: 8,
            color: PdfColors.grey700,
          ),
        ),
        build: (context) => [
          _buildTitle(report, monthLabel),
          pw.SizedBox(height: 10),
          _buildSummaryStrip(report),
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
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _green,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _greenDark, width: 1.2),
      ),
      child: pw.Column(
        children: [
          _bnText(
            'মাসিক হিসাব',
            bold: true,
            fontSize: 16,
            color: PdfColors.white,
            align: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
          _bnText(
            '${report.mess.name} — $monthLabel',
            bold: true,
            fontSize: 12,
            color: PdfColors.white,
            align: pw.TextAlign.center,
          ),
          if (report.mess.location.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            _bnText(
              report.mess.location,
              fontSize: 9,
              color: PdfColors.white,
              align: pw.TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSummaryStrip(MonthlySettlementReport report) {
    pw.Widget chip(String label, String value) {
      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: pw.BoxDecoration(
            color: _greenSoft,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _border, width: 0.5),
          ),
          child: pw.Column(
            children: [
              _bnText(
                label,
                fontSize: 7,
                color: _greenDark,
                align: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              _bnText(
                value,
                bold: true,
                fontSize: 10,
                color: _greenDark,
                align: pw.TextAlign.center,
                softWrap: false,
              ),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        chip('মোট মিল', _meals(report.totalConsumeMeal)),
        chip('মিল রেট', '${_money(report.mealRate)} ৳'),
        chip('মোট বাজার', '${_money(report.totalDeposit)} ৳'),
        chip('মাসিক বিল', '${_money(report.totalCookCost)} ৳'),
        chip('নেট', '${_money(report.totalNet)} ৳'),
      ],
    );
  }

  pw.Widget _buildStatementTable(MonthlySettlementReport report) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.7),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.45),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(0.85),
        3: const pw.FlexColumnWidth(0.85),
        4: const pw.FlexColumnWidth(0.95),
        5: const pw.FlexColumnWidth(0.85),
        6: const pw.FlexColumnWidth(0.9),
        7: const pw.FlexColumnWidth(0.95),
        8: const pw.FlexColumnWidth(0.8),
        9: const pw.FlexColumnWidth(0.95),
        10: const pw.FlexColumnWidth(1.15),
        11: const pw.FlexColumnWidth(0.9),
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
          background: _headerBg,
          softWrap: false,
        );
    return pw.TableRow(
      children: [
        h('ক্রম'),
        h('নাম'),
        h('মোট মিল'),
        h('মিল রেট'),
        h('খাবার খরচ'),
        h('কুক খরচ'),
        h('মোট বকেয়া'),
        h('জমা টাকা'),
        h('ঈদ বোনাস'),
        h('মোট খরচ'),
        h('নেট পাবে/দিবে'),
        h('মন্তব্য'),
      ],
    );
  }

  pw.TableRow _memberRow(MemberMonthlySettlement row, {required bool zebra}) {
    final net = row.netPayableReceivable;
    final isPayable = net < 0;
    final remark = net > 0
        ? 'পাবে'
        : net < 0
            ? 'দিবে'
            : 'সমান';
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
          align: pw.TextAlign.right,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.costOfMeal),
          align: pw.TextAlign.right,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.cookCost),
          align: pw.TextAlign.right,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.totalDue),
          align: pw.TextAlign.right,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.depositMoney),
          align: pw.TextAlign.right,
          background: bg,
          softWrap: false,
        ),
        _cell(
          row.eidBonus == 0 ? '—' : _money(row.eidBonus),
          align: pw.TextAlign.right,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(row.totalCost),
          bold: true,
          align: pw.TextAlign.right,
          background: bg,
          softWrap: false,
        ),
        _cell(
          _money(net),
          bold: true,
          align: pw.TextAlign.right,
          color: isPayable ? PdfColors.red800 : PdfColors.green800,
          background: isPayable ? _payableBg : _receivableBg,
          softWrap: false,
        ),
        _cell(
          remark,
          bold: true,
          align: pw.TextAlign.center,
          color: isPayable
              ? PdfColors.red800
              : (net > 0 ? PdfColors.green800 : _textDark),
          background: bg,
          softWrap: false,
        ),
      ],
    );
  }

  pw.TableRow _totalRow(MonthlySettlementReport report) {
    final net = report.totalNet;
    return pw.TableRow(
      children: [
        _cell('', bold: true, background: _totalBg),
        _cell(
          'সর্বমোট',
          bold: true,
          align: pw.TextAlign.center,
          background: _totalBg,
          fontSize: 8.5,
        ),
        _cell(
          _meals(report.totalConsumeMeal),
          bold: true,
          align: pw.TextAlign.center,
          background: _totalBg,
          softWrap: false,
        ),
        _cell('', bold: true, background: _totalBg),
        _cell(
          _money(report.totalCostOfMeal),
          bold: true,
          align: pw.TextAlign.right,
          background: _totalBg,
          softWrap: false,
        ),
        _cell(
          _money(report.totalCookCost),
          bold: true,
          align: pw.TextAlign.right,
          background: _totalBg,
          softWrap: false,
        ),
        _cell(
          _money(report.totalDue),
          bold: true,
          align: pw.TextAlign.right,
          background: _totalBg,
          softWrap: false,
        ),
        _cell(
          _money(report.totalDeposit),
          bold: true,
          align: pw.TextAlign.right,
          background: _totalBg,
          softWrap: false,
        ),
        _cell(
          report.totalEidBonus == 0 ? '—' : _money(report.totalEidBonus),
          bold: true,
          align: pw.TextAlign.right,
          background: _totalBg,
          softWrap: false,
        ),
        _cell(
          _money(report.totalCost),
          bold: true,
          align: pw.TextAlign.right,
          background: _totalBg,
          softWrap: false,
        ),
        _cell(
          _money(net),
          bold: true,
          align: pw.TextAlign.right,
          color: net < 0 ? PdfColors.red800 : PdfColors.green800,
          background: _totalBg,
          softWrap: false,
        ),
        _cell('', bold: true, background: _totalBg),
      ],
    );
  }

  pw.Widget _buildNote(MonthlySettlementReport report) {
    final billLines = report.fixedBills
        .map((b) => '${b.type.bnLabel}: ${_money(b.amount)} ৳')
        .join('  •  ');

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _greenSoft,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _bnText(
            'হিসাবের নিয়ম',
            bold: true,
            fontSize: 9,
            color: _greenDark,
          ),
          pw.SizedBox(height: 4),
          _bnText(
            'মিল রেট = মোট বাজার (${_money(report.totalCostOfMeal)} ৳) ÷ মোট মিল (${_meals(report.totalConsumeMeal)}) = ${_money(report.mealRate)} ৳',
            fontSize: 8,
          ),
          _bnText(
            'খাবার খরচ = মিল × রেট  ·  কুক খরচ = মাসিক বিলের সমান ভাগ (ঈদ বোনাস ছাড়া)  ·  মোট বকেয়া = খাবার খরচ + কুক খরচ',
            fontSize: 8,
          ),
          _bnText(
            'জমা টাকা = অনুমোদিত বাজার জমা  ·  নেট = জমা − মোট খরচ  ·  ধনাত্মক = পাবে, ঋণাত্মক = দিবে',
            fontSize: 8,
          ),
          if (billLines.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _bnText(
              'এই মাসের মাসিক বিল — $billLines  (মোট: ${_money(report.totalCookCost)} ৳)',
              fontSize: 8,
            ),
          ],
        ],
      ),
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

  String _meals(double n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
}
