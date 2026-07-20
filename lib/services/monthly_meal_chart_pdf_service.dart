import 'package:bangla_pdf/bangla_pdf.dart' as bn;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/monthly_meal_chart.dart';
import '../utils/bn_date_format.dart';

/// Smart meal chart PDF (সকাল / বিকাল / রাত) via bangla_pdf.
class MonthlyMealChartPdfService {
  static pw.Font? _latinRegular;
  static pw.Font? _latinBold;

  static const _green = PdfColor.fromInt(0xFF2E7D32);
  static const _greenDark = PdfColor.fromInt(0xFF1B5E20);
  static const _greenSoft = PdfColor.fromInt(0xFFE8F5E9);
  static const _headerYellow = PdfColor.fromInt(0xFFFFF59D);
  static const _totalsGold = PdfColor.fromInt(0xFFFFD54F);
  static const _totalOrange = PdfColor.fromInt(0xFFFFCC80);
  static const _zebra = PdfColor.fromInt(0xFFF5F5F5);
  static const _border = PdfColor.fromInt(0xFF9E9E9E);
  static const _textDark = PdfColor.fromInt(0xFF212121);
  static const _white = PdfColors.white;

  Future<void> _ensureFonts() async {
    if (_latinRegular != null) return;
    final results = await Future.wait([
      rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    ]);
    _latinRegular = pw.Font.ttf(results[0]);
    _latinBold = pw.Font.ttf(results[1]);
  }

  pw.Widget _bnText(
    String text, {
    double fontSize = 7,
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.center,
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

  Future<Uint8List> generate(
    MonthlyMealChart chart, {
    String? messName,
  }) async {
    await _ensureFonts();

    final members = chart.members;
    final memberCount = members.length;
    final colCount = 1 + memberCount * 3 + 1;

    final doc = pw.Document();
    final title = messName != null && messName.trim().isNotEmpty
        ? 'মিল চার্ট — ${messName.trim()} — ${chart.monthLabel}'
        : 'মিল চার্ট — ${chart.monthLabel}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(14, 14, 14, 16),
        theme: pw.ThemeData.withFont(
          base: _latinRegular!,
          bold: _latinBold!,
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _greenSoft,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: _green, width: 0.5),
                  ),
                  child: _bnText(
                    title,
                    bold: true,
                    fontSize: 8,
                    color: _greenDark,
                    align: pw.TextAlign.left,
                  ),
                ),
              ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: _bnText(
            'পৃষ্ঠা ${context.pageNumber}/${context.pagesCount}',
            fontSize: 7,
            color: PdfColors.grey700,
            align: pw.TextAlign.right,
          ),
        ),
        build: (context) => [
          _titleBanner(title),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: pw.BoxDecoration(
              color: _greenSoft,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: _border, width: 0.5),
            ),
            child: _bnText(
              'সকাল  ·  বিকাল  ·  রাত',
              bold: true,
              fontSize: 8,
              color: _greenDark,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildTable(chart, colCount),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _titleBanner(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _green,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _greenDark, width: 1.1),
      ),
      child: _bnText(
        title,
        bold: true,
        fontSize: 13,
        color: _white,
      ),
    );
  }

  PdfColor _memberColor(int i) {
    final v = MonthlyMealChart.memberColorValues[
        i % MonthlyMealChart.memberColorValues.length];
    return PdfColor.fromInt(v);
  }

  pw.Widget _cell(
    String text, {
    PdfColor? bg,
    bool bold = false,
    double fontSize = 6.5,
    pw.TextAlign align = pw.TextAlign.center,
    PdfColor? textColor,
  }) {
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 1.5, vertical: 3),
      alignment: align == pw.TextAlign.left
          ? pw.Alignment.centerLeft
          : pw.Alignment.center,
      child: _bnText(
        text,
        bold: bold,
        fontSize: fontSize,
        align: align,
        softWrap: false,
        color: textColor,
      ),
    );
  }

  pw.Widget _buildTable(MonthlyMealChart chart, int colCount) {
    final members = chart.members;
    final memberCount = members.length;

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(78),
    };
    for (var c = 1; c < colCount - 1; c++) {
      widths[c] = const pw.FlexColumnWidth(1);
    }
    widths[colCount - 1] = const pw.FixedColumnWidth(28);

    final rows = <pw.TableRow>[
      // Member names — name in first of 3 cols
      pw.TableRow(
        children: [
          _cell('তারিখ', bg: _headerYellow, bold: true, fontSize: 7),
          for (var i = 0; i < memberCount; i++) ...[
            _cell(
              members[i].name,
              bg: _memberColor(i),
              bold: true,
              fontSize: 6,
            ),
            _cell('', bg: _memberColor(i)),
            _cell('', bg: _memberColor(i)),
          ],
          _cell('মোট', bg: _totalOrange, bold: true, fontSize: 7),
        ],
      ),
      // সকাল বিকাল রাত
      pw.TableRow(
        children: [
          _cell('', bg: _headerYellow),
          for (var i = 0; i < memberCount; i++) ...[
            _cell('সকাল', bg: _memberColor(i), bold: true, fontSize: 5.5),
            _cell('বিকাল', bg: _memberColor(i), bold: true, fontSize: 5.5),
            _cell('রাত', bg: _memberColor(i), bold: true, fontSize: 5.5),
          ],
          _cell('মিল', bg: _totalOrange, bold: true, fontSize: 6),
        ],
      ),
    ];

    for (var di = 0; di < chart.days.length; di++) {
      final dayRow = chart.days[di];
      final zebra = di.isOdd;
      final dateBg = zebra ? _zebra : _white;
      final cells = <pw.Widget>[
        _cell(
          formatBnDayShort(dayRow.day),
          bg: dateBg,
          fontSize: 6,
          align: pw.TextAlign.left,
        ),
      ];
      for (var i = 0; i < memberCount; i++) {
        final bld = dayRow.byUid[members[i].uid] ?? const MealBld();
        final bg = zebra ? _zebra : _memberColor(i);
        cells.add(_cell(MonthlyMealChart.formatQty(bld.b), bg: bg));
        cells.add(_cell(MonthlyMealChart.formatQty(bld.l), bg: bg));
        cells.add(_cell(MonthlyMealChart.formatQty(bld.d), bg: bg));
      }
      cells.add(
        _cell(
          MonthlyMealChart.formatQty(dayRow.dayTotal),
          bg: _totalOrange,
          bold: dayRow.dayTotal > 0,
        ),
      );
      rows.add(pw.TableRow(children: cells));
    }

    // Column totals
    rows.add(
      pw.TableRow(
        children: [
          _cell('মোট', bg: _totalsGold, bold: true, fontSize: 7),
          for (var i = 0; i < memberCount; i++) ...[
            _cell(
              MonthlyMealChart.formatQtyOrZero(chart.memberB[i]),
              bg: _memberColor(i),
              bold: true,
            ),
            _cell(
              MonthlyMealChart.formatQtyOrZero(chart.memberL[i]),
              bg: _memberColor(i),
              bold: true,
            ),
            _cell(
              MonthlyMealChart.formatQtyOrZero(chart.memberD[i]),
              bg: _memberColor(i),
              bold: true,
            ),
          ],
          _cell(
            MonthlyMealChart.formatQtyOrZero(chart.grandTotal),
            bg: _totalOrange,
            bold: true,
          ),
        ],
      ),
    );

    // Person totals
    rows.add(
      pw.TableRow(
        children: [
          _cell(
            'সর্বমোট',
            bg: _green,
            bold: true,
            fontSize: 7,
            textColor: _white,
          ),
          for (var i = 0; i < memberCount; i++) ...[
            _cell(
              MonthlyMealChart.formatQtyOrZero(chart.personTotal(i)),
              bg: _greenDark,
              bold: true,
              textColor: _white,
            ),
            _cell('', bg: _greenDark),
            _cell('', bg: _greenDark),
          ],
          _cell(
            MonthlyMealChart.formatQtyOrZero(chart.grandTotal),
            bg: _green,
            bold: true,
            textColor: _white,
          ),
        ],
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: widths,
      children: rows,
    );
  }
}
