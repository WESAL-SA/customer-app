import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ui.dart';
import '../../../design_system/components/primary_button.dart';
import '../../../design_system/spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'auth_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || _name.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final result = await ref.read(authControllerProvider.notifier).completeProfile(
          name: _name.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold((_) {}, (failure) => context.showFailure(failure));
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
              Text(l.profileSetupTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: WesalSpacing.xxl),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(hintText: l.fullName),
              ),
              const SizedBox(height: WesalSpacing.lg),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(hintText: l.email),
              ),
              const Spacer(),
              PrimaryButton(
                label: l.actionContinue,
                isLoading: _loading,
                onPressed: _name.text.trim().isEmpty ? null : _submit,
              ),
              const SizedBox(height: WesalSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
