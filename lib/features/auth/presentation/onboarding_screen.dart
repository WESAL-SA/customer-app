import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../design_system/components/primary_button.dart';
import '../../../design_system/components/wesal_logo.dart';
import '../../../design_system/spacing.dart';
import '../../../l10n/generated/app_localizations.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WesalSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const WesalLogo(size: 104),
              const SizedBox(height: WesalSpacing.xxl),
              Text(l.onboardingTitle,
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: WesalSpacing.md),
              Text(
                l.onboardingSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                label: l.getStarted,
                onPressed: () => context.go(Routes.login),
              ),
              const SizedBox(height: WesalSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
