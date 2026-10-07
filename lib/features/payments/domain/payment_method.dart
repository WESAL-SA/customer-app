import 'package:equatable/equatable.dart';

enum PaymentType { cash, mada, applePay, card }

/// A payment method shown to the customer.
///
/// Security (spec §10, §23): Wesal NEVER stores raw card credentials. For card
/// / Mada methods only a provider token and a display mask (last 4 digits, card
/// brand) are kept. Tokenization happens through the approved PCI-compliant
/// payment provider; this model carries only non-sensitive display data plus
/// the provider token reference.
class PaymentMethod extends Equatable {
  const PaymentMethod({
    required this.id,
    required this.type,
    this.maskedNumber,
    this.brand,
    this.isDefault = false,
    this.providerTokenRef,
  });

  final String id;
  final PaymentType type;

  /// e.g. "4821" (last 4 only — never the full PAN).
  final String? maskedNumber;
  final String? brand;
  final bool isDefault;

  /// Opaque reference to the tokenized instrument held by the payment provider.
  /// This is NOT a card number and NOT a secret key.
  final String? providerTokenRef;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        id: json['id'] as String,
        type: PaymentType.values.byName(json['type'] as String),
        maskedNumber: json['maskedNumber'] as String?,
        brand: json['brand'] as String?,
        isDefault: (json['isDefault'] as bool?) ?? false,
        providerTokenRef: json['providerTokenRef'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, type, maskedNumber, brand, isDefault, providerTokenRef];
}
