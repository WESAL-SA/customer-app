import '../../../core/network/api_result.dart';
import 'user.dart';

/// Authentication contract (spec §25).
///
/// INTEGRATION POINT: the real implementation calls the Wesal auth API
/// (phone + OTP → tokens). Security rules the real impl must honor:
///   - OTP expiration, rate limiting, retry limits (server-enforced).
///   - Never hardcode or log OTPs.
///   - Tokens stored only via TokenStore (keychain/keystore).
///   - Token refresh + logout + session management.
abstract interface class AuthRepository {
  /// Returns the signed-in user if a valid session can be restored, else null.
  Future<WesalUser?> restoreSession();

  /// Requests an OTP for [phone] (E.164, e.g. +9665XXXXXXXX).
  /// Returns an opaque challenge id the server uses to tie verification to this
  /// request (also enables resend throttling).
  Future<Result<OtpChallenge>> requestOtp(String phone);

  /// Verifies [code] against [challengeId]. On success the session (tokens) is
  /// persisted by the implementation and the user is returned.
  Future<Result<WesalUser>> verifyOtp({
    required String challengeId,
    required String code,
  });

  /// Completes first-time profile setup.
  Future<Result<WesalUser>> updateProfile({String? name, String? email});

  Future<void> logout();
}

class OtpChallenge {
  const OtpChallenge({
    required this.challengeId,
    required this.phone,
    required this.resendCooldown,
    required this.codeLength,
  });

  final String challengeId;
  final String phone;
  final Duration resendCooldown;
  final int codeLength;
}
