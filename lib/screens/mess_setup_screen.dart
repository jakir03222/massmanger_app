import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';
import '../models/mess.dart';
import '../services/auth_service.dart';
import '../services/mess_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_setup_banner.dart';

Future<void> _confirmAndSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final ds = AppStrings.of(dialogContext);
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          ds.logout,
          style: appFont(context: dialogContext, fontWeight: FontWeight.w700),
        ),
        content: Text(
          ds.logoutConfirm,
          style: appFont(context: dialogContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(ds.no, style: appFont(context: dialogContext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              ds.yesLogout,
              style: appFont(
                context: dialogContext,
                color: AppColors.monthRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
  if (confirmed != true) return;
  if (!context.mounted) return;

  try {
    await AuthService().signOut();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.of(context).logoutFailed,
          style: appFont(context: context),
        ),
      ),
    );
  }
}

enum MessSetupMode { create, join }

class MessSetupScreen extends StatefulWidget {
  const MessSetupScreen({super.key});

  @override
  State<MessSetupScreen> createState() => _MessSetupScreenState();
}

class _MessSetupScreenState extends State<MessSetupScreen> {
  MessSetupMode _mode = MessSetupMode.create;
  final _messNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _joinCodeController = TextEditingController();
  final _messService = MessService();
  bool _loading = false;

  @override
  void dispose() {
    _messNameController.dispose();
    _addressController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _showCreatedCode(Mess mess) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final s = AppStrings.of(context);
        return AlertDialog(
          title: Text(
            s.messCreatedTitle,
            style: appFont(context: context, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.messCreatedShareHint,
                style: appFont(context: context, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.featureGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        mess.code,
                        textAlign: TextAlign.center,
                        style: appFont(
                          context: context,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: s.copy,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: mess.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              s.codeCopied,
                              style: appFont(context: context),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.copy_rounded,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    IconButton(
                      tooltip: s.share,
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: s.shareMessInvite(mess.name, mess.code),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.share_rounded,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                s.ok,
                style: appFont(
                  context: context,
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

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    setState(() => _loading = true);
    try {
      if (_mode == MessSetupMode.create) {
        // Create first without routing, show code, then go Home.
        final mess = await _messService.createMess(
          name: _messNameController.text,
          location: _addressController.text,
          linkUser: false,
        );
        if (!mounted) return;
        setState(() => _loading = false);
        await _showCreatedCode(mess);
        await _messService.linkCurrentUserToMess(mess.id);
      } else {
        // Join → messId set → AppEntry routes to Home.
        await _messService.joinMess(code: _joinCodeController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.joinedMessSuccess,
              style: appFont(context: context),
            ),
          ),
        );
      }
    } on MessException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: appFont(context: context)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.somethingWentWrong,
            style: appFont(context: context),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _MessSetupHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const MessSetupBanner(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        s.messSetupIntro,
                        textAlign: TextAlign.center,
                        style: appFont(
                          context: context,
                          fontSize: 12,
                          color: AppColors.textGrey,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              selected: _mode == MessSetupMode.create,
                              icon: Icons.home_rounded,
                              title: s.createMessAdmin,
                              subtitle: s.youWillBeAdmin,
                              onTap: _loading
                                  ? () {}
                                  : () => setState(
                                        () => _mode = MessSetupMode.create,
                                      ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              selected: _mode == MessSetupMode.join,
                              icon: Icons.vpn_key_rounded,
                              title: s.joinMessShort,
                              subtitle: s.joinAsMember,
                              onTap: _loading
                                  ? () {}
                                  : () => setState(
                                        () => _mode = MessSetupMode.join,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FormCard(
                      mode: _mode,
                      messNameController: _messNameController,
                      addressController: _addressController,
                      joinCodeController: _joinCodeController,
                      loading: _loading,
                      onSubmit: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 16),
                    const _InfoFooter(),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _confirmAndSignOut(context),
                      icon: Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: AppColors.monthRed,
                      ),
                      label: Text(
                        s.logout,
                        style: appFont(
                          context: context,
                          fontWeight: FontWeight.w700,
                          color: AppColors.monthRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessSetupHeader extends StatelessWidget {
  const _MessSetupHeader();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: AppColors.headerIcon,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            s.messSetup,
            style: appFont(
              context: context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: s.logout,
            onPressed: () => _confirmAndSignOut(context),
            icon: Icon(
              Icons.logout_rounded,
              color: AppColors.monthRed,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectedCardBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : AppColors.borderGrey,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    selected ? AppColors.primaryGreen : const Color(0xFFECECEC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: appFont(
                context: context,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.darkGreen : AppColors.textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: appFont(
                context: context,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: selected ? AppColors.primaryGreen : AppColors.textGrey,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.mode,
    required this.messNameController,
    required this.addressController,
    required this.joinCodeController,
    required this.loading,
    this.onSubmit,
  });

  final MessSetupMode mode;
  final TextEditingController messNameController;
  final TextEditingController addressController;
  final TextEditingController joinCodeController;
  final bool loading;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mode == MessSetupMode.create) ...[
            _FormField(
              label: s.messName,
              controller: messNameController,
            ),
            const SizedBox(height: 16),
            _FormField(
              label: s.messLocation,
              controller: addressController,
              suffixIcon: Icons.my_location_outlined,
            ),
          ] else ...[
            _FormField(
              label: s.messCodeSixDigit,
              controller: joinCodeController,
              hint: s.codeExampleHint,
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                disabledBackgroundColor:
                    AppColors.primaryGreen.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mode == MessSetupMode.create
                              ? s.createMess
                              : s.joinMess,
                          style: appFont(
                            context: context,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.card,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.suffixIcon,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final IconData? suffixIcon;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: appFont(
            context: context,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: appFont(
            context: context,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: appFont(
              context: context,
              fontSize: 14,
              color: AppColors.textGrey,
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: BorderSide(
                color: AppColors.primaryGreen,
                width: 1.5,
              ),
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: AppColors.textGrey, size: 20)
                : null,
          ),
        ),
      ],
    );
  }
}

class _InfoFooter extends StatelessWidget {
  const _InfoFooter();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBoxBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              size: 14,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.messSetupFooter,
              style: appFont(
                context: context,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
