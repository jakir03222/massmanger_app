import 'package:bangla_pdf/bangla_pdf.dart' as bn;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/mess.dart';
import '../models/monthly_meal_chart.dart';

/// Meal chart PDF only (2nd section / standalone) — Name, then B|L|D columns.
class MonthlyMealChartPdfService {
  static pw.Font? _latinRegular;
  static pw.Font? _latinBold;
  static pw.MemoryImage? _appLogo;

  static const _appName = 'Mass Manager';
  static const _headerYellow = PdfColor.fromInt(0xFFFFEB9C);
  static const _totalsYellow = PdfColor.fromInt(0xFFFFD966);
  static const _totalMealHeader = PdfColor.fromInt(0xFF1F4E79);
  static const _totalMealCol = PdfColor.fromInt(0xFFFCE4D6);
  static const _zebra = PdfColor.fromInt(0xFFF2F2F2);
  static const _line = PdfColor.fromInt(0xFF9E9E9E);
  static const _textDark = PdfColor.fromInt(0xFF212121);
  static const _white = PdfColors.white;
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

  Future<List<pw.Page>> buildPages(
    MonthlyMealChart chart, {
    String? messName,
    String? messLocation,
    String? superAdminName,
  }) async {
    await _ensureAssets();

    final monthTitle =
        'Month Of ${DateFormat('MMMM yyyy').format(chart.month)}';
    final memberCount = chart.members.length;
    final nameSize = memberCount > 10
        ? 5.0
        : memberCount > 7
        ? 5.5
        : 6.5;
    final cellSize = memberCount > 10
        ? 5.5
        : memberCount > 7
        ? 6.0
        : 6.5;

    return [
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(12, 12, 12, 14),
        theme: pw.ThemeData.withFont(base: _latinRegular!, bold: _latinBold!),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: _bnText(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            fontSize: 7,
            color: PdfColors.grey700,
            align: pw.TextAlign.right,
          ),
        ),
        build: (context) => [
          _brandHeader(messName: messName, messLocation: messLocation),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 7),
            color: _headerYellow,
            child: _bnText(monthTitle, bold: true, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          _buildTable(chart, nameSize: nameSize, cellSize: cellSize),
          pw.SizedBox(height: 22),
          _signatureBlock(superAdminName ?? ''),
        ],
      ),
    ];
  }

  pw.Widget _brandHeader({String? messName, String? messLocation}) {
    final name = messName?.trim() ?? '';
    final location = messLocation?.trim() ?? '';
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              width: 32,
              height: 32,
              margin: const pw.EdgeInsets.only(right: 8),
              child: pw.Image(_appLogo!, fit: pw.BoxFit.contain),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _bnText(
                  _appName,
                  bold: true,
                  fontSize: 11,
                  color: _brandGreen,
                  align: pw.TextAlign.left,
                ),
                if (name.isNotEmpty)
                  _bnText(
                    name,
                    bold: true,
                    fontSize: 10,
                    align: pw.TextAlign.left,
                  ),
                if (location.isNotEmpty)
                  _bnText(
                    location,
                    fontSize: 7.5,
                    color: PdfColors.grey700,
                    align: pw.TextAlign.left,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> generate(
    MonthlyMealChart chart, {
    String? messName,
    String? messLocation,
    String? superAdminName,
  }) async {
    final pages = await buildPages(
      chart,
      messName: messName,
      messLocation: messLocation,
      superAdminName: superAdminName,
    );
    final doc = pw.Document();
    for (final page in pages) {
      doc.addPage(page);
    }
    return doc.save();
  }

  Future<void> addToDocument(
    pw.Document doc,
    MonthlyMealChart chart, {
    String? messName,
    String? messLocation,
    String? superAdminName,
  }) async {
    final pages = await buildPages(
      chart,
      messName: messName,
      messLocation: messLocation,
      superAdminName: superAdminName,
    );
    for (final page in pages) {
      doc.addPage(page);
    }
  }

  PdfColor _memberColor(int i) {
    final v = MonthlyMealChart
        .memberColorValues[i % MonthlyMealChart.memberColorValues.length];
    return PdfColor.fromInt(v);
  }

  /// Same user color on every row (optional slight darken on odd rows).
  PdfColor _memberRowColor(int memberIndex, {required bool oddRow}) {
    final base = _memberColor(memberIndex);
    if (!oddRow) return base;
    return PdfColor(
      (base.red * 0.92).clamp(0.0, 1.0),
      (base.green * 0.92).clamp(0.0, 1.0),
      (base.blue * 0.92).clamp(0.0, 1.0),
    );
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 2.5),
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

  /// Excel-style: Name over each member, then B|L|D columns, then day values.
  /// Only used by the meal-chart PDF (2nd section / standalone meal chart).
  pw.Widget _buildTable(
    MonthlyMealChart chart, {
    required double nameSize,
    required double cellSize,
  }) {
    final members = chart.members;
    final memberCount = members.length;
    // Date | B L D × members | Total Meal
    final colCount = 1 + (memberCount * 3) + 1;

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(118),
    };
    for (var c = 1; c < colCount - 1; c++) {
      widths[c] = const pw.FlexColumnWidth(1);
    }
    widths[colCount - 1] = const pw.FixedColumnWidth(34);

    final dateFmt = DateFormat('EEEE, MMMM d, yyyy');
    const bldLabels = ['B', 'L', 'D'];

    // Name row: one block per member spanning B+L+D width (Excel merge look).
    final nameHeader = pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: _line, width: 0.6),
        left: pw.BorderSide(color: _line, width: 0.6),
        right: pw.BorderSide(color: _line, width: 0.6),
        verticalInside: pw.BorderSide(color: _line, width: 0.35),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(118),
        for (var i = 0; i < memberCount; i++)
          i + 1: const pw.FlexColumnWidth(3),
        memberCount + 1: const pw.FixedColumnWidth(34),
      },
      children: [
        pw.TableRow(
          children: [
            _cell('Date', bg: _headerYellow, bold: true, fontSize: 7),
            for (var i = 0; i < memberCount; i++)
              pw.Container(
                color: _memberColor(i),
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 2,
                ),
                alignment: pw.Alignment.center,
                child: _bnText(
                  members[i].name,
                  bold: true,
                  fontSize: nameSize,
                  softWrap: true,
                ),
              ),
            _cell(
              'Total Meal',
              bg: _totalMealHeader,
              bold: true,
              fontSize: 6,
              textColor: _white,
            ),
          ],
        ),
      ],
    );

    final rows = <pw.TableRow>[
      // B | L | D under each member name (separate columns)
      pw.TableRow(
        children: [
          _cell('', bg: _headerYellow, fontSize: 6),
          for (var i = 0; i < memberCount; i++)
            for (final label in bldLabels)
              _cell(
                label,
                bg: _memberColor(i),
                bold: true,
                fontSize: 6.5,
              ),
          _cell(
            'Total',
            bg: _totalMealHeader,
            bold: true,
            fontSize: 6,
            textColor: _white,
          ),
        ],
      ),
    ];

    for (var di = 0; di < chart.days.length; di++) {
      final dayRow = chart.days[di];
      final odd = di.isOdd;
      final cells = <pw.Widget>[
        _cell(
          dateFmt.format(dayRow.day),
          bg: odd ? _zebra : _white,
          fontSize: cellSize,
          align: pw.TextAlign.left,
        ),
      ];
      for (var i = 0; i < memberCount; i++) {
        final meal = dayRow.byUid[members[i].uid] ?? const MealBld();
        final bg = _memberRowColor(i, oddRow: odd);
        cells
          ..add(_cell(
            MonthlyMealChart.formatQty(meal.b),
            bg: bg,
            fontSize: cellSize,
          ))
          ..add(_cell(
            MonthlyMealChart.formatQty(meal.l),
            bg: bg,
            fontSize: cellSize,
          ))
          ..add(_cell(
            MonthlyMealChart.formatQty(meal.d),
            bg: bg,
            fontSize: cellSize,
          ));
      }
      cells.add(
        _cell(
          MonthlyMealChart.formatQty(dayRow.dayTotal),
          bg: _totalMealCol,
          bold: dayRow.dayTotal > 0,
          fontSize: cellSize,
        ),
      );
      rows.add(pw.TableRow(children: cells));
    }

    // B / L / D totals in separate columns
    rows.add(
      pw.TableRow(
        children: [
          _cell('Totals', bg: _totalsYellow, bold: true, fontSize: 7),
          for (var i = 0; i < memberCount; i++) ...[
            _cell(
              MonthlyMealChart.formatQtyOrZero(chart.memberB[i]),
              bg: _memberColor(i),
              bold: true,
              fontSize: cellSize,
            ),
            _cell(
              MonthlyMealChart.formatQtyOrZero(chart.memberL[i]),
              bg: _memberColor(i),
              bold: true,
              fontSize: cellSize,
            ),
            _cell(
              MonthlyMealChart.formatQtyOrZero(chart.memberD[i]),
              bg: _memberColor(i),
              bold: true,
              fontSize: cellSize,
            ),
          ],
          _cell(
            MonthlyMealChart.formatQtyOrZero(chart.grandTotal),
            bg: _totalMealCol,
            bold: true,
            fontSize: cellSize,
          ),
        ],
      ),
    );

    // Person total — one block under each member (spans B+L+D visually)
    final personTotalRow = pw.Table(
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: _line, width: 0.6),
        left: pw.BorderSide(color: _line, width: 0.6),
        right: pw.BorderSide(color: _line, width: 0.6),
        top: pw.BorderSide(color: _line, width: 0.35),
        verticalInside: pw.BorderSide(color: _line, width: 0.35),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(118),
        for (var i = 0; i < memberCount; i++)
          i + 1: const pw.FlexColumnWidth(3),
        memberCount + 1: const pw.FixedColumnWidth(34),
      },
      children: [
        pw.TableRow(
          children: [
            _cell('Total', bg: _totalsYellow, bold: true, fontSize: 7),
            for (var i = 0; i < memberCount; i++)
              _cell(
                MonthlyMealChart.formatQtyOrZero(chart.personTotal(i)),
                bg: _memberColor(i),
                bold: true,
                fontSize: cellSize,
              ),
            _cell(
              MonthlyMealChart.formatQtyOrZero(chart.grandTotal),
              bg: _totalMealCol,
              bold: true,
              fontSize: 7,
            ),
          ],
        ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _bnText(
          'B = Breakfast  ·  L = Lunch  ·  D = Dinner',
          fontSize: 7,
          color: PdfColors.grey700,
        ),
        pw.SizedBox(height: 4),
        nameHeader,
        pw.Table(
          border: const pw.TableBorder(
            left: pw.BorderSide(color: _line, width: 0.6),
            right: pw.BorderSide(color: _line, width: 0.6),
            horizontalInside: pw.BorderSide(color: _line, width: 0.35),
            verticalInside: pw.BorderSide(color: _line, width: 0.35),
          ),
          columnWidths: widths,
          children: rows,
        ),
        personTotalRow,
      ],
    );
  }

  pw.Widget _signatureBlock(String superAdminName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 28),
              pw.Container(width: 160, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 5),
              _bnText('Super Admin Signature', bold: true, fontSize: 9),
              if (superAdminName.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                _bnText(superAdminName, fontSize: 8, color: PdfColors.grey800),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String? resolveSuperAdminName(List<MessMember> members) {
    for (final m in members) {
      if (m.isSuperAdmin) return m.name;
    }
    return null;
  }
}
