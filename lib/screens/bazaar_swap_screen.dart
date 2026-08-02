import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/bazaar_schedule.dart';
import '../models/bazaar_swap_request.dart';
import '../models/mess.dart';
import '../services/bazaar_schedule_service.dart';
import '../services/bazaar_swap_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_feedback.dart';
import '../widgets/app_surface.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';

class BazaarSwapScreen extends StatefulWidget {
  const BazaarSwapScreen({super.key});

  @override
  State<BazaarSwapScreen> createState() => _BazaarSwapScreenState();
}

class _BazaarSwapScreenState extends State<BazaarSwapScreen> {
  final _swapService = BazaarSwapService();
  final _scheduleService = BazaarScheduleService();
  final Set<String> _busy = {};
  bool _requesting = false;

  // ── helpers ──────────────────────────────────────────

  String _dateLabel(String start, String end) {
    final s = BazaarSchedule.parseDateKey(start);
    final e = BazaarSchedule.parseDateKey(end);
    if (s == null) return start;
    final sStr = formatBnDate(s);
    if (e == null || start == end) return sStr;
    return '$sStr → ${formatBnDate(e)}';
  }

  void _showError(String msg) {
    if (!mounted) return;
    showAppSnack(context, msg, isError: true);
  }

  void _showOk(String msg) {
    if (!mounted) return;
    showAppSnack(context, msg);
  }

  // ── Member: request swap with another same-mess member ──

  Future<void> _startRequest(
    String messId,
    String myUid,
    String myName,
    List<BazaarSchedule> allApproved,
  ) async {
    final s = AppStrings.of(context);

    // Step 1: my upcoming / running dates
    final myDates = allApproved
        .where((sc) =>
            sc.uid == myUid &&
            BazaarSwapService.isSwappable(sc.startDateKey, sc.endDateKey))
        .toList();

    if (myDates.isEmpty) {
      _showError(s.bazaarSwapNoSchedule);
      return;
    }

    final myPick = myDates.length == 1
        ? myDates.first
        : await _pickFromSheet(
            title: s.bazaarSwapStep1,
            schedules: myDates,
            rowLabel: (sc) => _dateLabel(sc.startDateKey, sc.endDateKey),
          );
    if (myPick == null || !mounted) return;

    // Step 2: another same-mess member's upcoming / running date
    final others = allApproved
        .where((sc) =>
            sc.uid != myUid &&
            BazaarSwapService.isSwappable(sc.startDateKey, sc.endDateKey))
        .toList();

    if (others.isEmpty) {
      _showError(s.bazaarSwapNoOtherSchedules);
      return;
    }

    final theirPick = await _pickFromSheet(
      title: s.bazaarSwapStep2,
      schedules: others,
      rowLabel: (sc) =>
          '${sc.memberName}: ${_dateLabel(sc.startDateKey, sc.endDateKey)}',
    );
    if (theirPick == null || !mounted) return;

    final myLabel = _dateLabel(myPick.startDateKey, myPick.endDateKey);
    final theirLabel =
        _dateLabel(theirPick.startDateKey, theirPick.endDateKey);

    final note = await _noteDialog(
      dateLabel: '$myLabel  ↔  ${theirPick.memberName} ($theirLabel)',
    );
    if (note == null || !mounted) return;

    setState(() => _requesting = true);
    try {
      await _swapService.requestSwap(
        messId: messId,
        requesterUid: myUid,
        requesterName: myName,
        scheduleId: myPick.id,
        dateKey: myPick.startDateKey,
        endDateKey: myPick.endDateKey,
        yearMonth: myPick.yearMonth,
        targetUid: theirPick.uid,
        targetName: theirPick.memberName,
        targetScheduleId: theirPick.id,
        targetDateKey: theirPick.startDateKey,
        targetEndDateKey: theirPick.endDateKey,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      _showOk(s.bazaarSwapSentWithPartner(myLabel, theirPick.memberName, theirLabel));
    } on BazaarSwapException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  // ── Admin / Super admin: one-tap approve ──

  Future<void> _adminApprove(
    String messId,
    String adminUid,
    BazaarSwapRequest req,
  ) async {
    setState(() => _busy.add(req.id));
    try {
      await _swapService.approveByAdmin(
        messId: messId,
        swapId: req.id,
        adminUid: adminUid,
      );
      if (!mounted) return;
      _showOk(AppStrings.of(context).bazaarSwapApprovedSnack);
    } on BazaarSwapException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy.remove(req.id));
    }
  }

  /// Admin / Super admin: swap two THIS MONTH slots (no member request).
  Future<void> _adminDirectSwap(
    String messId,
    String adminUid,
    List<BazaarSchedule> allApproved,
  ) async {
    final s = AppStrings.of(context);
    final month = BazaarSwapService.currentYearMonth();
    final eligible = allApproved
        .where((sc) => sc.yearMonth == month)
        .toList()
      ..sort((a, b) => a.startDateKey.compareTo(b.startDateKey));

    if (eligible.length < 2) {
      _showError(s.bazaarAdminNeedTwoSlots);
      return;
    }

    final first = await _pickFromSheet(
      title: s.bazaarAdminPickFirstSlot,
      schedules: eligible,
      rowLabel: (sc) =>
          '${sc.memberName}: ${_dateLabel(sc.startDateKey, sc.endDateKey)}',
    );
    if (first == null || !mounted) return;

    final secondList =
        eligible.where((sc) => sc.id != first.id).toList();
    final second = await _pickFromSheet(
      title: s.bazaarAdminPickSecondSlot,
      schedules: secondList,
      rowLabel: (sc) =>
          '${sc.memberName}: ${_dateLabel(sc.startDateKey, sc.endDateKey)}',
    );
    if (second == null || !mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.bazaarAdminSwapConfirmTitle,
          style: appFont(context: dCtx, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${first.memberName} (${_dateLabel(first.startDateKey, first.endDateKey)})\n'
          '↔\n'
          '${second.memberName} (${_dateLabel(second.startDateKey, second.endDateKey)})\n\n'
          '${s.bazaarAdminNoRequestNeeded}',
          textAlign: TextAlign.center,
          style: appFont(context: dCtx, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(s.no, style: appFont(context: dCtx)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              elevation: 0,
            ),
            child: Text(
              s.bazaarAdminApplyChange,
              style: appFont(
                context: dCtx,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _requesting = true);
    try {
      await _swapService.adminDirectSwap(
        messId: messId,
        adminUid: adminUid,
        scheduleAId: first.id,
        uidA: first.uid,
        nameA: first.memberName,
        dateKeyA: first.startDateKey,
        endDateKeyA: first.endDateKey,
        scheduleBId: second.id,
        uidB: second.uid,
        nameB: second.memberName,
        dateKeyB: second.startDateKey,
        endDateKeyB: second.endDateKey,
        yearMonth: first.yearMonth,
      );
      if (!mounted) return;
      _showOk(s.bazaarSwapApprovedSnack);
    } on BazaarSwapException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  /// Admin: reassign one THIS MONTH slot to any other mess member.
  Future<void> _adminReassign(
    String messId,
    String adminUid,
    List<BazaarSchedule> allApproved,
    List<MessMember> members,
  ) async {
    final s = AppStrings.of(context);
    final month = BazaarSwapService.currentYearMonth();
    final eligible = allApproved
        .where((sc) => sc.yearMonth == month)
        .toList()
      ..sort((a, b) => a.startDateKey.compareTo(b.startDateKey));

    if (eligible.isEmpty) {
      _showError(s.bazaarAdminNoSlotsThisMonth);
      return;
    }

    final slot = await _pickFromSheet(
      title: s.bazaarAdminPickSlotToReassign,
      schedules: eligible,
      rowLabel: (sc) =>
          '${sc.memberName}: ${_dateLabel(sc.startDateKey, sc.endDateKey)}',
    );
    if (slot == null || !mounted) return;

    final others = members.where((m) => m.uid != slot.uid).toList();
    if (others.isEmpty) {
      _showError(s.bazaarAdminNoOtherMember);
      return;
    }

    final newOwner = await showModalBottomSheet<MessMember>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.55,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  s.bazaarAdminNewOwner,
                  style: appFont(
                    context: ctx,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: others.length,
                  itemBuilder: (ctx2, i) {
                    final m = others[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.featureGreenBg,
                        child: Text(
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                          style: appFont(
                            context: ctx2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      title: Text(
                        m.name,
                        style: appFont(
                            context: ctx2, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        m.roleLabel(bn: AppStrings.of(ctx2).isBengali),
                        style: appFont(context: ctx2, fontSize: 12),
                      ),
                      onTap: () => Navigator.pop(ctx, m),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (newOwner == null || !mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.bazaarAdminReassignTitle,
          style: appFont(context: dCtx, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${_dateLabel(slot.startDateKey, slot.endDateKey)}\n'
          '${slot.memberName} → ${newOwner.name}\n\n'
          '${s.bazaarAdminNoRequestNeeded}',
          textAlign: TextAlign.center,
          style: appFont(context: dCtx, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(s.no, style: appFont(context: dCtx)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              elevation: 0,
            ),
            child: Text(
              s.ok,
              style: appFont(
                context: dCtx,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _requesting = true);
    try {
      await _swapService.adminReassignSlot(
        messId: messId,
        adminUid: adminUid,
        scheduleId: slot.id,
        fromUid: slot.uid,
        fromName: slot.memberName,
        dateKey: slot.startDateKey,
        endDateKey: slot.endDateKey,
        yearMonth: slot.yearMonth,
        toUid: newOwner.uid,
        toName: newOwner.name,
      );
      if (!mounted) return;
      _showOk(s.bazaarAdminReassignedSnack(newOwner.name));
    } on BazaarSwapException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _adminReject(
    String messId,
    String adminUid,
    BazaarSwapRequest req,
  ) async {
    setState(() => _busy.add(req.id));
    try {
      await _swapService.rejectByAdmin(
        messId: messId,
        swapId: req.id,
        adminUid: adminUid,
      );
      if (!mounted) return;
      _showOk(AppStrings.of(context).bazaarSwapRejectedSnack);
    } on BazaarSwapException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(req.id));
    }
  }

  // ── Member: cancel ───────────────────────────────────

  Future<void> _cancelRequest(
    String messId,
    String myUid,
    BazaarSwapRequest req,
  ) async {
    setState(() => _busy.add(req.id));
    try {
      await _swapService.cancelByRequester(
        messId: messId,
        swapId: req.id,
        requesterUid: myUid,
      );
      if (!mounted) return;
      _showOk(AppStrings.of(context).bazaarSwapCancelledSnack);
    } on BazaarSwapException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(req.id));
    }
  }

  // ── Dialogs ──────────────────────────────────────────

  Future<BazaarSchedule?> _pickFromSheet({
    required String title,
    required List<BazaarSchedule> schedules,
    required String Function(BazaarSchedule) rowLabel,
  }) {
    return showModalBottomSheet<BazaarSchedule>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  title,
                  style: appFont(
                    context: ctx,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: schedules.length,
                  itemBuilder: (ctx2, i) {
                    final sc = schedules[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.featureGreenBg,
                        child: Text(
                          sc.memberName.isNotEmpty
                              ? sc.memberName[0].toUpperCase()
                              : '?',
                          style: appFont(
                            context: ctx2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      title: Text(
                        rowLabel(sc),
                        style: appFont(
                          context: ctx2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, sc),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns note string (may be empty) on confirm, null if cancelled.
  Future<String?> _noteDialog({required String dateLabel}) {
    final noteCtrl = TextEditingController();
    final s = AppStrings.of(context);
    return showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.bazaarSwapRequest,
          style: appFont(context: dCtx, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.featureGreenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      color: AppColors.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: appFont(
                        context: dCtx,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGreen,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              style: appFont(context: dCtx, fontSize: 13),
              decoration: InputDecoration(
                hintText: s.bazaarSwapNoteHint,
                hintStyle: appFont(
                  context: dCtx,
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: AppColors.primaryGreen, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text(s.no, style: appFont(context: dCtx)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, noteCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              s.bazaarSwapSend,
              style: appFont(
                context: dCtx,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.darkGreen,
        elevation: 0,
        title: Text(
          s.bazaarSwapTitle,
          style: appFont(
            context: context,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGreen,
          ),
        ),
      ),
      body: MessSessionBuilder(
        builder: (context, appUser, mess, members) {
          if (members.isEmpty) {
            return Center(
              child: Text(
                s.sessionLoadFailed,
                style: appFont(context: context),
              ),
            );
          }
          final me = members.firstWhere(
            (m) => m.uid == appUser.uid,
            orElse: () => members.first,
          );
          final isAdmin = me.isAdmin;

          return StreamBuilder<List<BazaarSwapRequest>>(
            stream: _swapService.watchAll(mess.id),
            builder: (context, swapSnap) {
              if (swapSnap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      s.sessionLoadFailed,
                      textAlign: TextAlign.center,
                      style: appFont(context: context),
                    ),
                  ),
                );
              }

              final allSwaps = swapSnap.data ?? [];
              final pending = allSwaps.where((r) => r.isPending).toList();
              final history = allSwaps.where((r) => r.isResolved).toList();
              final myPending = pending
                  .where((r) => r.requesterUid == appUser.uid)
                  .toList();

              return StreamBuilder<List<BazaarSchedule>>(
                stream: _scheduleService.watchApproved(mess.id),
                builder: (context, schedSnap) {
                  final approved = schedSnap.data ?? [];

                  return Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
                        children: [
                          MessAppHeader(
                            title: mess.name,
                            subtitle: mess.location,
                          ),
                          const SizedBox(height: 12),
                          AppSectionHeader(
                            title: s.bazaarSwapTitle,
                            subtitle: isAdmin
                                ? s.bazaarSwapAdminHint
                                : s.bazaarSwapMemberHint,
                          ),
                          const SizedBox(height: 10),
                          _HowToCard(isAdmin: isAdmin),

                          // ── Admin tools: this month only, no request ──
                          if (isAdmin) ...[
                            const SizedBox(height: 16),
                            AppSectionHeader(
                              title: s.bazaarAdminScheduleChange,
                              subtitle: s.bazaarAdminScheduleChangeSub,
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _requesting
                                          ? null
                                          : () => _adminDirectSwap(
                                                mess.id,
                                                appUser.uid,
                                                approved,
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryGreen,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.swap_horiz_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: Text(
                                        s.bazaarAdminSwapSlots,
                                        style: appFont(
                                          context: context,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _requesting
                                          ? null
                                          : () => _adminReassign(
                                                mess.id,
                                                appUser.uid,
                                                approved,
                                                members,
                                              ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.primaryGreen,
                                        side: BorderSide(
                                          color: AppColors.primaryGreen,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.person_search_rounded,
                                        color: AppColors.primaryGreen,
                                        size: 20,
                                      ),
                                      label: Text(
                                        s.bazaarAdminReassignSlot,
                                        style: appFont(
                                          context: context,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryGreen,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // ── Admin / Super admin: pending requests ──
                          if (isAdmin && pending.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            AppSectionHeader(
                              title: s.bazaarSwapRequests,
                              subtitle: '${pending.length} টি অপেক্ষমাণ',
                            ),
                            const SizedBox(height: 10),
                            ...pending.map(
                              (r) => _AdminRequestCard(
                                req: r,
                                myDateLabel:
                                    _dateLabel(r.dateKey, r.endDateKey),
                                theirDateLabel: _dateLabel(
                                    r.targetDateKey, r.targetEndDateKey),
                                busy: _busy.contains(r.id),
                                onApprove: () =>
                                    _adminApprove(mess.id, appUser.uid, r),
                                onReject: () =>
                                    _adminReject(mess.id, appUser.uid, r),
                              ),
                            ),
                          ],

                          // ── My pending (member OR admin who requested) ──
                          if (myPending.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            AppSectionHeader(title: s.bazaarMySwapRequests),
                            const SizedBox(height: 10),
                            ...myPending.map(
                              (r) => _MyPendingCard(
                                req: r,
                                dateLabel:
                                    '${_dateLabel(r.dateKey, r.endDateKey)} ↔ ${r.targetName} (${_dateLabel(r.targetDateKey, r.targetEndDateKey)})',
                                busy: _busy.contains(r.id),
                                onCancel: () =>
                                    _cancelRequest(mess.id, appUser.uid, r),
                              ),
                            ),
                          ],

                          // ── Empty state ────────────────────────────
                          if (pending.isEmpty && myPending.isEmpty) ...[
                            const SizedBox(height: 24),
                            Padding(
                              padding: AppSpace.pageH,
                              child: AppEmptyState(
                                icon: Icons.swap_horiz_rounded,
                                title: s.bazaarSwapNoOpen,
                              ),
                            ),
                          ],

                          // ── History ────────────────────────────────
                          if (history.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            AppSectionHeader(title: s.history),
                            const SizedBox(height: 10),
                            ...history.take(20).map(
                                  (r) => _HistoryCard(
                                    req: r,
                                    dateLabel:
                                        _dateLabel(r.dateKey, r.endDateKey),
                                    isBn: s.isBengali,
                                  ),
                                ),
                          ],
                        ],
                      ),

                      // ── FAB ───────────────────────────────────────
                      Positioned(
                        right: 20,
                        bottom: 16,
                        child: FloatingActionButton.extended(
                          onPressed: _requesting
                              ? null
                              : () {
                                  if (isAdmin) {
                                    _adminDirectSwap(
                                      mess.id,
                                      appUser.uid,
                                      approved,
                                    );
                                  } else {
                                    _startRequest(
                                      mess.id,
                                      appUser.uid,
                                      me.name,
                                      approved,
                                    );
                                  }
                                },
                          backgroundColor: AppColors.primaryGreen,
                          icon: _requesting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.swap_horiz_rounded,
                                  color: Colors.white),
                          label: Text(
                            isAdmin ? s.bazaarAdminScheduleChange : s.bazaarSwapRequest,
                            style: appFont(
                              context: context,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HowToCard extends StatelessWidget {
  const _HowToCard({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final steps = isAdmin
        ? [
            s.bazaarHowAdminStep1,
            s.bazaarHowAdminStep2,
            s.bazaarHowAdminStep3,
            s.bazaarHowAdminStep4,
          ]
        : [
            s.bazaarHowMemberStep1,
            s.bazaarHowMemberStep2,
            s.bazaarHowMemberStep3,
            s.bazaarHowMemberStep4,
          ];

    return AppCard(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(14),
      color: AppColors.featureGreenBg,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? s.bazaarHowAdminTitle : s.bazaarHowMemberTitle,
            style: appFont(
              context: context,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < steps.length; i++) ...[
            Text(
              '${i + 1}. ${steps[i]}',
              style: appFont(
                context: context,
                fontSize: 12,
                height: 1.45,
                color: AppColors.textDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Admin / Super admin card: shows A ↔ B pair + Approve / Reject.
class _AdminRequestCard extends StatelessWidget {
  const _AdminRequestCard({
    required this.req,
    required this.myDateLabel,
    required this.theirDateLabel,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final BazaarSwapRequest req;
  final String myDateLabel;
  final String theirDateLabel;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AppCard(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      color: AppColors.updateOrangeBg,
      borderColor: AppColors.statusOrange.withValues(alpha: 0.35),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.requesterName,
                      style: appFont(
                        context: context,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      myDateLabel,
                      style: appFont(
                        context: context,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.primaryGreen,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      req.targetName,
                      style: appFont(
                        context: context,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      theirDateLabel,
                      style: appFont(
                        context: context,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGreen,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (req.note != null && req.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              req.note!,
              style: appFont(
                context: context,
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.monthRed,
                    side: BorderSide(color: AppColors.monthRed),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    s.bazaarSwapReject,
                    style: appFont(
                        context: context, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                  label: Text(
                    s.bazaarSwapApprove,
                    style: appFont(
                      context: context,
                      fontWeight: FontWeight.w700,
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

/// Member's own pending card — shows status + cancel option.
class _MyPendingCard extends StatelessWidget {
  const _MyPendingCard({
    required this.req,
    required this.dateLabel,
    required this.busy,
    required this.onCancel,
  });

  final BazaarSwapRequest req;
  final String dateLabel;
  final bool busy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AppCard(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.featureGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.swap_horiz_rounded,
                color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: appFont(
                    context: context,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  req.status.label(bn: AppStrings.of(context).isBengali),
                  style: appFont(
                    context: context,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusOrange,
                  ),
                ),
                if (req.note != null && req.note!.isNotEmpty)
                  Text(
                    req.note!,
                    style: appFont(
                      context: context,
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy ? null : onCancel,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.monthRed,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    s.bazaarSwapCancel,
                    style: appFont(
                      context: context,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// History card: resolved swap.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.req,
    required this.dateLabel,
    required this.isBn,
  });

  final BazaarSwapRequest req;
  final String dateLabel;
  final bool isBn;

  Color get _statusColor {
    switch (req.status) {
      case BazaarSwapStatus.approved:
        return AppColors.primaryGreen;
      case BazaarSwapStatus.rejected:
        return AppColors.monthRed;
      default:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.swap_horiz_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.requesterName,
                  style: appFont(
                    context: context,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  dateLabel,
                  style: appFont(
                    context: context,
                    fontSize: 12,
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (req.isApproved && req.targetName.isNotEmpty)
                  Text(
                    '↔ ${req.targetName} (${req.targetDateKey})',
                    style: appFont(
                      context: context,
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              req.status.label(bn: isBn),
              style: appFont(
                context: context,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
