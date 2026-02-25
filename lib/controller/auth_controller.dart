// lib/controller/auth_controller.dart
// Manages authentication state (email/password + Google Sign-In stubs).
// Wire up firebase_auth + google_sign_in packages for production.

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? userEmail;
  final String? userName;

  const AuthState({
    this.status = AuthStatus.idle,
    this.errorMessage,
    this.userEmail,
    this.userName,
  });

  bool get isLoading  => status == AuthStatus.loading;
  bool get isSuccess  => status == AuthStatus.success;
  bool get hasError   => status == AuthStatus.error;
  bool get isSignedIn => status == AuthStatus.success && userEmail != null;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? userEmail,
    String? userName,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  // ── Email / Password ──────────────────────────────────────────────────────

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    await Future.delayed(const Duration(seconds: 1)); // simulate network
    // TODO: replace with FirebaseAuth.instance.signInWithEmailAndPassword(...)
    if (email.isNotEmpty && password.length >= 6) {
      state = state.copyWith(
        status: AuthStatus.success,
        userEmail: email,
        userName: email.split('@').first,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid email or password.',
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    await Future.delayed(const Duration(seconds: 1));
    // TODO: replace with FirebaseAuth.instance.createUserWithEmailAndPassword(...)
    if (email.isNotEmpty && password.length >= 6) {
      state = state.copyWith(
        status: AuthStatus.success,
        userEmail: email,
        userName: name,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Please fill in all fields correctly.',
      );
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    await Future.delayed(const Duration(seconds: 1));
    // TODO: implement with google_sign_in + firebase_auth packages:
    // final googleUser = await GoogleSignIn().signIn();
    // final googleAuth = await googleUser!.authentication;
    // final credential = GoogleAuthProvider.credential(
    //   accessToken: googleAuth.accessToken,
    //   idToken: googleAuth.idToken,
    // );
    // await FirebaseAuth.instance.signInWithCredential(credential);
    state = state.copyWith(
      status: AuthStatus.success,
      userEmail: 'ahmad@example.com',
      userName: 'Ahmad Razif',
    );
  }

  void signOut() {
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.idle, errorMessage: null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (_) => AuthController(),
);
