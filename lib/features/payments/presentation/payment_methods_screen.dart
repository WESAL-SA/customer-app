import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/utils/ui.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/components/status_views.dart';
import '../../../design_system/spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/payment_method.dart';
import 'payment_label.dart';

final _paymentsProvider = FutureProvider.autoDispose((ref) async {
  final result = await ref.read(paymentRepositoryProvider).list();
  return result.fold((list) => list, (f) => throw f);
});

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(_paymentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.paymentMethods)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: l.errorGeneric,
          onRetry: () => ref.invalidate(_paymentsProvider),
        ),
        data: (methods) => ListView(
          children: [
            ...methods.map((m) => ListTile(
                  leading: Icon(m.icon, color: WesalColors.brand),
                  title: Text(m.label(l)),
                  trailing: m.isDefault
                      ? const Icon(Icons.check_circle,
                          color: WesalColors.success)
                      : null,
                  onTap: () async {
                    final result = await ref
                        .read(paymentRepositoryProvider)
                        .setDefault(m.id);
                    if (!context.mounted) return;
                    result.fold(
                      (_) => ref.invalidate(_paymentsProvider),
                      (f) => context.showFailure(f),
                    );
                  },
                )),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(WesalSpacing.lg),
              child: OutlinedButton.icon(
                // INTEGRATION POINT: launch the payment provider's secure card
                // entry (tokenization) flow; the app never handles raw PANs.
                onPressed: () => context.showMessage(l.errorGeneric),
                icon: const Icon(Icons.add),
                label: Text(l.paymentMethods),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
