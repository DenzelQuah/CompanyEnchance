// lib/controller/auth_controller.dart
// Manages authentication state (email/password + Google Sign-In stubs).
// Wire up firebase_auth + google_sign_in packages for production.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Get a convenient reference to the Supabase client
  final _supabase = Supabase.instance.client;

  // ── Email / Password ──────────────────────────────────────────────────────

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      state = state.copyWith(
        status: AuthStatus.success,
        userEmail: res.user?.email,
        userName: res.user?.userMetadata?['full_name'] ?? email.split('@').first,
      );
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name}, // Store the user's name in Supabase metadata
      );
      
      state = state.copyWith(
        status: AuthStatus.success,
        userEmail: res.user?.email,
        userName: name,
      );
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'An unexpected error occurred.');
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']!;

      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: 'No Email Was Found.');
        return;
      }

      // Pass the tokens to Supabase
      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      state = state.copyWith(
        status: AuthStatus.success,
        userEmail: res.user?.email,
        userName: res.user?.userMetadata?['full_name'] ?? res.user?.email?.split('@').first,
      );
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (e) {
      // 👈 1. Print the actual error to your terminal!
      print('🔥 REAL GOOGLE ERROR: $e'); 
      
      // 👈 2. Show the real error on the screen temporarily
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString()); 
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
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
