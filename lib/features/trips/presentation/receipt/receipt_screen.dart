import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models.dart';

/// Digital receipt (spec §19). All values come from the authoritative trip /
/// payment data; the client does not compute totals.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.trip});
  final Trip trip;

  String _fareLineLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'baseFare':
        return l.baseFare;
      case 'distanceFare':
        return l.distanceFare;
      case 'timeFare':
        return l.timeFare;
      case 'discount':
        return l.discount;
      case 'tax':
        return l.tax;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = trip.finalFare ?? trip.estimatedFare;
    final dt = trip.completedAt ?? trip.createdAt;

    return Scaffold(
      appBar: AppBar(title: Text(l.receipt)),
      body: ListView(
        padding: const EdgeInsets.all(WesalSpacing.screen),
        children: [
          Text('Wesal', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: WesalSpacing.lg),
          _kv(context, l.tripId, trip.id),
          if (dt != null)
            _kv(context, l.dateTime,
                DateFormat.yMMMEd().add_jm().format(dt)),
          const Divider(height: WesalSpacing.xxl),
          _kv(context, l.pickup, trip.pickup.title),
          _kv(context, l.destination, trip.destination.title),
          if (trip.driver != null) ...[
            const Divider(height: WesalSpacing.xxl),
            _kv(context, l.driver, trip.driver!.name),
            _kv(context, l.vehicle,
                '${trip.driver!.vehicle.color} ${trip.driver!.vehicle.label} · ${trip.driver!.vehicle.plate}'),
          ],
          const Divider(height: WesalSpacing.xxl),
          Text(l.fareBreakdown,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: WesalSpacing.sm),
          ...trip.fareLines.map((line) => _kv(
                context,
                _fareLineLabel(l, line.label),
                line.amount.formatted(),
              )),
          const Divider(height: WesalSpacing.xl),
          _kv(context, l.total, total.formatted(), emphasize: true),
          if (trip.paymentMethodLabel != null) ...[
            const SizedBox(height: WesalSpacing.lg),
            _kv(context, l.paidWith, trip.paymentMethodLabel!),
          ],
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v,
      {bool emphasize = false}) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WesalSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(k,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
          ),
          const SizedBox(width: WesalSpacing.lg),
          Flexible(
            child: Text(v, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}
