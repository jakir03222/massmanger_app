import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/monthly_meal_chart.dart';
import '../theme/app_colors.dart';

/// Excel-like scrollable meal chart sheet for in-app viewing.
class MealChartSheetView extends StatelessWidget {
  const MealChartSheetView({super.key, required this.chart, this.messName});

  final MonthlyMealChart chart;
  final String? messName;

  static const _dateWidth = 168.0;
  static const _bldWidth = 44.0;
  static const _totalWidth = 56.0;
  static const _nameRowHeight = 36.0;
  static const _bldRowHeight = 28.0;
  static const _rowHeight = 30.0;

  static const _titleGreen = Color(0xFF2E7D32);
  static const _titleGreenDark = Color(0xFF1B5E20);
  static const _legendBg = Color(0xFFE8F5E9);
  static const _headerYellow = Color(0xFFFFF59D);
  static const _totalsGold = Color(0xFFFFD54F);
  static const _totalOrange = Color(0xFFFFCC80);
  static const _totalOrangeDark = Color(0xFFFFB74D);
  static const _zebraGray = Color(0xFFF5F5F5);
  static const _borderColor = Color(0xFF9E9E9E);

  Color _memberColor(int i) => Color(
        MonthlyMealChart.memberColorValues[
            i % MonthlyMealChart.memberColorValues.length],
      );

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final members = chart.members;
    final title = s.mealChartTitle(
      s.monthLabel(chart.month),
      messName: messName,
    );

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: _titleGreen,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _titleGreenDark, width: 1.2),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: appFont(
                context: context,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.card,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: _legendBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _borderColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              s.morningEveningNight,
              textAlign: TextAlign.center,
              style: appFont(
                context: context,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _titleGreenDark,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: _borderColor, width: 1.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _dateWidth,
                          child: Column(
                            children: [
                              _cell(
                                context,
                                s.date,
                                height: _nameRowHeight,
                                bg: _headerYellow,
                                bold: true,
                              ),
                              _cell(
                                context,
                                '',
                                height: _bldRowHeight,
                                bg: _headerYellow,
                                bold: true,
                              ),
                              for (var di = 0; di < chart.days.length; di++)
                                _cell(
                                  context,
                                  s.formatDate(chart.days[di].day),
                                  height: _rowHeight,
                                  bg: di.isEven ? Colors.white : _zebraGray,
                                  align: TextAlign.left,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              _cell(
                                context,
                                s.total,
                                height: _rowHeight,
                                bg: _totalsGold,
                                bold: true,
                              ),
                              _cell(
                                context,
                                s.grandTotal,
                                height: _rowHeight,
                                bg: _titleGreen,
                                bold: true,
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    for (var i = 0; i < members.length; i++)
                                      _cell(
                                        context,
                                        members[i].name,
                                        width: _bldWidth * 3,
                                        height: _nameRowHeight,
                                        bg: _memberColor(i),
                                        bold: true,
                                        fontSize: 11,
                                      ),
                                    _cell(
                                      context,
                                      s.totalMeals,
                                      width: _totalWidth,
                                      height: _nameRowHeight,
                                      bg: _totalOrangeDark,
                                      bold: true,
                                      fontSize: 10,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    for (var i = 0; i < members.length; i++) ...[
                                      _cell(
                                        context,
                                        s.morning,
                                        width: _bldWidth,
                                        height: _bldRowHeight,
                                        bg: _memberColor(i),
                                        bold: true,
                                        fontSize: 10,
                                      ),
                                      _cell(
                                        context,
                                        s.evening,
                                        width: _bldWidth,
                                        height: _bldRowHeight,
                                        bg: _memberColor(i),
                                        bold: true,
                                        fontSize: 10,
                                      ),
                                      _cell(
                                        context,
                                        s.night,
                                        width: _bldWidth,
                                        height: _bldRowHeight,
                                        bg: _memberColor(i),
                                        bold: true,
                                        fontSize: 10,
                                      ),
                                    ],
                                    _cell(
                                      context,
                                      s.total,
                                      width: _totalWidth,
                                      height: _bldRowHeight,
                                      bg: _totalOrangeDark,
                                      bold: true,
                                      fontSize: 10,
                                    ),
                                  ],
                                ),
                                for (var di = 0; di < chart.days.length; di++)
                                  Builder(builder: (_) {
                                    final row = chart.days[di];
                                    return Row(
                                      children: [
                                        for (var i = 0;
                                            i < members.length;
                                            i++) ...[
                                          Builder(builder: (_) {
                                            final bld =
                                                row.byUid[members[i].uid] ??
                                                    const MealBld();
                                            final bg = di.isEven
                                                ? _memberColor(i)
                                                : _zebraGray;
                                            return Row(
                                              children: [
                                                _cell(
                                                  context,
                                                  MonthlyMealChart.formatQty(
                                                    bld.b,
                                                  ),
                                                  width: _bldWidth,
                                                  height: _rowHeight,
                                                  bg: bg,
                                                ),
                                                _cell(
                                                  context,
                                                  MonthlyMealChart.formatQty(
                                                    bld.l,
                                                  ),
                                                  width: _bldWidth,
                                                  height: _rowHeight,
                                                  bg: bg,
                                                ),
                                                _cell(
                                                  context,
                                                  MonthlyMealChart.formatQty(
                                                    bld.d,
                                                  ),
                                                  width: _bldWidth,
                                                  height: _rowHeight,
                                                  bg: bg,
                                                ),
                                              ],
                                            );
                                          }),
                                        ],
                                        _cell(
                                          context,
                                          MonthlyMealChart.formatQty(
                                            row.dayTotal,
                                          ),
                                          width: _totalWidth,
                                          height: _rowHeight,
                                          bg: _totalOrange,
                                          bold: row.dayTotal > 0,
                                        ),
                                      ],
                                    );
                                  }),
                                Row(
                                  children: [
                                    for (var i = 0; i < members.length; i++) ...[
                                      _cell(
                                        context,
                                        MonthlyMealChart.formatQtyOrZero(
                                          chart.memberB[i],
                                        ),
                                        width: _bldWidth,
                                        height: _rowHeight,
                                        bg: _memberColor(i),
                                        bold: true,
                                      ),
                                      _cell(
                                        context,
                                        MonthlyMealChart.formatQtyOrZero(
                                          chart.memberL[i],
                                        ),
                                        width: _bldWidth,
                                        height: _rowHeight,
                                        bg: _memberColor(i),
                                        bold: true,
                                      ),
                                      _cell(
                                        context,
                                        MonthlyMealChart.formatQtyOrZero(
                                          chart.memberD[i],
                                        ),
                                        width: _bldWidth,
                                        height: _rowHeight,
                                        bg: _memberColor(i),
                                        bold: true,
                                      ),
                                    ],
                                    _cell(
                                      context,
                                      MonthlyMealChart.formatQtyOrZero(
                                        chart.grandTotal,
                                      ),
                                      width: _totalWidth,
                                      height: _rowHeight,
                                      bg: _totalOrangeDark,
                                      bold: true,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    for (var i = 0; i < members.length; i++)
                                      _cell(
                                        context,
                                        MonthlyMealChart.formatQtyOrZero(
                                          chart.personTotal(i),
                                        ),
                                        width: _bldWidth * 3,
                                        height: _rowHeight,
                                        bg: _titleGreenDark,
                                        bold: true,
                                        textColor: Colors.white,
                                      ),
                                    _cell(
                                      context,
                                      MonthlyMealChart.formatQtyOrZero(
                                        chart.grandTotal,
                                      ),
                                      width: _totalWidth,
                                      height: _rowHeight,
                                      bg: _titleGreen,
                                      bold: true,
                                      textColor: Colors.white,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Text(
              s.mealChartScrollHint,
              textAlign: TextAlign.center,
              style: appFont(
                context: context,
                fontSize: 11,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    String text, {
    double? width,
    required double height,
    Color bg = Colors.white,
    Color? textColor,
    bool bold = false,
    double fontSize = 11,
    TextAlign align = TextAlign.center,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: _borderColor, width: 0.6),
      ),
      child: Text(
        text,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: appFont(
          context: context,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: textColor ?? AppColors.textDark,
        ),
      ),
    );
  }
}
