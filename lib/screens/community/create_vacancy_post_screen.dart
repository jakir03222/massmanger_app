import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/community_post_service.dart';
import '../../theme/app_colors.dart';

class CreateVacancyPostScreen extends StatefulWidget {
  const CreateVacancyPostScreen({super.key});

  @override
  State<CreateVacancyPostScreen> createState() =>
      _CreateVacancyPostScreenState();
}

class _CreateVacancyPostScreenState extends State<CreateVacancyPostScreen> {
  final _seatsController = TextEditingController(text: '1');
  final _rentController = TextEditingController();
  final _bodyController = TextEditingController();
  final _service = CommunityPostService();
  bool _includeCode = false;
  bool _loading = false;

  @override
  void dispose() {
    _seatsController.dispose();
    _rentController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final seats = int.tryParse(_seatsController.text.trim()) ?? 0;
      await _service.createVacancyPost(
        seatsAvailable: seats,
        body: _bodyController.text,
        rentHint: _rentController.text,
        includeMessCode: _includeCode,
      );
      if (!mounted) return;
      final s = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.postUploaded,
            style: appFont(context: context),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e', style: appFont(context: context)),
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
      appBar: AppBar(
        title: Text(
          s.vacancyPost,
          style: appFont(context: context, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.seatsCountLabel,
            style: appFont(
              context: context,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _seatsController,
            keyboardType: TextInputType.number,
            style: appFont(context: context),
            decoration: _dec(context, s.seatsHint),
          ),
          const SizedBox(height: 14),
          Text(
            s.rentOptional,
            style: appFont(
              context: context,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _rentController,
            style: appFont(context: context),
            decoration: _dec(context, s.rentHintExample),
          ),
          const SizedBox(height: 14),
          Text(
            s.description,
            style: appFont(
              context: context,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyController,
            maxLines: 5,
            style: appFont(context: context),
            decoration: _dec(context, s.descriptionHint),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              s.showMessCodeOnPost,
              style: appFont(context: context, fontSize: 13),
            ),
            value: _includeCode,
            activeThumbColor: AppColors.primaryGreen,
            onChanged: (v) => setState(() => _includeCode = v),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    s.publishPost,
                    style: appFont(
                      context: context,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(BuildContext context, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: appFont(context: context, color: AppColors.textGrey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
      );
}
