import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
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
            ClipRRect(
              borderRadius: BorderRadius.circular(WesalRadii.xl),
              child: Image.asset(
                'assets/images/wesal_logo.jpg',
                width: 240,
                fit: BoxFit.cover,
                // Graceful fallback if the asset is unavailable.
                errorBuilder: (_, __, ___) => const _WordmarkFallback(),
              ),
            ),
            const SizedBox(height: WesalSpacing.xxl),
            Text(
              l.tagline,
              style: const TextStyle(
                color: WesalColors.brand,
                fontSize: 16,
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

class _WordmarkFallback extends StatelessWidget {
  const _WordmarkFallback();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: WesalColors.brand, size: 56),
        SizedBox(height: WesalSpacing.sm),
        Text(
          'Wesal',
          style: TextStyle(
            color: WesalColors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
