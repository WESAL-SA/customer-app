import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Minimal, redaction-aware logger.
///
/// Security (spec §40): this logger MUST NOT be used to log OTPs, passwords,
/// card numbers, payment secrets, auth tokens, or sensitive personal data.
/// A deny-list of key substrings is redacted from any map payload as a
/// second line of defence, but callers remain responsible for not passing
/// sensitive values in the first place.
///
/// In production, wire [AppLogger.sink] to your crash/observability provider
/// (e.g. Crashlytics/Sentry) instead of the console.
class AppLogger {
  AppLogger._();

  static const Set<String> _redactKeys = {
    'otp',
    'code',
    'password',
    'pass',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'card',
    'cardnumber',
    'card_number',
    'cvv',
    'cvc',
    'pan',
    'secret',
    'pin',
  };

  /// Pluggable sink. Defaults to console in debug, no-op in release.
  static void Function(String level, String message, Object? error,
      StackTrace? stack)? sink;

  static void d(String message, {Map<String, Object?>? data}) =>
      _log('DEBUG', message, data: data);

  static void i(String message, {Map<String, Object?>? data}) =>
      _log('INFO', message, data: data);

  static void w(String message, {Map<String, Object?>? data, Object? error}) =>
      _log('WARN', message, data: data, error: error);

  static void e(
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? data,
  }) =>
      _log('ERROR', message, data: data, error: error, stack: stack);

  static void _log(
    String level,
    String message, {
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stack,
  }) {
    final redacted = data == null ? '' : ' ${_redact(data)}';
    final line = '[$level] $message$redacted';

    if (sink != null) {
      sink!(level, line, error, stack);
      return;
    }
    if (kDebugMode) {
      developer.log(
        line,
        name: 'wesal',
        error: error,
        stackTrace: stack,
      );
    }
  }

  static Map<String, Object?> _redact(Map<String, Object?> data) {
    return data.map((key, value) {
      final lower = key.toLowerCase();
      final shouldRedact = _redactKeys.any(lower.contains);
      return MapEntry(key, shouldRedact ? '***' : value);
    });
  }
}
