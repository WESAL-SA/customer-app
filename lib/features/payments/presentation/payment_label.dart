import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/payment_method.dart';

/// Presentation helpers for payment methods (localized label + icon).
extension PaymentMethodPresentation on PaymentMethod {
  String label(AppLocalizations l) {
    switch (type) {
      case PaymentType.cash:
        return l.cash;
      case PaymentType.mada:
        return maskedNumber == null ? l.mada : '${l.mada} •••• $maskedNumber';
      case PaymentType.applePay:
        return l.applePay;
      case PaymentType.card:
        final brand = this.brand ?? 'Card';
        return maskedNumber == null ? brand : '$brand •••• $maskedNumber';
    }
  }

  IconData get icon {
    switch (type) {
      case PaymentType.cash:
        return Icons.payments_outlined;
      case PaymentType.mada:
      case PaymentType.card:
        return Icons.credit_card;
      case PaymentType.applePay:
        return Icons.apple;
    }
  }
}
