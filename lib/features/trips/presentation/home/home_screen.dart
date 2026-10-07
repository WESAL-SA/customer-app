import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../design_system/colors.dart';
import '../../../../design_system/spacing.dart';
import '../../../../design_system/typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../design_system/components/wesal_map.dart';
import '../../domain/trip_status.dart';
import '../trip_controller.dart';

/// Home: live map + booking card (spec §4). If an active trip exists, a resume
/// banner appears so the customer can jump back into it (spec §41 recovery).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrip = ref.watch(tripControllerProvider).valueOrNull;
    final hasActive = activeTrip != null && activeTrip.status.isActive;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: WesalMap()),

          // Top bar: logo, avatar, notifications.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WesalSpacing.screen,
                vertical: WesalSpacing.sm,
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: WesalColors.brand, size: 22),
                      const SizedBox(width: 4),
                      Text('Wesal',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                  const Spacer(),
                  _CircleButton(
                    icon: Icons.notifications_none,
                    onTap: () {},
                  ),
                  const SizedBox(width: WesalSpacing.sm),
                  _CircleButton(icon: Icons.person_outline, onTap: () {}),
                ],
              ),
            ),
          ),

          // Booking card (one-handed, bottom).
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(WesalSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasActive) ...[
                      _ResumeTripBanner(
                        onTap: () => context.push(Routes.activeTrip),
                      ),
                      const SizedBox(height: WesalSpacing.md),
                    ],
                    _BookingCard(
                      onTap: () => context.push(Routes.search),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(WesalSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(WesalRadii.xl),
        boxShadow: WesalShadows.sheet(Theme.of(context).brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.whereAreYouGoing,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: WesalSpacing.lg),
          _Row(
            icon: Icons.my_location,
            iconColor: WesalColors.brand,
            label: l.currentLocation,
            muted: false,
          ),
          const Divider(height: WesalSpacing.lg),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(WesalRadii.md),
            child: _Row(
              icon: Icons.search,
              iconColor: scheme.onSurface,
              label: l.enterDestination,
              muted: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.muted,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WesalSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: WesalSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: muted
                        ? scheme.onSurface.withValues(alpha: 0.5)
                        : scheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeTripBanner extends StatelessWidget {
  const _ResumeTripBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: WesalColors.brand,
      borderRadius: BorderRadius.circular(WesalRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WesalRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(WesalSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.navigation, color: WesalColors.white),
              const SizedBox(width: WesalSpacing.md),
              Expanded(
                child: Text(l.currentTrip,
                    style: const TextStyle(
                        color: WesalColors.white,
                        fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right, color: WesalColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(WesalSpacing.sm),
          child: Icon(icon, size: 22, color: scheme.onSurface),
        ),
      ),
    );
  }
}
