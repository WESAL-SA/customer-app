import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ui.dart';
import '../../../design_system/components/primary_button.dart';
import '../../../design_system/spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_repository.dart';
import 'auth_controller.dart';

/// OTP verification (spec §25). The code is never generated or shown by the
/// client. Resend is throttled by the server's cooldown.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.challenge});
  final OtpChallenge challenge;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown(widget.challenge.resendCooldown.inSeconds);
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verify() async {
    if (_loading || _controller.text.length < widget.challenge.codeLength) return;
    setState(() => _loading = true);
    final result = await ref.read(authControllerProvider.notifier).verifyOtp(
          challengeId: widget.challenge.challengeId,
          code: _controller.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    // On success the router redirects automatically (needsProfile/authenticated).
    result.fold((_) {}, (failure) => context.showFailure(failure));
  }

  Future<void> _resend() async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .requestOtp(widget.challenge.phone);
    if (!mounted) return;
    result.fold(
      (challenge) => _startCooldown(challenge.resendCooldown.inSeconds),
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
              Text(l.otpTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: WesalSpacing.sm),
              Text(l.otpSubtitle(widget.challenge.phone),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: WesalSpacing.xxl),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 16),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.challenge.codeLength),
                ],
                onChanged: (v) {
                  setState(() {});
                  if (v.length == widget.challenge.codeLength) _verify();
                },
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: WesalSpacing.lg),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _cooldown == 0 ? _resend : null,
                  child: Text(
                    _cooldown == 0 ? l.resendCode : l.resendIn(_cooldown),
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: l.verify,
                isLoading: _loading,
                onPressed:
                    _controller.text.length == widget.challenge.codeLength
                        ? _verify
                        : null,
              ),
              const SizedBox(height: WesalSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
