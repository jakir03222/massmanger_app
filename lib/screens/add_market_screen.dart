import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/market_entry.dart';
import '../services/market_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bn_date_picker.dart';
import '../widgets/mess_session_builder.dart';

class _ItemControllers {
  _ItemControllers({
    String name = '',
    String quantity = '',
    String amount = '',
  })  : name = TextEditingController(text: name),
        quantity = TextEditingController(text: quantity),
        amount = TextEditingController(text: amount);

  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController amount;

  void dispose() {
    name.dispose();
    quantity.dispose();
    amount.dispose();
  }
}

class AddMarketScreen extends StatefulWidget {
  const AddMarketScreen({
    super.key,
    this.existing,
  });

  /// When set, screen opens in edit mode.
  final MarketEntry? existing;

  @override
  State<AddMarketScreen> createState() => _AddMarketScreenState();
}

class _AddMarketScreenState extends State<AddMarketScreen> {
  final _marketService = MarketService();
  late final List<_ItemControllers> _items;
  late DateTime _marketDate;
  bool _saving = false;
  bool _deleting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _marketDate = _parseExistingDate(existing?.dateKey) ?? DateTime.now();
    if (existing != null && existing.items.isNotEmpty) {
      _items = existing.items
          .map(
            (e) => _ItemControllers(
              name: e.name,
              quantity: e.quantity,
              amount: e.amount % 1 == 0
                  ? e.amount.toInt().toString()
                  : e.amount.toString(),
            ),
          )
          .toList();
    } else if (existing != null) {
      _items = [
        _ItemControllers(
          name: existing.notes,
          amount: existing.amount % 1 == 0
              ? existing.amount.toInt().toString()
              : existing.amount.toString(),
        ),
      ];
    } else {
      _items = [_ItemControllers()];
    }
  }

  DateTime? _parseExistingDate(String? key) {
    if (key == null || key.isEmpty) return null;
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  Future<void> _pickMarketDate() async {
    if (_isEdit) return;
    final picked = await showBnDatePicker(
      context: context,
      initialDate: _marketDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'বাজারের তারিখ সিলেক্ট করুন',
    );
    if (picked == null) return;
    setState(() => _marketDate = picked);
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() => _items.add(_ItemControllers()));
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  double get _totalAmount {
    var total = 0.0;
    for (final item in _items) {
      total += double.tryParse(item.amount.text.trim()) ?? 0;
    }
    return total;
  }

  List<MarketItem>? _parseItems() {
    final parsed = <MarketItem>[];
    for (final item in _items) {
      final itemName = item.name.text.trim();
      final qty = item.quantity.text.trim();
      final amount = double.tryParse(item.amount.text.trim());
      if (itemName.isEmpty && qty.isEmpty && (amount == null || amount == 0)) {
        continue;
      }
      if (itemName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'প্রতিটি আইটেমের নাম দিন',
              style: GoogleFonts.notoSansBengali(),
            ),
          ),
        );
        return null;
      }
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"$itemName" এর সঠিক টাকা দিন',
              style: GoogleFonts.notoSansBengali(),
            ),
          ),
        );
        return null;
      }
      parsed.add(MarketItem(
        name: itemName,
        quantity: qty.isEmpty ? '—' : qty,
        amount: amount,
      ));
    }

    if (parsed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'কমপক্ষে একটি বাজার আইটেম যোগ করুন',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
      return null;
    }
    return parsed;
  }

  Future<void> _save({
    required String messId,
    required String uid,
    required String name,
    required bool asAdmin,
  }) async {
    final parsed = _parseItems();
    if (parsed == null) return;

    setState(() => _saving = true);
    try {
      final total = parsed.fold<double>(0, (s, e) => s + e.amount);
      final notes = parsed
          .map((e) => '${e.name} (${e.quantity}) ${e.amount.round()}৳')
          .join(', ');

      if (_isEdit) {
        await _marketService.updateMarket(
          messId: messId,
          marketId: widget.existing!.id,
          amount: total,
          notes: notes,
          items: parsed,
          editedByUid: asAdmin ? uid : null,
          editedByName: asAdmin ? name : null,
        );
      } else {
        await _marketService.addMarket(
          messId: messId,
          shopperUid: uid,
          shopperName: name,
          amount: total,
          notes: notes,
          dateKey: dateKey(_marketDate),
          yearMonth: yearMonthKey(_marketDate),
          items: parsed,
          asAdmin: asAdmin,
        );
      }
      if (!mounted) return;
      // true = approved/saved, false = sent as pending request
      Navigator.of(context).pop(_isEdit || asAdmin);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'হালনাগাদ ব্যর্থ' : 'বাজার সংরক্ষণ ব্যর্থ',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String messId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'বাজার মুছবেন?',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'এই বাজার এন্ট্রি মুছে যাবে।',
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
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _marketService.deleteMarket(
        messId: messId,
        marketId: widget.existing!.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('মুছে ফেলা ব্যর্থ', style: GoogleFonts.notoSansBengali()),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.notoSansBengali(fontSize: 13),
      hintStyle: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textGrey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _deleting;

    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final matched = members.where((m) => m.uid == appUser.uid);
        final me = matched.isNotEmpty ? matched.first : null;
        final isAdmin = me?.isAdmin ?? false;
        final name = me?.name ?? (appUser.name ?? appUser.email);

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: AppColors.darkGreen,
            title: Text(
              _isEdit
                  ? 'বাজার সম্পাদনা করুন'
                  : (isAdmin ? 'বাজার যোগ করুন' : 'বাজার অনুরোধ'),
              style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
            ),
            actions: [
              if (_isEdit && isAdmin)
                IconButton(
                  onPressed: busy ? null : () => _delete(mess.id),
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                  tooltip: 'মুছুন (শুধু অ্যাডমিন)',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isEdit && !isAdmin) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Text(
                      'মেম্বার হিসেবে বাজার অ্যাডমিনের কাছে অনুরোধ যাবে। অ্যাডমিন অনুমোদন করলে সবাই দেখতে পাবে।',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                InkWell(
                  onTap: _isEdit || busy ? null : _pickMarketDate,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'বাজারের তারিখ',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              Text(
                                formatBnDate(_marketDate),
                                style: GoogleFonts.notoSansBengali(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isEdit)
                          Text(
                            'পরিবর্তন',
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
                const SizedBox(height: 12),
                Text(
                  'বাজারকারী: ${_isEdit ? widget.existing!.shopperName : name}',
                  style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (_isEdit && widget.existing!.wasEditedByAdmin) ...[
                  const SizedBox(height: 4),
                  Text(
                    'সম্পাদনা করেছেন: ${widget.existing!.editedByName}',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
                if (_isEdit) ...[
                  const SizedBox(height: 6),
                  Text(
                    'তৈরি: ${formatDateTime(widget.existing!.createdAt)}',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                if (_isEdit && !isAdmin) ...[
                  const SizedBox(height: 8),
                  Text(
                    'মুছতে শুধু অ্যাডমিন পারবে',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'বাজারের আইটেম',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: busy ? null : _addItem,
                      tooltip: 'আইটেম যোগ',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.featureGreenBg,
                      ),
                      icon: const Icon(Icons.add, color: AppColors.primaryGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_items.length, (index) {
                  final item = _items[index];
                  return Container(
                    key: ObjectKey(item),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'আইটেম ${index + 1}',
                              style: GoogleFonts.notoSansBengali(
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkGreen,
                              ),
                            ),
                            const Spacer(),
                            if (_items.length > 1)
                              IconButton(
                                onPressed: busy ? null : () => _removeItem(index),
                                tooltip: 'রিমুভ',
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Color(0xFFC62828),
                                ),
                              ),
                          ],
                        ),
                        TextField(
                          controller: item.name,
                          textInputAction: TextInputAction.next,
                          decoration: _fieldDecoration(
                            'বাজারের নাম',
                            hint: 'যেমন: চাল',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: item.quantity,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  'পরিমাণ',
                                  hint: '৫ কেজি',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: item.amount,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: _fieldDecoration(
                                  'টাকা',
                                  hint: '500',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: busy ? null : _addItem,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(
                      'আরও আইটেম যোগ করুন',
                      style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.featureGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'মোট টাকা',
                        style: GoogleFonts.notoSansBengali(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatTaka(_totalAmount),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: busy
                        ? null
                        : () => _save(
                              messId: mess.id,
                              uid: appUser.uid,
                              name: name,
                              asAdmin: isAdmin,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit
                                ? 'হালনাগাদ করুন'
                                : (isAdmin
                                    ? 'বাজার সংরক্ষণ করুন'
                                    : 'অ্যাডমিনকে অনুরোধ পাঠান'),
                            style: GoogleFonts.notoSansBengali(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
