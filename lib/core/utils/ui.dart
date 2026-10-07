import 'package:flutter/material.dart';

import '../network/api_result.dart';
import '../network/failure_messages.dart';
import '../../l10n/generated/app_localizations.dart';

/// Small UI helpers for consistent, user-friendly feedback (spec §26).
extension SnackbarX on BuildContext {
  void showFailure(Failure failure) {
    final l = AppLocalizations.of(this);
    showMessage(failure.localized(l));
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
