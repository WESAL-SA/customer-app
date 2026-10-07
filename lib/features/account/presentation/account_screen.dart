import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../app/router.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: Text(l.account)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(WesalSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: WesalColors.brandSurface,
                  child: Text(
                    (user?.name?.isNotEmpty ?? false) ? user!.name![0] : 'W',
                    style: const TextStyle(
                        fontSize: 24,
                        color: WesalColors.brand,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: WesalSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? l.profile,
                        style: Theme.of(context).textTheme.titleLarge),
                    if (user?.phone != null)
                      Text(user!.phone,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          _tile(context, Icons.person_outline, l.personalInformation, () {}),
          _tile(context, Icons.payment, l.paymentMethods,
              () => context.push(Routes.paymentMethods)),
          _tile(context, Icons.bookmark_border, l.savedPlaces, () {}),
          _tile(context, Icons.notifications_none, l.notifications, () {}),
          _tile(context, Icons.shield_outlined, l.safetyCenter, () {}),
          _LanguageTile(),
          _tile(context, Icons.help_outline, l.helpSupport, () {}),
          _tile(context, Icons.description_outlined, l.terms,
              () => context.push(Routes.terms)),
          _tile(context, Icons.privacy_tip_outlined, l.privacy,
              () => context.push(Routes.privacy)),
          const Divider(),
          _tile(
            context,
            Icons.logout,
            l.logout,
            () => _confirmLogout(context, ref),
            color: WesalColors.danger,
          ),
          const SizedBox(height: WesalSpacing.xxl),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? WesalColors.brand),
      title: Text(label, style: color == null ? null : TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.logout),
        content: Text(l.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.logout)),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _LanguageTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = Localizations.localeOf(context).languageCode;
    return ListTile(
      leading: const Icon(Icons.language, color: WesalColors.brand),
      title: Text(l.language),
      trailing: Text(
        current == 'ar' ? l.languageArabic : l.languageEnglish,
        style: const TextStyle(color: WesalColors.brand),
      ),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l.languageEnglish),
                trailing: current == 'en' ? const Icon(Icons.check) : null,
                onTap: () {
                  ref
                      .read(localeControllerProvider.notifier)
                      .setLocale(const Locale('en'));
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(l.languageArabic),
                trailing: current == 'ar' ? const Icon(Icons.check) : null,
                onTap: () {
                  ref
                      .read(localeControllerProvider.notifier)
                      .setLocale(const Locale('ar'));
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
