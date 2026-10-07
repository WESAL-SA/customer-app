import '../../../core/network/api_result.dart';
import 'payment_method.dart';

/// Payment methods contract (spec §10, §23).
///
/// INTEGRATION POINT: the real implementation integrates the approved,
/// PCI-compliant payment provider. Card entry/tokenization happens in the
/// provider's SDK/web flow; this app only ever handles tokens + display masks,
/// never raw card data.
abstract interface class PaymentRepository {
  Future<Result<List<PaymentMethod>>> list();

  /// Adds a tokenized method. [providerTokenRef] comes from the provider SDK
  /// after the customer enters card details inside the provider's secure flow.
  Future<Result<PaymentMethod>> add({
    required PaymentType type,
    String? providerTokenRef,
  });

  Future<Result<void>> remove(String id);

  Future<Result<void>> setDefault(String id);
}
