import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/meal_entry.dart';
import '../models/mess.dart';
import '../services/meal_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bn_date_picker.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';

class MealScreen extends StatelessWidget {
  const MealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        return _MealBody(appUser: appUser, mess: mess, members: members);
      },
    );
  }
}

class _MealBody extends StatefulWidget {
  const _MealBody({
    required this.appUser,
    required this.mess,
    required this.members,
  });

  final AppUser appUser;
  final Mess mess;
  final List<MessMember> members;

  @override
  State<_MealBody> createState() => _MealBodyState();
}

class _MealBodyState extends State<_MealBody> {
  final _mealService = MealService();
  DateTime _selectedDate = DateTime.now();
  String? _memberFilterUid;
  final Set<String> _busyIds = {};
  bool _adding = false;

  String get _day => dateKey(_selectedDate);

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  MessMember? get _me {
    final matched =
        widget.members.where((m) => m.uid == widget.appUser.uid);
    return matched.isNotEmpty ? matched.first : null;
  }

  bool get _isAdmin => _me?.isAdmin ?? false;

  List<MealEntry> _filterByMember(List<MealEntry> items) {
    final uid = _memberFilterUid;
    if (uid == null) return items;
    return items.where((e) => e.uid == uid).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showBnDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'মিলের তারিখ সিলেক্ট করুন',
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<MessMember?> _pickMember() async {
    return showModalBottomSheet<MessMember>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'মেম্বার সিলেক্ট করুন',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.members.length,
                  itemBuilder: (context, index) {
                    final m = widget.members[index];
                    return ListTile(
                      title: Text(
                        m.name,
                        style: GoogleFonts.notoSansBengali(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, m),
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

  Future<_MealAddDraft?> _askQuantity(
    MealType type, {
    double initial = 0.5,
    String confirmLabel = 'যোগ করুন',
    bool pickDate = true,
  }) async {
    return showDialog<_MealAddDraft>(
      context: context,
      builder: (context) => _MealQuantityDialog(
        type: type,
        initialQty: initial,
        confirmLabel: confirmLabel,
        initialDate: _selectedDate,
        pickDate: pickDate,
      ),
    );
  }

  Future<void> _editMeal(MealEntry entry) async {
    if (!_isAdmin) return;
    final admin = _me;
    if (admin == null) return;

    final draft = await _askQuantity(
      entry.type,
      initial: entry.rateValue < 0.5 ? 0.5 : entry.rateValue,
      confirmLabel: 'হালনাগাদ করুন',
      pickDate: false,
    );
    if (draft == null) return;

    setState(() => _busyIds.add(entry.id));
    try {
      await _mealService.updateMealItem(
        messId: widget.mess.id,
        day: _day,
        itemId: entry.id,
        rateValue: draft.quantity,
        editedByUid: admin.uid,
        editedByName: admin.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'হালনাগাদ হয়েছে — সম্পাদনা: ${admin.name}',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(entry.id));
    }
  }

  Future<void> _addType(MealType type) async {
    MessMember? target = _me;
    if (_isAdmin) {
      target = await _pickMember();
      if (target == null) return;
    }
    if (target == null) return;

    final draft = await _askQuantity(type);
    if (draft == null) return;

    final day = dateKey(draft.date);
    setState(() {
      _adding = true;
      _selectedDate = draft.date;
    });
    try {
      final admin = _me;
      await _mealService.addMealItem(
        messId: widget.mess.id,
        day: day,
        uid: target.uid,
        name: target.name,
        type: type,
        rateValue: draft.quantity,
        asAdmin: _isAdmin,
        addedByUid: _isAdmin ? admin?.uid : null,
        addedByName: _isAdmin ? admin?.name : null,
      );
      if (!mounted) return;
      final q = draft.quantity % 1 == 0
          ? draft.quantity.toInt().toString()
          : draft.quantity.toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAdmin
                ? '${type.bnLabel} $q যোগ হয়েছে (${formatBnDate(draft.date)})'
                : '${type.bnLabel} $q অনুরোধ — অনুমোদন হলে তালিকায় যোগ হবে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _approve(MealEntry entry) async {
    setState(() => _busyIds.add(entry.id));
    try {
      await _mealService.approveMeal(
        messId: widget.mess.id,
        day: _day,
        itemId: entry.id,
        adminUid: widget.appUser.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'অনুমোদন — ${entry.displayLabel} তালিকায় যোগ হয়েছে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(entry.id));
    }
  }

  Future<void> _reject(MealEntry entry) async {
    setState(() => _busyIds.add(entry.id));
    try {
      await _mealService.rejectMeal(
        messId: widget.mess.id,
        day: _day,
        itemId: entry.id,
        adminUid: widget.appUser.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'প্রত্যাখ্যান — তালিকা থেকে মুছে গেছে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(entry.id));
    }
  }

  Future<void> _delete(MealEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'মিল মুছবেন?',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${entry.name} — ${entry.displayLabel} মুছে যাবে।',
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
    await _mealService.deleteMeal(
      messId: widget.mess.id,
      day: _day,
      itemId: entry.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MealEntry>>(
      stream: _mealService.watchDayMeals(widget.mess.id, _day),
      builder: (context, mealSnap) {
        final all = mealSnap.data ?? [];
        final pending = _filterByMember(all.where((e) => e.isPending).toList());
        final approved = _filterByMember(
          all.where((e) {
            if (!e.isApproved) return false;
            if (_isAdmin) return true;
            return e.uid == widget.appUser.uid;
          }).toList(),
        );
        final myPending =
            all.where((e) => e.uid == widget.appUser.uid && e.isPending);

        var morningCount = approved
            .where((e) => e.morning)
            .fold<double>(0, (s, e) => s + e.rateValue);
        var eveningCount = approved
            .where((e) => e.evening)
            .fold<double>(0, (s, e) => s + e.rateValue);
        var nightCount = approved
            .where((e) => e.night)
            .fold<double>(0, (s, e) => s + e.rateValue);
        var rateTotal = approved
            .where((e) => e.isRate)
            .fold<double>(0, (s, e) => s + e.rateValue);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MessAppHeader(
                      title: widget.mess.name,
                      subtitle: widget.mess.location,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'মিল লিস্ট',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  formatBnDate(_selectedDate),
                                  style: GoogleFonts.notoSansBengali(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                _isToday ? 'আজ' : 'পরিবর্তন',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'সকাল / বিকাল / রাত / রেট আলাদা · পরিমাণ ০.৫ করে +/− · অনুমোদনের পর তালিকায়',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _isAdmin ? 'মেম্বারের মিল যোগ' : 'মিল যোগ করুন',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _AddTypeChip(
                            label: 'সকাল যোগ',
                            enabled: !_adding,
                            onTap: () => _addType(MealType.morning),
                          ),
                          _AddTypeChip(
                            label: 'বিকাল যোগ',
                            enabled: !_adding,
                            onTap: () => _addType(MealType.evening),
                          ),
                          _AddTypeChip(
                            label: 'রাত যোগ',
                            enabled: !_adding,
                            onTap: () => _addType(MealType.night),
                          ),
                          _AddTypeChip(
                            label: 'রেট যোগ',
                            enabled: !_adding,
                            onTap: () => _addType(MealType.rate),
                          ),
                        ],
                      ),
                    ),
                    if (!_isAdmin) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'মুছতে পারবেন না · অ্যাডমিন অনুমোদন করলে হিসাব/তালিকায় যোগ হবে',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                    if (_isAdmin && widget.members.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _memberChip('সব মেম্বার', null),
                            ...widget.members.map(
                              (m) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _memberChip(m.name, m.uid),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_isAdmin && pending.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'মিল অনুরোধ (${pending.length})',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...pending.map(
                        (e) => _PendingItemCard(
                          entry: e,
                          busy: _busyIds.contains(e.id),
                          onAccept: () => _approve(e),
                          onReject: () => _reject(e),
                        ),
                      ),
                    ],
                    if (!_isAdmin && myPending.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'আমার অনুরোধ (অপেক্ষমাণ)',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...myPending.map(
                        (e) => _ListItemCard(
                          entry: e,
                          isAdmin: false,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'অনুমোদিত মিল লিস্ট',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'অনুমোদন এর পর এখানে আলাদা আলাদা দেখা যায়',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (approved.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
                        child: Text(
                          'এই তারিখে অনুমোদিত মিল নেই',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansBengali(
                            color: AppColors.textGrey,
                          ),
                        ),
                      )
                    else
                      ...approved.map(
                        (e) => _ListItemCard(
                          entry: e,
                          isAdmin: _isAdmin,
                          onEdit: _isAdmin ? () => _editMeal(e) : null,
                          onDelete: _isAdmin ? () => _delete(e) : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_isAdmin)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.borderGrey)),
                ),
                child: Text(
                  'সকাল: ${morningCount % 1 == 0 ? morningCount.toInt() : morningCount.toStringAsFixed(1)}  •  বিকাল: ${eveningCount % 1 == 0 ? eveningCount.toInt() : eveningCount.toStringAsFixed(1)}  •  রাত: ${nightCount % 1 == 0 ? nightCount.toInt() : nightCount.toStringAsFixed(1)}  •  রেট: ${rateTotal % 1 == 0 ? rateTotal.toInt() : rateTotal.toStringAsFixed(1)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _memberChip(String label, String? uid) {
    final selected = _memberFilterUid == uid;
    return GestureDetector(
      onTap: () => setState(() => _memberFilterUid = uid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.darkGreen : AppColors.borderGrey,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansBengali(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

class _MealAddDraft {
  const _MealAddDraft({required this.quantity, required this.date});

  final double quantity;
  final DateTime date;
}

class _MealQuantityDialog extends StatefulWidget {
  const _MealQuantityDialog({
    required this.type,
    this.initialQty = 0.5,
    this.confirmLabel = 'যোগ করুন',
    this.initialDate,
    this.pickDate = true,
  });

  final MealType type;
  final double initialQty;
  final String confirmLabel;
  final DateTime? initialDate;
  final bool pickDate;

  @override
  State<_MealQuantityDialog> createState() => _MealQuantityDialogState();
}

class _MealQuantityDialogState extends State<_MealQuantityDialog> {
  static const double _step = 0.5;
  static const double _min = 0.5;
  static const double _max = 20;

  late double _qty;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final start = widget.initialQty;
    _qty = start < _min ? _min : double.parse(start.toStringAsFixed(1));
    _date = widget.initialDate ?? DateTime.now();
  }

  String get _label {
    return _qty % 1 == 0 ? _qty.toInt().toString() : _qty.toStringAsFixed(1);
  }

  void _inc() {
    if (_qty + _step > _max) return;
    setState(() => _qty = double.parse((_qty + _step).toStringAsFixed(1)));
  }

  void _dec() {
    if (_qty - _step < _min) return;
    setState(() => _qty = double.parse((_qty - _step).toStringAsFixed(1)));
  }

  Future<void> _pickDate() async {
    final picked = await showBnDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'মিলের তারিখ সিলেক্ট করুন',
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${widget.type.bnLabel} যোগ',
        style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.pickDate) ...[
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formatBnDate(_date),
                        style: GoogleFonts.notoSansBengali(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'তারিখ',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            'পরিমাণ · ০.৫ করে বাড়ান / কমান',
            style: GoogleFonts.notoSansBengali(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _qty <= _min ? null : _dec,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  disabledBackgroundColor: const Color(0xFFFFCDD2),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 20),
              Container(
                width: 80,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.featureGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _label,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              IconButton.filled(
                onPressed: _qty >= _max ? null : _inc,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor: AppColors.featureGreenBg,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('বাতিল', style: GoogleFonts.notoSansBengali()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _MealAddDraft(quantity: _qty, date: _date),
          ),
          child: Text(
            widget.confirmLabel,
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _AddTypeChip extends StatelessWidget {
  const _AddTypeChip({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryGreen,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingItemCard extends StatelessWidget {
  const _PendingItemCard({
    required this.entry,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final MealEntry entry;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.name,
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
          ),
          Text(
            entry.displayLabel,
            style: GoogleFonts.notoSansBengali(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          Text(
            'যোগ: ${formatDateTime(entry.createdAt)}',
            style: GoogleFonts.notoSansBengali(
              fontSize: 11,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFC62828)),
                  ),
                  child: Text(
                    'প্রত্যাখ্যান',
                    style: GoogleFonts.notoSansBengali(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 0,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'গ্রহণ',
                          style: GoogleFonts.notoSansBengali(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListItemCard extends StatelessWidget {
  const _ListItemCard({
    required this.entry,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  final MealEntry entry;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  entry.displayLabel,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                Text(
                  'যোগ: ${formatDateTime(entry.createdAt)}',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
                if (entry.wasAddedByAdmin)
                  Text(
                    'যোগ করেছেন: ${entry.addedByName}',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                if (entry.wasEditedByAdmin)
                  Text(
                    'সম্পাদনা: ${entry.editedByName}',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGreen,
                    ),
                  ),
                if (!entry.isApproved)
                  Text(
                    entry.status.bnLabel,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: entry.isPending
                          ? const Color(0xFFF9A825)
                          : const Color(0xFFC62828),
                    ),
                  ),
              ],
            ),
          ),
          if (isAdmin) ...[
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGreen),
                tooltip: 'হালনাগাদ',
              ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                tooltip: 'মুছুন',
              ),
          ],
        ],
      ),
    );
  }
}
