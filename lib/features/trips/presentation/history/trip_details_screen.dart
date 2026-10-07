import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../design_system/colors.dart';
import '../../../../design_system/components/wesal_map.dart';
import '../../../../design_system/spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models.dart';

/// Trip details (spec §20): route, driver, vehicle, fare, receipt, support.
class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tripDetails)),
      body: ListView(
        children: [
          SizedBox(
            height: 200,
            child: WesalMap(
              pickupLabel: trip.pickup.title,
              destinationLabel: trip.destination.title,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(WesalSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(context, Icons.my_location, l.pickup, trip.pickup.title),
                _row(context, Icons.location_on, l.destination,
                    trip.destination.title),
                if (trip.driver != null)
                  _row(context, Icons.person, l.driver,
                      '${trip.driver!.name} · ${trip.driver!.vehicle.label}'),
                _row(context, Icons.payments, l.total,
                    (trip.finalFare ?? trip.estimatedFare).formatted()),
                const SizedBox(height: WesalSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long,
                      color: WesalColors.brand),
                  title: Text(l.viewReceipt),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.receipt, extra: trip),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.flag_outlined, color: WesalColors.brand),
                  title: Text(l.reportIssue),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WesalSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: WesalSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k, style: Theme.of(context).textTheme.bodySmall),
                Text(v, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
