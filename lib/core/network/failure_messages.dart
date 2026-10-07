import '../../l10n/generated/app_localizations.dart';
import 'api_result.dart';

/// Maps a [Failure] to a user-friendly, localized message. The UI shows these
/// — never raw backend errors or stack traces (spec §26).
extension FailureMessage on Failure {
  String localized(AppLocalizations l) {
    switch (kind) {
      case FailureKind.network:
        return l.errorNetwork;
      case FailureKind.timeout:
        return l.errorTimeout;
      case FailureKind.server:
        return l.errorServer;
      case FailureKind.unauthorized:
        return l.errorSessionExpired;
      case FailureKind.paymentFailed:
        return l.errorPaymentFailed;
      case FailureKind.locationUnavailable:
        return l.errorLocationUnavailable;
      case FailureKind.noDriversAvailable:
        return l.noDriversMessage;
      case FailureKind.forbidden:
      case FailureKind.validation:
      case FailureKind.notFound:
      case FailureKind.conflict:
      case FailureKind.rateLimited:
      case FailureKind.unknown:
        return l.errorGeneric;
    }
  }
}
