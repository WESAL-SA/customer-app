import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for authentication tokens.
///
/// Security (spec §25, §28): tokens are stored in the platform keychain /
/// keystore via flutter_secure_storage — never in SharedPreferences, never in
/// plaintext, and never logged. The access token is short-lived; the refresh
/// token is used by the API client to obtain a new one.
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiry,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? accessTokenExpiry;

  bool get isAccessTokenExpired {
    final expiry = accessTokenExpiry;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _kAccess = 'wesal_access_token';
  static const _kRefresh = 'wesal_refresh_token';
  static const _kExpiry = 'wesal_access_expiry';

  @override
  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    if (access == null || refresh == null) return null;
    final expiryRaw = await _storage.read(key: _kExpiry);
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      accessTokenExpiry:
          expiryRaw == null ? null : DateTime.tryParse(expiryRaw),
    );
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
    await _storage.write(
      key: _kExpiry,
      value: tokens.accessTokenExpiry?.toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kExpiry);
  }
}

/// In-memory token store used by the mock layer and tests, so running the app
/// with mocks requires no platform keychain.
class InMemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  @override
  Future<void> clear() async => _tokens = null;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;
}
