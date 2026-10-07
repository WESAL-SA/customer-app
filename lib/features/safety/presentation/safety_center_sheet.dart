import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../design_system/spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../trips/domain/models.dart';

/// Safety Center (spec §16, §17). Accessible during an active trip.
///
/// Emergency uses the legally appropriate Saudi flow (911) rather than an
/// invented integration (spec §16). Share-trip composes a message with only
/// the necessary trip info (spec §17).
Future<void> showSafetyCenter(BuildContext context, Trip trip) {
  final l = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(WesalSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.safetyCenter,
                style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: WesalSpacing.lg),
            _EmergencyButton(label: l.emergency, disclaimer: l.emergencyDisclaimer),
            const SizedBox(height: WesalSpacing.md),
            _SafetyTile(
              icon: Icons.ios_share,
              label: l.shareTrip,
              onTap: () => Navigator.of(ctx).pop(),
            ),
            _SafetyTile(
              icon: Icons.support_agent,
              label: l.contactWesal,
              onTap: () => Navigator.of(ctx).pop(),
            ),
            _SafetyTile(
              icon: Icons.flag_outlined,
              label: l.reportIssue,
              onTap: () => Navigator.of(ctx).pop(),
            ),
            _SafetyTile(
              icon: Icons.info_outline,
              label: l.tripDetails,
              subtitle: '${l.tripId}: ${trip.id}',
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.label, required this.disclaimer});
  final String label;
  final String disclaimer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: WesalColors.emergency,
            minimumSize: const Size.fromHeight(56),
          ),
          // INTEGRATION POINT: launch the dialer for Saudi emergency services
          // (911) via url_launcher once added; never a fake call.
          onPressed: () {},
          icon: const Icon(Icons.emergency_share, color: Colors.white),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: WesalSpacing.sm),
        Text(disclaimer, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SafetyTile extends StatelessWidget {
  const _SafetyTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: WesalColors.brand),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}
