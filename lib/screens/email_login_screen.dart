import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_surface.dart';
import 'register_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _authService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: appFont(context: context)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final s = AppStrings.of(context);
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        final ds = AppStrings.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            ds.passwordResetTitle,
            style: appFont(context: context, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ds.passwordResetBody,
                style: appFont(context: context, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: controller,
                label: ds.email,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ds.cancel, style: appFont(context: context)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(
                ds.sendLink,
                style: appFont(
                  context: context,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (email == null || email.isEmpty || !mounted) return;
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.resetLinkSent,
            style: appFont(context: context),
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: appFont(context: context)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          s.emailLoginTitle,
          style: appFont(
            context: context,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.emailLoginSubtitle,
                        style: appFont(
                          context: context,
                          fontSize: 14,
                          color: AppColors.textGrey,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _emailController,
                        label: s.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.textGrey,
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return s.emailRequired;
                          if (!v.contains('@')) return s.emailInvalid;
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _passwordController,
                        label: s.password,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textGrey,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textGrey,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return s.passwordRequired;
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _forgotPassword,
                          child: Text(
                            s.forgotPassword,
                            style: appFont(
                              context: context,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      AppPrimaryButton(
                        label: s.loginAction,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                  child: Text(
                    s.createNewAccount,
                    style: appFont(
                      context: context,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
