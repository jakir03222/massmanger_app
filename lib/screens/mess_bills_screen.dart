import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mess.dart';
import '../models/mess_bill.dart';
import '../services/mess_bill_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_session_builder.dart';

class MessBillsScreen extends StatefulWidget {
  const MessBillsScreen({super.key});

  @override
  State<MessBillsScreen> createState() => _MessBillsScreenState();
}

class _MessBillsScreenState extends State<MessBillsScreen> {
  final _service = MessBillService();
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  String get _yearMonth => yearMonthKey(_month);

  String get _monthLabel {
    const months = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];
    return '${months[_month.month - 1]} ${_month.year}';
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _openEditor({
    required String messId,
    required MessMember me,
    MessBill? existing,
  }) async {
    final result = await showModalBottomSheet<_BillFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => _BillFormSheet(
        initial: existing,
        defaultMonth: _month,
      ),
    );
    if (result == null || !mounted) return;

    try {
      if (existing == null) {
        await _service.addBill(
          messId: messId,
          type: result.type,
          amount: result.amount,
          yearMonth: result.yearMonth,
          adminUid: me.uid,
          adminName: me.name,
          note: result.note,
        );
      } else {
        await _service.updateBill(
          messId: messId,
          billId: existing.id,
          type: result.type,
          amount: result.amount,
          yearMonth: result.yearMonth,
          note: result.note,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'বিল যোগ হয়েছে' : 'বিল হালনাগাদ হয়েছে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
      if (result.yearMonth != _yearMonth) {
        final p = result.yearMonth.split('-');
        if (p.length == 2) {
          final y = int.tryParse(p[0]);
          final m = int.tryParse(p[1]);
          if (y != null && m != null) {
            setState(() => _month = DateTime(y, m));
          }
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'সংরক্ষণ ব্যর্থ — আবার চেষ্টা করুন',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    }
  }

  Future<void> _delete(String messId, MessBill bill) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'বিল মুছবেন?',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${bill.type.bnLabel} — ${formatTaka(bill.amount)} মুছে যাবে।',
          style: GoogleFonts.notoSansBengali(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('না', style: GoogleFonts.notoSansBengali()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'মুছুন',
              style: GoogleFonts.notoSansBengali(
                color: const Color(0xFFC62828),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deleteBill(messId: messId, billId: bill.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('বিল মুছে গেছে', style: GoogleFonts.notoSansBengali()),
      ),
    );
  }

  IconData _iconFor(MessBillType type) {
    switch (type) {
      case MessBillType.cook:
        return Icons.restaurant_menu_rounded;
      case MessBillType.rent:
        return Icons.home_outlined;
      case MessBillType.electricity:
        return Icons.bolt_outlined;
      case MessBillType.water:
        return Icons.water_drop_outlined;
      case MessBillType.utility:
        return Icons.wifi_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final matched = members.where((m) => m.uid == appUser.uid);
        final me = matched.isNotEmpty ? matched.first : null;
        final isAdmin = me?.isAdmin ?? false;

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: AppColors.textDark,
            title: Text(
              'মাসিক বিল',
              style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
            ),
          ),
          floatingActionButton: isAdmin && me != null
              ? FloatingActionButton.extended(
                  onPressed: () => _openEditor(messId: mess.id, me: me),
                  backgroundColor: AppColors.primaryGreen,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'বিল যোগ',
                    style: GoogleFonts.notoSansBengali(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _shiftMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          _monthLabel,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shiftMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  isAdmin
                      ? 'অ্যাডমিন বিল যোগ/সম্পাদনা/মুছতে পারবে · সব মেম্বার দেখতে পাবে'
                      : 'এই মাসের মেস বিল — অ্যাডমিন যোগ করেছে',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<MessBill>>(
                  stream: _service.watchByMonth(mess.id, _yearMonth),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      );
                    }
                    final bills = snap.data ?? [];
                    if (bills.isEmpty) {
                      return Center(
                        child: Text(
                          'এই মাসে কোনো বিল নেই',
                          style: GoogleFonts.notoSansBengali(
                            color: AppColors.textGrey,
                          ),
                        ),
                      );
                    }
                    final total =
                        bills.fold<double>(0, (s, b) => s + b.amount);
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.featureGreenBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'মোট বিল',
                                style: GoogleFonts.notoSansBengali(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                formatTaka(total),
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...bills.map(
                          (b) => _BillCard(
                            bill: b,
                            icon: _iconFor(b.type),
                            isAdmin: isAdmin,
                            onEdit: isAdmin && me != null
                                ? () => _openEditor(
                                      messId: mess.id,
                                      me: me,
                                      existing: b,
                                    )
                                : null,
                            onDelete: isAdmin
                                ? () => _delete(mess.id, b)
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.bill,
    required this.icon,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  final MessBill bill;
  final IconData icon;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.featureGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.type.bnLabel,
                  style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  formatTaka(bill.amount),
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGreen,
                  ),
                ),
                if (bill.note.isNotEmpty)
                  Text(
                    bill.note,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
              ],
            ),
          ),
          if (isAdmin) ...[
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'সম্পাদনা',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Color(0xFFC62828),
              ),
              tooltip: 'মুছুন',
            ),
          ],
        ],
      ),
    );
  }
}

class _BillFormResult {
  const _BillFormResult({
    required this.type,
    required this.amount,
    required this.yearMonth,
    required this.note,
  });

  final MessBillType type;
  final double amount;
  final String yearMonth;
  final String note;
}

class _BillFormSheet extends StatefulWidget {
  const _BillFormSheet({
    this.initial,
    required this.defaultMonth,
  });

  final MessBill? initial;
  final DateTime defaultMonth;

  @override
  State<_BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends State<_BillFormSheet> {
  late MessBillType _type;
  late DateTime _month;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _type = init?.type ?? MessBillType.cook;
    if (init != null && init.yearMonth.length >= 7) {
      final p = init.yearMonth.split('-');
      final y = int.tryParse(p[0]) ?? widget.defaultMonth.year;
      final m = int.tryParse(p[1]) ?? widget.defaultMonth.month;
      _month = DateTime(y, m);
    } else {
      _month = widget.defaultMonth;
    }
    _amountCtrl = TextEditingController(
      text: init == null
          ? ''
          : (init.amount % 1 == 0
              ? init.amount.toInt().toString()
              : init.amount.toStringAsFixed(2)),
    );
    _noteCtrl = TextEditingController(text: init?.note ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _monthLabel {
    const months = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];
    return '${months[_month.month - 1]} ${_month.year}';
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'সঠিক টাকার পরিমাণ দিন',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _BillFormResult(
        type: _type,
        amount: amount,
        yearMonth: yearMonthKey(_month),
        note: _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial == null ? 'বিল যোগ করুন' : 'বিল সম্পাদনা',
              style: GoogleFonts.notoSansBengali(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'বিলের ধরন',
              style: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MessBillType.values.map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text(
                    t.bnLabel,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppColors.primaryGreen,
                  backgroundColor: AppColors.featureGreenBg,
                  onSelected: (_) => setState(() => _type = t),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text(
              'মাস',
              style: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _month,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  helpText: 'মাস সিলেক্ট করুন',
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (picked != null) {
                  setState(() => _month = DateTime(picked.year, picked.month));
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderGrey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _monthLabel,
                      style: GoogleFonts.notoSansBengali(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'টাকার পরিমাণ',
              style: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText: 'যেমন: ৫০০০',
                hintStyle: GoogleFonts.notoSansBengali(
                  color: AppColors.textGrey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: '৳',
              ),
              style: GoogleFonts.notoSansBengali(),
            ),
            const SizedBox(height: 14),
            Text(
              'নোট (ঐচ্ছিক)',
              style: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: 'ঐচ্ছিক বিবরণ',
                hintStyle: GoogleFonts.notoSansBengali(
                  color: AppColors.textGrey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: GoogleFonts.notoSansBengali(),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.initial == null ? 'যোগ করুন' : 'হালনাগাদ করুন',
                style: GoogleFonts.notoSansBengali(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
