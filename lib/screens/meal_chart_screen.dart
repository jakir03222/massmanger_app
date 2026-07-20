import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mess.dart';
import '../models/monthly_meal_chart.dart';
import '../services/monthly_meal_chart_excel_service.dart';
import '../services/monthly_meal_chart_pdf_service.dart';
import '../services/pdf_download_service.dart';
import '../theme/app_colors.dart';
import '../widgets/meal_chart_sheet_view.dart';
import '../widgets/mess_session_builder.dart' show yearMonthKey;

/// Full-screen smart meal chart for Super Admin / Admin (Excel + PDF).
class MealChartScreen extends StatefulWidget {
  const MealChartScreen({
    super.key,
    required this.mess,
    required this.members,
    required this.month,
    this.canDownload = true,
  });

  final Mess mess;
  final List<MessMember> members;
  final DateTime month;
  final bool canDownload;

  @override
  State<MealChartScreen> createState() => _MealChartScreenState();
}

class _MealChartScreenState extends State<MealChartScreen> {
  final _builder = MonthlyMealChartBuilder();
  final _excel = MonthlyMealChartExcelService();
  final _pdf = MonthlyMealChartPdfService();
  final _download = PdfDownloadService();

  MonthlyMealChart? _chart;
  Object? _error;
  bool _loading = true;
  bool _exportingExcel = false;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chart = await _builder.buildForMess(
        messId: widget.mess.id,
        members: widget.members,
        month: widget.month,
      );
      if (!mounted) return;
      setState(() {
        _chart = chart;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _exportExcel() async {
    final chart = _chart;
    if (chart == null || _exportingExcel || _exportingPdf) return;
    setState(() => _exportingExcel = true);
    try {
      final bytes = _excel.encodeChart(chart, messName: widget.mess.name);
      if (!mounted) return;
      final result = await _download.saveExcelAndOpen(
        bytes: bytes,
        filename: 'meal-chart-${yearMonthKey(widget.month)}.xlsx',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.savedToDownloads
                ? 'Excel ডাউনলোড ফোল্ডারে সেভ হয়েছে'
                : 'Excel সেভ হয়েছে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel তৈরি ব্যর্থ — আবার চেষ্টা করুন',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  Future<void> _exportPdf() async {
    final chart = _chart;
    if (chart == null || _exportingExcel || _exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final bytes = await _pdf.generate(chart, messName: widget.mess.name);
      if (!mounted) return;
      final result = await _download.saveAndOpen(
        bytes: bytes,
        filename: 'meal-chart-${yearMonthKey(widget.month)}.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.savedToDownloads
                ? 'মিল চার্ট PDF ডাউনলোড ফোল্ডারে সেভ হয়েছে'
                : 'মিল চার্ট PDF সেভ হয়েছে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF তৈরি ব্যর্থ — আবার চেষ্টা করুন',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _exportingExcel || _exportingPdf;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: Text(
          'মিল চার্ট',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (widget.canDownload && _chart != null) ...[
            IconButton(
              tooltip: 'PDF ডাউনলোড',
              onPressed: busy ? null : _exportPdf,
              icon: _exportingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
            ),
            IconButton(
              tooltip: 'Excel ডাউনলোড',
              onPressed: busy ? null : _exportExcel,
              icon: _exportingExcel
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.grid_on_rounded),
            ),
          ],
          IconButton(
            tooltip: 'রিফ্রেশ',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'চার্ট লোড হয়নি',
                          style: GoogleFonts.notoSansBengali(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                          ),
                          child: Text(
                            'আবার চেষ্টা',
                            style: GoogleFonts.notoSansBengali(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: Column(
                    children: [
                      if (widget.canDownload)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: busy ? null : _exportPdf,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: _exportingPdf
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.picture_as_pdf_outlined,
                                          size: 20,
                                        ),
                                  label: Text(
                                    _exportingPdf
                                        ? 'PDF…'
                                        : 'Smart PDF',
                                    style: GoogleFonts.notoSansBengali(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy ? null : _exportExcel,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryGreen,
                                    side: const BorderSide(
                                      color: AppColors.primaryGreen,
                                    ),
                                    minimumSize: const Size(0, 46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: _exportingExcel
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primaryGreen,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.grid_on_rounded,
                                          size: 20,
                                        ),
                                  label: Text(
                                    _exportingExcel
                                        ? 'Excel…'
                                        : 'Excel',
                                    style: GoogleFonts.notoSansBengali(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: MealChartSheetView(
                          chart: _chart!,
                          messName: widget.mess.name,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
