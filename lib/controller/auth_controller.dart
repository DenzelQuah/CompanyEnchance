// lib/controller/auth_controller.dart
// Manages authentication state (email/password + Google Sign-In stubs).
// Wire up firebase_auth + google_sign_in packages for production.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? userEmail;
  final String? userName;
  final bool hasCompletedSurvey;

  const AuthState({
    this.status = AuthStatus.idle,
    this.errorMessage,
    this.userEmail,
    this.userName,
    this.hasCompletedSurvey = false,
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
    bool? hasCompletedSurvey,
    
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      hasCompletedSurvey: hasCompletedSurvey ?? this.hasCompletedSurvey,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  // Get a convenient reference to the Supabase client
  final _supabase = Supabase.instance.client;


  // Checks if the authenticated user already has a row in 'survey_responses'.

  Future<bool> _checkSurveyStatus(String authUserId) async {
    try {
      // 1. First, check if they saved data using their Login ID (e.g. from a previous login)
      final authData = await _supabase
          .from('survey_responses')
          .select('id')
          .eq('id', authUserId) 
          .maybeSingle();

      if (authData != null) return true; // Found it immediately!

      // 2. PLAN B: Check if they did the survey anonymously on this device
      final prefs = await SharedPreferences.getInstance();
      final String? localId = prefs.getString('survey_session_id');

      if (localId != null) {
        // Now check Supabase for this ANONYMOUS ID
        final localData = await _supabase
            .from('survey_responses')
            .select('id')
            .eq('id', localId)
            .maybeSingle();
        
        if (localData != null) {
          return true; // Found their anonymous data!
        }
      }

      return false; // No data found at all
    } catch (e) {
      return false;
    }
  }

  // ── Email / Password ──────────────────────────────────────────────────────

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if they have done the survey before
      final hasData = await _checkSurveyStatus(res.user!.id);
      
      state = state.copyWith(
        status: AuthStatus.success,
        userEmail: res.user?.email,
        userName: res.user?.userMetadata?['full_name'] ?? email.split('@').first,
        hasCompletedSurvey: hasData,
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
        hasCompletedSurvey: false, // New users haven't completed the survey
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
      // Check if they have done the survey before
      final hasData = await _checkSurveyStatus(res.user!.id);

      state = state.copyWith(
        status: AuthStatus.success,
        userEmail: res.user?.email,
        userName: res.user?.userMetadata?['full_name'] ?? res.user?.email?.split('@').first,
        hasCompletedSurvey: hasData,
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
