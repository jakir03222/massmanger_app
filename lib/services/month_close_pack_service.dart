import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/member_payment.dart';
import '../models/mess.dart';
import '../models/monthly_settlement.dart';
import '../services/monthly_meal_chart_excel_service.dart';
import '../services/monthly_report_pdf_service.dart';
import '../utils/date_formatters.dart';

/// Builds PDF + Excel + payment text and shares as a month-close pack.
class MonthClosePackService {
  MonthClosePackService({
    MonthlyReportPdfService? pdfService,
    MonthlyMealChartExcelService? excelService,
  })  : _pdf = pdfService ?? MonthlyReportPdfService(),
        _excel = excelService ?? MonthlyMealChartExcelService();

  final MonthlyReportPdfService _pdf;
  final MonthlyMealChartExcelService _excel;

  Future<void> sharePack({
    required MonthlySettlementReport report,
    required List<MessMember> members,
    required Map<String, MemberPayment> payments,
    required bool isBengali,
  }) async {
    final monthKey =
        '${report.month.year}-${report.month.month.toString().padLeft(2, '0')}';
    // Export files always use English labels.
    final monthLabel = DateFormat('MMMM yyyy').format(report.month);
    final pdfBytes = await _pdf.generate(report);
    final excelBytes = await _excel.generate(
      mess: report.mess,
      members: members,
      month: report.month,
    );

    final dir = await getTemporaryDirectory();
    final pdfPath = '${dir.path}/invoice_report_$monthKey.pdf';
    final xlsPath = '${dir.path}/meal_chart_$monthKey.xlsx';
    await File(pdfPath).writeAsBytes(pdfBytes, flush: true);
    await File(xlsPath).writeAsBytes(excelBytes, flush: true);

    final paymentLines = <String>[
      'Payment sheet — $monthLabel (${report.mess.name})',
    ];
    for (final row in report.members) {
      final paid = payments[row.member.uid]?.paid == true;
      final net = row.netPayableReceivable;
      final dueLabel = net < 0 ? 'pays' : 'gets';
      final status = paid ? 'PAID' : 'DUE';
      final note = payments[row.member.uid]?.note.trim() ?? '';
      paymentLines.add(
        '${row.member.name}: $dueLabel ${formatTaka(net.abs())} · $status'
        '${note.isEmpty ? '' : ' ($note)'}',
      );
    }

    await SharePlus.instance.share(
      ShareParams(
        text: paymentLines.join('\n'),
        files: [
          XFile(pdfPath, mimeType: 'application/pdf'),
          XFile(
            xlsPath,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'Invoice Report — $monthLabel',
      ),
    );
  }
}
