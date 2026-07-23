import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/market_entry.dart';
import '../models/mess.dart';
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

  /// Due bazaar — unpaid at the shop.
  bool _isDue = false;

  /// Admin adding bazaar on behalf of a selected member (null = self).
  String? _shopperUid;
  String? _shopperName;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _marketDate = _parseExistingDate(existing?.dateKey) ?? DateTime.now();
    _isDue = existing?.isDue ?? false;
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
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final s = AppStrings.of(context);
    final picked = await showBnDatePicker(
      context: context,
      initialDate: _marketDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: s.selectMarketDate,
    );
    if (!mounted || picked == null) return;
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
    final s = AppStrings.of(context);
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
              s.itemNameRequired,
              style: appFont(context: context),
            ),
          ),
        );
        return null;
      }
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.itemAmountRequired(itemName),
              style: appFont(context: context),
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
            s.addAtLeastOneItem,
            style: appFont(context: context),
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
      final total = parsed.fold<double>(0, (sum, e) => sum + e.amount);
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
          isDue: _isDue,
          dateKey: dateKey(_marketDate),
          yearMonth: yearMonthKey(_marketDate),
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
          isDue: _isDue,
        );
      }
      if (!mounted) return;
      // true = approved/saved, false = sent as pending request
      Navigator.of(context).pop(_isEdit || asAdmin);
    } catch (_) {
      if (!mounted) return;
      final s = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? s.updateFailed : s.marketSaveFailed,
            style: appFont(context: context),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String messId) async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          s.deleteMarketTitle,
          style: appFont(context: context, fontWeight: FontWeight.w700),
        ),
        content: Text(
          s.deleteMarketBody,
          style: appFont(context: context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.no, style: appFont(context: context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              s.delete,
              style: appFont(
                context: context,
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
      final sn = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sn.deleteFailed, style: appFont(context: context)),
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
      labelStyle: appFont(context: context, fontSize: 13),
      hintStyle: appFont(
        context: context,
        fontSize: 12,
        color: AppColors.textGrey,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final busy = _saving || _deleting;

    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final matched = members.where((m) => m.uid == appUser.uid);
        final me = matched.isNotEmpty ? matched.first : null;
        final isAdmin = me?.isAdmin ?? false;
        final myName = me?.name ?? (appUser.name ?? appUser.email);

        // Effective shopper: admin may pick another member when adding.
        final canPickShopper = !_isEdit && isAdmin && members.isNotEmpty;
        final shopperUid = _shopperUid ?? appUser.uid;
        final shopperName = _shopperName ?? myName;

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: AppColors.darkGreen,
            title: Text(
              _isEdit
                  ? s.editMarket
                  : (isAdmin ? s.addMarketFull : s.marketRequestTitle),
              style: appFont(context: context, fontWeight: FontWeight.w700),
            ),
            actions: [
              if (_isEdit && isAdmin)
                IconButton(
                  onPressed: busy ? null : () => _delete(mess.id),
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                  tooltip: s.deleteAdminOnlyTooltip,
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
                      s.memberMarketRequestHint,
                      style: appFont(
                        context: context,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Material(
                  color: AppColors.featureGreenBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primaryGreen),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: busy ? null : _pickMarketDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              size: 22,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.selectMarketDate,
                                  style: appFont(
                                    context: context,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatBnDate(_marketDate),
                                  style: appFont(
                                    context: context,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.pickDate,
                              style: appFont(
                                context: context,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.card,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.tapDateThenSave,
                  style: appFont(
                    context: context,
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 12),
                if (canPickShopper)
                  _ShopperSelector(
                    members: members,
                    selectedUid: shopperUid,
                    onSelected: (m) => setState(() {
                      _shopperUid = m.uid;
                      _shopperName = m.name;
                    }),
                  )
                else
                  Text(
                    s.shopperLabel(
                      _isEdit ? widget.existing!.shopperName : shopperName,
                    ),
                    style: appFont(
                      context: context,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                if (_isEdit && widget.existing!.wasEditedByAdmin) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.editedByFull(widget.existing!.editedByName ?? ''),
                    style: appFont(
                      context: context,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
                if (_isEdit) ...[
                  const SizedBox(height: 6),
                  Text(
                    s.createdAtLabel(
                      formatDateTime(widget.existing!.createdAt),
                    ),
                    style: appFont(
                      context: context,
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                if (_isEdit && !isAdmin) ...[
                  const SizedBox(height: 8),
                  Text(
                    s.onlyAdminCanDelete,
                    style: appFont(
                      context: context,
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      s.marketItems,
                      style: appFont(
                        context: context,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: busy ? null : _addItem,
                      tooltip: s.addItemTooltip,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.featureGreenBg,
                      ),
                      icon: Icon(Icons.add, color: AppColors.primaryGreen),
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
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              s.itemNumber(index + 1),
                              style: appFont(
                                context: context,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkGreen,
                              ),
                            ),
                            const Spacer(),
                            if (_items.length > 1)
                              IconButton(
                                onPressed: busy ? null : () => _removeItem(index),
                                tooltip: s.remove,
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
                            s.marketItemName,
                            hint: s.marketItemNameHint,
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
                                  s.amount,
                                  hint: s.quantityHint,
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
                                  s.taka,
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
                      s.addMoreItems,
                      style: appFont(
                        context: context,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: _isDue
                      ? const Color(0xFFFFF3E0)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _isDue
                          ? AppColors.actionOrange
                          : AppColors.borderGrey,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    value: _isDue,
                    onChanged: busy ? null : (v) => setState(() => _isDue = v),
                    activeThumbColor: AppColors.actionOrange,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    title: Text(
                      s.dueMarket,
                      style: appFont(
                        context: context,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    subtitle: Text(
                      s.dueMarketSubtitle,
                      style: appFont(
                        context: context,
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                    secondary: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: _isDue
                          ? AppColors.actionOrange
                          : AppColors.textGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.featureGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isDue ? s.totalAmountDue : s.totalAmount,
                        style: appFont(
                          context: context,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatTaka(_totalAmount),
                        style: appFont(
                          context: context,
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
                              uid: shopperUid,
                              name: shopperName,
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
                                ? s.update
                                : (isAdmin
                                    ? s.saveMarket
                                    : s.sendRequestToAdmin),
                            style: appFont(
                              context: context,
                              fontWeight: FontWeight.w600,
                              color: AppColors.card,
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

class _ShopperSelector extends StatelessWidget {
  const _ShopperSelector({
    required this.members,
    required this.selectedUid,
    required this.onSelected,
  });

  final List<MessMember> members;
  final String selectedUid;
  final ValueChanged<MessMember> onSelected;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.selectShopper,
          style: appFont(
            context: context,
            fontSize: 12,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: members.any((m) => m.uid == selectedUid)
                  ? selectedUid
                  : null,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down,
                  color: AppColors.primaryGreen),
              hint: Text(s.member, style: appFont(context: context)),
              items: members
                  .map(
                    (m) => DropdownMenuItem<String>(
                      value: m.uid,
                      child: Text(
                        m.name +
                            (m.isSuperAdmin
                                ? ' (${s.superAdmin})'
                                : (m.isRegularAdmin ? ' (${s.admin})' : '')),
                        style: appFont(context: context),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (uid) {
                if (uid == null) return;
                final picked = members.firstWhere((m) => m.uid == uid);
                onSelected(picked);
              },
            ),
          ),
        ),
      ],
    );
  }
}
