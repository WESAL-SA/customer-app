import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../../core/network/failure_messages.dart';
import '../../../../design_system/colors.dart';
import '../../../../design_system/components/status_views.dart';
import '../../../../design_system/spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models.dart';
import '../../domain/trip_status.dart';

/// Loads one page of trip history (spec §20). Pagination hook is in place via
/// [TripPage.nextCursor]; this phase renders the first page.
final _historyProvider = FutureProvider.autoDispose((ref) async {
  final result = await ref.read(tripRepositoryProvider).history();
  return result.fold((page) => page, (failure) => throw failure);
});

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(_historyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.yourTrips)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: l.errorGeneric,
          onRetry: () => ref.invalidate(_historyProvider),
        ),
        data: (page) {
          if (page.trips.isEmpty) {
            return EmptyView(title: l.noTripsTitle, message: l.noTripsMessage);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_historyProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(WesalSpacing.lg),
              itemCount: page.trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: WesalSpacing.md),
              itemBuilder: (_, i) => _TripCard(trip: page.trips[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fare = trip.finalFare ?? trip.estimatedFare;
    final cancelled = trip.status != TripStatus.tripCompleted;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(WesalRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(WesalRadii.lg),
        onTap: () => context.push(Routes.tripDetails, extra: trip),
        child: Padding(
          padding: const EdgeInsets.all(WesalSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.surfaceContainerHighest,
                child: Icon(
                  cancelled ? Icons.close : Icons.check,
                  color: cancelled ? WesalColors.danger : WesalColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: WesalSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.pickup.title} → ${trip.destination.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cancelled ? l.statusCancelled : l.statusCompleted,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WesalSpacing.sm),
              Text(fare.formatted(decimals: 0),
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
