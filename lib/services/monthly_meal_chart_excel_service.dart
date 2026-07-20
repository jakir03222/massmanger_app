import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/mess.dart';
import '../models/monthly_meal_chart.dart';
import '../utils/bn_date_format.dart';

/// Builds a polished, user-friendly month meal chart Excel (সকাল / বিকাল / রাত).
class MonthlyMealChartExcelService {
  MonthlyMealChartExcelService({MonthlyMealChartBuilder? builder})
      : _builder = builder ?? MonthlyMealChartBuilder();

  final MonthlyMealChartBuilder _builder;

  // Brand / table palette
  static final _titleGreen = ExcelColor.fromHexString('FF2E7D32');
  static final _titleGreenDark = ExcelColor.fromHexString('FF1B5E20');
  static final _legendBg = ExcelColor.fromHexString('FFE8F5E9');
  static final _headerYellow = ExcelColor.fromHexString('FFFFF59D');
  static final _totalsGold = ExcelColor.fromHexString('FFFFD54F');
  static final _totalOrange = ExcelColor.fromHexString('FFFFCC80');
  static final _totalOrangeDark = ExcelColor.fromHexString('FFFFB74D');
  static final _zebraGray = ExcelColor.fromHexString('FFF5F5F5');
  static final _white = ExcelColor.white;
  static final _textDark = ExcelColor.fromHexString('FF212121');
  static final _borderGray = ExcelColor.fromHexString('FF9E9E9E');
  static final _borderDark = ExcelColor.fromHexString('FF424242');

  static const _topPadRow = 0;
  static const _titleRow = 1;
  static const _legendRow = 2;
  static const _spacerRow = 3;
  static const _nameHeaderRow = 4;
  static const _bldHeaderRow = 5;
  static const _dataStartRow = 6;

  static final _thinBorder = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: _borderGray,
  );
  static final _mediumBorder = Border(
    borderStyle: BorderStyle.Medium,
    borderColorHex: _borderDark,
  );

  Future<Uint8List> generate({
    required Mess mess,
    required List<MessMember> members,
    required DateTime month,
  }) async {
    final chart = await _builder.buildForMess(
      messId: mess.id,
      members: members,
      month: month,
    );
    return encodeChart(chart, messName: mess.name);
  }

  Uint8List encodeChart(MonthlyMealChart chart, {String? messName}) {
    final excel = Excel.createExcel();
    const sheetName = 'Meal Chart';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    final members = chart.members;
    final memberCount = members.length;
    final lastCol = 1 + (memberCount * 3);
    final dayCount = chart.days.length;
    final totalsRow = _dataStartRow + dayCount;
    final grandRow = totalsRow + 1;
    final bottomPadRow = grandRow + 1;

    // ── Top padding ──────────────────────────────────────────────
    _fillRow(sheet, _topPadRow, lastCol, _padStyle());

    // ── Title ────────────────────────────────────────────────────
    final title = messName != null && messName.trim().isNotEmpty
        ? 'মিল চার্ট — ${messName.trim()} — ${chart.monthLabel}'
        : 'মিল চার্ট — ${chart.monthLabel}';
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: _titleRow),
      CellIndex.indexByColumnRow(columnIndex: lastCol, rowIndex: _titleRow),
      customValue: TextCellValue(title),
    );
    _styleCell(
      sheet,
      0,
      _titleRow,
      _titleStyle(bg: _titleGreen, fontSize: 18),
    );
    sheet.setRowHeight(_titleRow, 34);

    // ── Legend ───────────────────────────────────────────────────
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: _legendRow),
      CellIndex.indexByColumnRow(columnIndex: lastCol, rowIndex: _legendRow),
      customValue: TextCellValue(
        'সকাল  ·  বিকাল  ·  রাত',
      ),
    );
    _styleCell(
      sheet,
      0,
      _legendRow,
      _legendStyle(),
    );
    sheet.setRowHeight(_legendRow, 22);

    // ── Spacer ───────────────────────────────────────────────────
    _fillRow(sheet, _spacerRow, lastCol, _padStyle());
    sheet.setRowHeight(_spacerRow, 8);

    // ── Member name header ─────────────────────────────────────────
    _setText(
      sheet,
      0,
      _nameHeaderRow,
      'তারিখ',
      _columnHeaderStyle(_headerYellow, darkText: true),
    );
    for (var i = 0; i < memberCount; i++) {
      final start = 1 + i * 3;
      final color = _memberExcelColor(i);
      final style = _columnHeaderStyle(color);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: start, rowIndex: _nameHeaderRow),
        CellIndex.indexByColumnRow(
          columnIndex: start + 2,
          rowIndex: _nameHeaderRow,
        ),
        customValue: TextCellValue(members[i].name),
      );
      for (var c = start; c <= start + 2; c++) {
        _styleCell(sheet, c, _nameHeaderRow, style);
      }
    }
    _setText(
      sheet,
      lastCol,
      _nameHeaderRow,
      'মোট মিল',
      _columnHeaderStyle(_totalOrangeDark, darkText: true),
    );
    sheet.setRowHeight(_nameHeaderRow, 26);

    // ── সকাল / বিকাল / রাত sub-header ──────────────────────────────
    _setText(
      sheet,
      0,
      _bldHeaderRow,
      '',
      _columnHeaderStyle(_headerYellow, darkText: true),
    );
    for (var i = 0; i < memberCount; i++) {
      final start = 1 + i * 3;
      final style = _columnHeaderStyle(_memberExcelColor(i), fontSize: 9);
      _setText(sheet, start, _bldHeaderRow, 'সকাল', style);
      _setText(sheet, start + 1, _bldHeaderRow, 'বিকাল', style);
      _setText(sheet, start + 2, _bldHeaderRow, 'রাত', style);
    }
    _setText(
      sheet,
      lastCol,
      _bldHeaderRow,
      'মোট',
      _columnHeaderStyle(_totalOrangeDark, darkText: true),
    );
    sheet.setRowHeight(_bldHeaderRow, 24);

    // ── Daily rows ─────────────────────────────────────────────────
    for (var di = 0; di < dayCount; di++) {
      final rowData = chart.days[di];
      final row = _dataStartRow + di;
      final zebra = di.isEven ? _white : _zebraGray;

      _setText(
        sheet,
        0,
        row,
        formatBnDayLabel(rowData.day),
        _dateStyle(zebra),
      );
      sheet.setRowHeight(row, 21);

      for (var i = 0; i < memberCount; i++) {
        final start = 1 + i * 3;
        final memberBg = _blendMemberWithZebra(i, di.isEven);
        final bld = rowData.byUid[members[i].uid] ?? const MealBld();
        _setQty(sheet, start, row, bld.b, _qtyStyle(memberBg));
        _setQty(sheet, start + 1, row, bld.l, _qtyStyle(memberBg));
        _setQty(sheet, start + 2, row, bld.d, _qtyStyle(memberBg));
      }
      _setQty(
        sheet,
        lastCol,
        row,
        rowData.dayTotal,
        _qtyStyle(_totalOrange, bold: rowData.dayTotal > 0),
      );
    }

    // ── Totals row (B/L/D breakdown) ─────────────────────────────
    _setText(
      sheet,
      0,
      totalsRow,
      'মোট',
      _totalRowStyle(_totalsGold, darkText: true),
    );
    sheet.setRowHeight(totalsRow, 26);
    for (var i = 0; i < memberCount; i++) {
      final start = 1 + i * 3;
      final bg = _memberExcelColor(i);
      final style = _totalRowStyle(bg);
      _setQty(sheet, start, totalsRow, chart.memberB[i], style);
      _setQty(sheet, start + 1, totalsRow, chart.memberL[i], style);
      _setQty(sheet, start + 2, totalsRow, chart.memberD[i], style);
    }
    _setQty(
      sheet,
      lastCol,
      totalsRow,
      chart.grandTotal,
      _totalRowStyle(_totalOrangeDark, darkText: true),
    );

    // ── Grand total per person ─────────────────────────────────────
    _setText(
      sheet,
      0,
      grandRow,
      'সর্বমোট',
      _totalRowStyle(_titleGreen, whiteText: true),
    );
    sheet.setRowHeight(grandRow, 28);
    for (var i = 0; i < memberCount; i++) {
      final start = 1 + i * 3;
      final personTotal = chart.personTotal(i);
      final style = _totalRowStyle(_titleGreenDark, whiteText: true);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: start, rowIndex: grandRow),
        CellIndex.indexByColumnRow(columnIndex: start + 2, rowIndex: grandRow),
        customValue: _qtyValue(personTotal),
      );
      for (var c = start; c <= start + 2; c++) {
        _styleCell(sheet, c, grandRow, style);
      }
    }
    _setQty(
      sheet,
      lastCol,
      grandRow,
      chart.grandTotal,
      _totalRowStyle(_titleGreen, whiteText: true, fontSize: 12),
    );

    // ── Bottom padding ─────────────────────────────────────────────
    _fillRow(sheet, bottomPadRow, lastCol, _padStyle());
    sheet.setRowHeight(bottomPadRow, 10);

    // ── Column widths (breathing room) ─────────────────────────────
    sheet.setColumnWidth(0, 36);
    for (var c = 1; c < lastCol; c++) {
      sheet.setColumnWidth(c, 9);
    }
    sheet.setColumnWidth(lastCol, 14);

    // Outer medium border around the whole table block
    _applyOuterBorder(sheet, lastCol, _nameHeaderRow, grandRow);

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to encode meal chart Excel');
    }
    return Uint8List.fromList(bytes);
  }

  void _applyOuterBorder(
    Sheet sheet,
    int lastCol,
    int topRow,
    int bottomRow,
  ) {
    for (var r = topRow; r <= bottomRow; r++) {
      for (var c = 0; c <= lastCol; c++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
        final existing = cell.cellStyle ?? CellStyle();
        cell.cellStyle = existing.copyWith(
          leftBorderVal: c == 0 ? _mediumBorder : existing.leftBorder,
          rightBorderVal: c == lastCol ? _mediumBorder : existing.rightBorder,
          topBorderVal: r == topRow ? _mediumBorder : existing.topBorder,
          bottomBorderVal:
              r == bottomRow ? _mediumBorder : existing.bottomBorder,
        );
      }
    }
  }

  void _fillRow(Sheet sheet, int row, int lastCol, CellStyle style) {
    for (var c = 0; c <= lastCol; c++) {
      _styleCell(sheet, c, row, style);
    }
  }

  CellStyle _padStyle() => CellStyle(
        backgroundColorHex: _white,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
      );

  CellStyle _titleStyle({required ExcelColor bg, int fontSize = 16}) =>
      CellStyle(
        bold: true,
        fontSize: fontSize,
        fontColorHex: _white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: bg,
        leftBorder: _mediumBorder,
        rightBorder: _mediumBorder,
        topBorder: _mediumBorder,
        bottomBorder: _mediumBorder,
        textWrapping: TextWrapping.WrapText,
      );

  CellStyle _legendStyle() => CellStyle(
        fontSize: 10,
        fontColorHex: _titleGreenDark,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: _legendBg,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
      );

  CellStyle _columnHeaderStyle(
    ExcelColor bg, {
    bool darkText = false,
    int fontSize = 11,
  }) =>
      CellStyle(
        bold: true,
        fontSize: fontSize,
        fontColorHex: darkText ? _textDark : _textDark,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: bg,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
        textWrapping: TextWrapping.WrapText,
      );

  CellStyle _dateStyle(ExcelColor bg) => CellStyle(
        fontSize: 10,
        fontColorHex: _textDark,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: bg,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
        textWrapping: TextWrapping.WrapText,
      );

  CellStyle _qtyStyle(ExcelColor bg, {bool bold = false}) => CellStyle(
        bold: bold,
        fontSize: 10,
        fontColorHex: _textDark,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: bg,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
      );

  CellStyle _totalRowStyle(
    ExcelColor bg, {
    bool darkText = false,
    bool whiteText = false,
    int fontSize = 11,
  }) =>
      CellStyle(
        bold: true,
        fontSize: fontSize,
        fontColorHex: whiteText
            ? _white
            : (darkText ? _textDark : _textDark),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: bg,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _mediumBorder,
        bottomBorder: _thinBorder,
        textWrapping: TextWrapping.WrapText,
      );

  ExcelColor _memberExcelColor(int index) {
    final value = MonthlyMealChart.memberColorValues[
        index % MonthlyMealChart.memberColorValues.length];
    final hex = value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return ExcelColor.fromHexString(hex);
  }

  ExcelColor _blendMemberWithZebra(int memberIndex, bool evenRow) {
    if (evenRow) return _memberExcelColor(memberIndex);
    // Slightly muted on zebra rows for readability
    return _zebraGray;
  }

  void _styleCell(Sheet sheet, int col, int row, CellStyle style) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = style;
  }

  void _setText(Sheet sheet, int col, int row, String text, CellStyle style) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = style;
  }

  void _setQty(Sheet sheet, int col, int row, double qty, CellStyle style) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (qty > 0) {
      cell.value = _qtyValue(qty);
    } else {
      cell.value = TextCellValue('');
    }
    cell.cellStyle = style;
  }

  CellValue _qtyValue(double qty) {
    if (qty == 0) return TextCellValue('0');
    if (qty % 1 == 0) return IntCellValue(qty.toInt());
    return DoubleCellValue(qty);
  }
}
