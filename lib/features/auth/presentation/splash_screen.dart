import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/components/wesal_logo.dart';
import '../../../design_system/spacing.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Shown while the session is being restored (spec §41). The router moves the
/// user on automatically once auth state is known.
///
/// Brand: charcoal-navy backdrop with the Wesal mark and gold tagline.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: WesalColors.brandInk,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WesalLogo(size: 132),
            const SizedBox(height: WesalSpacing.xl),
            Text(
              l.appName,
              style: const TextStyle(
                color: WesalColors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: WesalSpacing.xs),
            Text(
              l.tagline,
              style: const TextStyle(
                color: WesalColors.brand,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: WesalSpacing.xxl),
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: WesalColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
