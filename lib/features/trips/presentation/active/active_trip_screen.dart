import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/ui.dart';
import '../../../../design_system/colors.dart';
import '../../../../design_system/components/primary_button.dart';
import '../../../../design_system/components/rating_stars.dart';
import '../../../../design_system/components/status_views.dart';
import '../../../../design_system/components/wesal_map.dart';
import '../../../../design_system/spacing.dart';
import '../../../../design_system/typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../safety/presentation/safety_center_sheet.dart';
import '../../domain/models.dart';
import '../../domain/trip_status.dart';
import '../booking_controller.dart';
import '../trip_controller.dart';

/// Active-trip experience (spec §12–§18). Renders from the backend-authoritative
/// trip status, never from client-invented state.
class ActiveTripScreen extends ConsumerWidget {
  const ActiveTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tripAsync = ref.watch(tripControllerProvider);

    return Scaffold(
      body: tripAsync.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: l.errorGeneric,
          onRetry: () => ref.read(tripControllerProvider.notifier).refresh(),
        ),
        data: (trip) {
          if (trip == null) {
            // Nothing active — bounce home.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(Routes.home);
            });
            return const SizedBox.shrink();
          }
          return _TripBody(trip: trip);
        },
      ),
    );
  }
}

class _TripBody extends ConsumerWidget {
  const _TripBody({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = trip.status;

    if (status == TripStatus.tripCompleted) {
      return _CompletedPanel(trip: trip);
    }
    if (status.isTerminal) {
      return _TerminalPanel(trip: trip);
    }

    // Active: map on top, status panel at bottom.
    return Stack(
      children: [
        Positioned.fill(
          child: WesalMap(
            pickupLabel: trip.pickup.title,
            destinationLabel: trip.destination.title,
            showDriver: status.hasDriver,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: status.isSearching
              ? _SearchingPanel(trip: trip)
              : _DriverPanel(trip: trip),
        ),
      ],
    );
  }
}

// ---- Searching -------------------------------------------------------------

class _SearchingPanel extends ConsumerWidget {
  const _SearchingPanel({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return _BottomPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: WesalSpacing.lg),
          Text(l.findingDriver,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: WesalSpacing.xs),
          Text(l.findingDriverSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: WesalSpacing.lg),
          Text(l.estimatedFare,
              style: Theme.of(context).textTheme.bodySmall),
          Text(trip.estimatedFare.formatted(decimals: 0),
              style: WesalType.fare(Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: WesalSpacing.lg),
          OutlinedButton(
            onPressed: () => _confirmCancel(context, ref),
            child: Text(l.cancelRide),
          ),
        ],
      ),
    );
  }
}

// ---- Driver assigned / arriving / arrived / in-progress --------------------

class _DriverPanel extends ConsumerWidget {
  const _DriverPanel({required this.trip});
  final Trip trip;

  String _title(AppLocalizations l) {
    switch (trip.status) {
      case TripStatus.driverArrived:
        return l.driverArrived(trip.driver?.name ?? '');
      case TripStatus.tripStarted:
        return l.tripInProgress;
      default:
        return l.driverArriving(trip.driver?.name ?? '');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final driver = trip.driver;
    return _BottomPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_title(l),
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              if (trip.driverEtaMinutes != null &&
                  trip.status != TripStatus.tripStarted)
                _EtaChip(minutes: trip.driverEtaMinutes!),
            ],
          ),
          const SizedBox(height: WesalSpacing.lg),
          if (driver != null) _DriverRow(driver: driver),
          const SizedBox(height: WesalSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.call,
                  label: l.actionCall,
                  // INTEGRATION POINT: masked calling via the approved provider
                  // (never expose the driver's real number — spec §13).
                  onTap: () {},
                ),
              ),
              const SizedBox(width: WesalSpacing.md),
              Expanded(
                child: _ActionButton(
                  icon: Icons.message,
                  label: l.actionMessage,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: WesalSpacing.md),
              Expanded(
                child: _ActionButton(
                  icon: Icons.shield_outlined,
                  label: l.actionSafety,
                  onTap: () => showSafetyCenter(context, trip),
                ),
              ),
            ],
          ),
          if (trip.status.isCancellableByCustomer) ...[
            const SizedBox(height: WesalSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => _confirmCancel(context, ref),
                child: Text(l.cancelRide),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: scheme.surfaceContainerHighest,
          child: Text(
            driver.name.isNotEmpty ? driver.name[0] : '?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(width: WesalSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(driver.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: WesalSpacing.sm),
                  const Icon(Icons.star_rounded,
                      size: 16, color: WesalColors.warning),
                  Text(driver.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              Text('${driver.vehicle.color} ${driver.vehicle.label}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        _PlateBadge(plate: driver.vehicle.plate),
      ],
    );
  }
}

class _PlateBadge extends StatelessWidget {
  const _PlateBadge({required this.plate});
  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: WesalSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(WesalRadii.sm),
      ),
      child: Text(plate,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(letterSpacing: 1.5)),
    );
  }
}

class _EtaChip extends StatelessWidget {
  const _EtaChip({required this.minutes});
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(l.eta, style: Theme.of(context).textTheme.bodySmall),
        Text(l.etaMinutes(minutes),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: WesalColors.brand)),
      ],
    );
  }
}

// ---- Completed (with rating) -----------------------------------------------

class _CompletedPanel extends ConsumerStatefulWidget {
  const _CompletedPanel({required this.trip});
  final Trip trip;

  @override
  ConsumerState<_CompletedPanel> createState() => _CompletedPanelState();
}

class _CompletedPanelState extends ConsumerState<_CompletedPanel> {
  int _stars = 0;
  final _comment = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0 || _submitting) return;
    setState(() => _submitting = true);
    final result = await ref.read(tripControllerProvider.notifier).rate(
          stars: _stars,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold((_) => _finish(), (failure) => context.showFailure(failure));
  }

  void _finish() {
    ref.read(bookingControllerProvider.notifier).reset();
    ref.read(tripControllerProvider.notifier).clear();
    if (context.mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final trip = widget.trip;
    final fare = trip.finalFare ?? trip.estimatedFare;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(WesalSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: WesalSpacing.xl),
            const Icon(Icons.check_circle,
                color: WesalColors.success, size: 56),
            const SizedBox(height: WesalSpacing.md),
            Text(l.tripCompleted,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: WesalSpacing.sm),
            Text(fare.formatted(),
                textAlign: TextAlign.center,
                style: WesalType.fare(Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: WesalSpacing.xxl),
            Text(l.howWasYourTrip,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: WesalSpacing.md),
            RatingStars(
              value: _stars.toDouble(),
              onChanged: (v) => setState(() => _stars = v),
            ),
            const SizedBox(height: WesalSpacing.lg),
            TextField(
              controller: _comment,
              maxLines: 2,
              decoration: InputDecoration(hintText: l.addCommentOptional),
            ),
            const SizedBox(height: WesalSpacing.lg),
            PrimaryButton(
              label: l.submitRating,
              isLoading: _submitting,
              onPressed: _stars == 0 ? null : _submit,
            ),
            const SizedBox(height: WesalSpacing.sm),
            TextButton(
              onPressed: () => context.push(Routes.receipt, extra: trip),
              child: Text(l.viewReceipt),
            ),
            TextButton(onPressed: _finish, child: Text(l.actionDone)),
          ],
        ),
      ),
    );
  }
}

// ---- Terminal (cancelled / no driver / payment failed) ---------------------

class _TerminalPanel extends ConsumerWidget {
  const _TerminalPanel({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isNoDriver = trip.status == TripStatus.noDriverAvailable;
    return SafeArea(
      child: EmptyView(
        icon: isNoDriver ? Icons.search_off : Icons.cancel_outlined,
        title: isNoDriver ? l.noDriversTitle : l.statusCancelled,
        message: isNoDriver ? l.noDriversMessage : null,
        action: PrimaryButton(
          label: l.actionDone,
          onPressed: () {
            ref.read(bookingControllerProvider.notifier).reset();
            ref.read(tripControllerProvider.notifier).clear();
            context.go(Routes.home);
          },
        ),
      ),
    );
  }
}

// ---- shared ---------------------------------------------------------------

Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.cancelRide),
      content: Text('${l.cancelRide}?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel)),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.actionConfirm)),
      ],
    ),
  );
  if (confirmed != true) return;
  final result = await ref.read(tripControllerProvider.notifier).cancel();
  if (!context.mounted) return;
  result.fold((_) {}, (failure) => context.showFailure(failure));
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(WesalSpacing.lg),
      padding: const EdgeInsets.all(WesalSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(WesalRadii.xl),
        boxShadow: WesalShadows.sheet(Theme.of(context).brightness),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WesalRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: WesalSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(WesalRadii.md),
        ),
        child: Column(
          children: [
            Icon(icon, color: WesalColors.brand),
            const SizedBox(height: WesalSpacing.xs),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
