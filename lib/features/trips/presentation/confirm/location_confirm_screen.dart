import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../../core/utils/ui.dart';
import '../../../../design_system/colors.dart';
import '../../../../design_system/components/primary_button.dart';
import '../../../../design_system/components/status_views.dart';
import '../../../../design_system/components/wesal_map.dart';
import '../../../../design_system/spacing.dart';
import '../../../../design_system/typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models.dart';
import '../booking_controller.dart';

/// Confirm pickup + destination with a route preview, distance and time
/// (spec §6, §7). Requesting the authoritative quote also happens here so the
/// estimate shown is the backend's, not the client's.
class LocationConfirmScreen extends ConsumerStatefulWidget {
  const LocationConfirmScreen({super.key});

  @override
  ConsumerState<LocationConfirmScreen> createState() =>
      _LocationConfirmScreenState();
}

class _LocationConfirmScreenState
    extends ConsumerState<LocationConfirmScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final booking = ref.read(bookingControllerProvider);
    final repo = ref.read(tripRepositoryProvider);

    // Ensure a pickup exists. In production this comes from GPS / reverse
    // geocode or a manually-set pin (spec §6, §27).
    if (booking.pickup == null) {
      final pickupResult =
          await repo.resolvePickup(const LatLng(24.6908, 46.6854));
      if (!mounted) return;
      pickupResult.fold(
        (place) => ref.read(bookingControllerProvider.notifier).setPickup(place),
        (failure) => setState(() {
          _error = failure.kind.name;
          _loading = false;
        }),
      );
      if (_error != null) return;
    }

    final quoteResult =
        await ref.read(bookingControllerProvider.notifier).requestQuote();
    if (!mounted) return;
    quoteResult.fold(
      (_) => setState(() => _loading = false),
      (failure) {
        setState(() => _loading = false);
        context.showFailure(failure);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final booking = ref.watch(bookingControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.confirmLocations)),
      body: Column(
        children: [
          Expanded(
            child: WesalMap(
              pickupLabel: booking.pickup?.title,
              destinationLabel: booking.destination?.title,
            ),
          ),
          _Panel(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(WesalSpacing.xl),
                    child: LoadingView(),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LocationRow(
                        icon: Icons.my_location,
                        color: WesalColors.brand,
                        label: l.pickup,
                        value: booking.pickup?.title ?? l.currentLocation,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: WesalSpacing.xs),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Icon(Icons.more_vert, size: 18),
                        ),
                      ),
                      _LocationRow(
                        icon: Icons.location_on,
                        color: WesalColors.ink,
                        label: l.destination,
                        value: booking.destination?.title ?? '',
                      ),
                      if (booking.quote != null) ...[
                        const Divider(height: WesalSpacing.xl),
                        _TripMeta(quote: booking.quote!),
                      ],
                      const SizedBox(height: WesalSpacing.lg),
                      PrimaryButton(
                        label: l.confirmLocations,
                        onPressed: booking.quote == null
                            ? null
                            : () => context.pushReplacement(Routes.rideSelect),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TripMeta extends StatelessWidget {
  const _TripMeta({required this.quote});
  final FareQuote quote;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _MetaItem(
          icon: Icons.straighten,
          value: '${quote.distanceKm.toStringAsFixed(1)} km',
        ),
        _MetaItem(
          icon: Icons.schedule,
          value: l.etaMinutes(quote.durationMinutes),
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: WesalSpacing.sm),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: WesalSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          WesalSpacing.lg, WesalSpacing.lg, WesalSpacing.lg, WesalSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: WesalShadows.sheet(Theme.of(context).brightness),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
