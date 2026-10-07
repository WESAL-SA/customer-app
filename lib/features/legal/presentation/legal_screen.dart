import 'package:flutter/material.dart';

import '../../../design_system/components/status_views.dart';
import '../../../design_system/spacing.dart';
import '../../../l10n/generated/app_localizations.dart';

enum LegalKind { terms, privacy }

/// Legal / policy screens (spec §37).
///
/// Content is intentionally NOT hardcoded here. In production these screens
/// render versioned content fetched from the backend/admin system so legal
/// wording is managed by the business, not invented in the app. Until that
/// endpoint exists, an empty state explains that content will load from the
/// backend.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.kind});
  final LegalKind kind;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = kind == LegalKind.terms ? l.terms : l.privacy;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(WesalSpacing.lg),
        child: EmptyView(
          icon: Icons.description_outlined,
          title: title,
          // INTEGRATION POINT: load versioned legal content from the backend.
          message:
              'Content will be loaded from the Wesal content service once available.',
        ),
      ),
    );
  }
}
