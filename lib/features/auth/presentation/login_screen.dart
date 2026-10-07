import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/utils/ui.dart';
import '../../../design_system/components/primary_button.dart';
import '../../../design_system/spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _controller.text.trim().length >= 9;

  Future<void> _submit() async {
    if (!_isValid || _loading) return;
    setState(() => _loading = true);
    // Normalize to E.164 for Saudi numbers (mock accepts any).
    final phone = '+966${_controller.text.trim().replaceAll(RegExp(r'\s'), '')}';
    final result = await ref.read(authControllerProvider.notifier).requestOtp(phone);
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (challenge) => context.push(Routes.otp, extra: challenge),
      (failure) => context.showFailure(failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WesalSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.loginTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: WesalSpacing.sm),
              Text(l.loginSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: WesalSpacing.xxl),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixText: '+966  ',
                  hintText: l.phoneHint,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: l.sendCode,
                isLoading: _loading,
                onPressed: _isValid ? _submit : null,
              ),
              const SizedBox(height: WesalSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
