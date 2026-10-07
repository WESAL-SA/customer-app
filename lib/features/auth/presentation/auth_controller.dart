import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/network/api_result.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

enum AuthStatus { unknown, unauthenticated, needsProfile, authenticated }

class AuthState {
  const AuthState({required this.status, this.user});
  final AuthStatus status;
  final WesalUser? user;

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        user = null;

  AuthState copyWith({AuthStatus? status, WesalUser? user}) =>
      AuthState(status: status ?? this.status, user: user ?? this.user);
}

/// Holds session state and drives auth-related routing redirects (spec §41:
/// on launch, restore session and route to the right screen).
class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Kick off session restoration; state starts as `unknown` so the router
    // shows the splash until we know where to send the user.
    _restore();
    return const AuthState.unknown();
  }

  Future<void> _restore() async {
    final user = await _repo.restoreSession();
    if (user == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    } else {
      state = AuthState(
        status: user.isProfileComplete
            ? AuthStatus.authenticated
            : AuthStatus.needsProfile,
        user: user,
      );
    }
  }

  Future<Result<OtpChallenge>> requestOtp(String phone) =>
      _repo.requestOtp(phone);

  Future<Result<WesalUser>> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    final result = await _repo.verifyOtp(challengeId: challengeId, code: code);
    result.fold(
      (user) {
        state = AuthState(
          status: user.isProfileComplete
              ? AuthStatus.authenticated
              : AuthStatus.needsProfile,
          user: user,
        );
      },
      (_) {},
    );
    return result;
  }

  Future<Result<WesalUser>> completeProfile({
    required String name,
    String? email,
  }) async {
    final result = await _repo.updateProfile(name: name, email: email);
    result.fold(
      (user) => state = AuthState(status: AuthStatus.authenticated, user: user),
      (_) {},
    );
    return result;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
