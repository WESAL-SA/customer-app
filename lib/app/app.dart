import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/wesal_theme.dart';
import '../l10n/generated/app_localizations.dart';
import 'locale_controller.dart';
import 'router.dart';

class WesalApp extends ConsumerWidget {
  const WesalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'Wesal',
      debugShowCheckedModeBanner: false,
      theme: WesalTheme.light(),
      darkTheme: WesalTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,

      // Localization (spec §36). RTL is applied automatically for Arabic.
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
