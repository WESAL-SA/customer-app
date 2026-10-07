import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../../core/utils/ui.dart';
import '../../../../design_system/colors.dart';
import '../../../../design_system/components/primary_button.dart';
import '../../../../design_system/components/wesal_map.dart';
import '../../../../design_system/spacing.dart';
import '../../../../design_system/typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../payments/domain/payment_method.dart';
import '../../../payments/presentation/payment_label.dart';
import '../../domain/models.dart';
import '../booking_controller.dart';

/// Ride options + fare + payment + confirm (spec §8, §9, §10, §11).
class RideSelectScreen extends ConsumerStatefulWidget {
  const RideSelectScreen({super.key});

  @override
  ConsumerState<RideSelectScreen> createState() => _RideSelectScreenState();
}

class _RideSelectScreenState extends ConsumerState<RideSelectScreen> {
  List<PaymentMethod> _methods = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPayments());
  }

  Future<void> _loadPayments() async {
    final result = await ref.read(paymentRepositoryProvider).list();
    if (!mounted) return;
    result.fold((methods) {
      setState(() => _methods = methods);
      final current = ref.read(bookingControllerProvider).paymentMethodId;
      if (current == null && methods.isNotEmpty) {
        final def = methods.firstWhere((m) => m.isDefault,
            orElse: () => methods.first);
        ref
            .read(bookingControllerProvider.notifier)
            .setPayment(def.id, def.label(AppLocalizations.of(context)));
      }
    }, (_) {});
  }

  Future<void> _confirm() async {
    final result =
        await ref.read(bookingControllerProvider.notifier).requestRide();
    if (!mounted) return;
    result.fold(
      (_) => context.go(Routes.activeTrip),
      (failure) => context.showFailure(failure),
    );
  }

  void _openPaymentSheet() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(WesalSpacing.lg),
              child: Text(l.paymentMethod,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ..._methods.map((m) => ListTile(
                  leading: Icon(m.icon, color: WesalColors.brand),
                  title: Text(m.label(l)),
                  onTap: () {
                    ref
                        .read(bookingControllerProvider.notifier)
                        .setPayment(m.id, m.label(l));
                    Navigator.of(context).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final booking = ref.watch(bookingControllerProvider);
    final quote = booking.quote;

    return Scaffold(
      appBar: AppBar(title: Text(l.chooseRide)),
      body: quote == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                Expanded(
                  child: WesalMap(
                    pickupLabel: booking.pickup?.title,
                    destinationLabel: booking.destination?.title,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: WesalShadows.sheet(Theme.of(context).brightness),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: WesalSpacing.md),
                        ...quote.options.map((o) => _OptionTile(
                              option: o,
                              selected: o.id == booking.selectedOptionId,
                              onTap: () => ref
                                  .read(bookingControllerProvider.notifier)
                                  .selectOption(o.id),
                            )),
                        const Divider(height: 1),
                        _PaymentRow(
                          label: booking.paymentLabel ?? l.cash,
                          onTap: _openPaymentSheet,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(WesalSpacing.lg),
                          child: PrimaryButton(
                            label: l.confirmRide,
                            isLoading: booking.isRequesting,
                            onPressed: booking.selectedOption == null
                                ? null
                                : _confirm,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final RideOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: WesalSpacing.lg, vertical: WesalSpacing.md),
        color: selected ? WesalColors.brandSurface.withValues(alpha: 0.4) : null,
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(WesalRadii.md),
              ),
              child: const Icon(Icons.local_taxi, color: WesalColors.brand),
            ),
            const SizedBox(width: WesalSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${l.seats(option.capacity)} · ${l.etaMinutes(option.etaMinutes)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: WesalSpacing.sm),
            Text(
              option.estimatedFare.formatted(decimals: 0),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.payment, color: WesalColors.brand),
      title: Text(label),
      trailing: Text(l.actionChange,
          style: const TextStyle(color: WesalColors.brand)),
    );
  }
}
