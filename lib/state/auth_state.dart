import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Representation of an authenticated user in the app,
/// abstracting Firebase User to allow testing and demo environments.
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  factory AppUser.fromFirebase(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}

/// Manages authentication state via Firebase Auth and Google Sign-In.
class AuthState extends ChangeNotifier {
  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn? _googleSignIn;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;
  bool _isDemoMode = false;

  AuthState({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn {
    _init();
  }

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDemoMode => _isDemoMode;

  void _init() {
    try {
      final auth = _firebaseAuth;
      if (auth != null) {
        _authSubscription = auth.authStateChanges().listen((user) {
          if (!_isDemoMode) {
            _currentUser = user != null ? AppUser.fromFirebase(user) : null;
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('Firebase auth listener init skipped: $e');
    }
  }

  /// Sign in using Google OAuth credentials
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final auth = _firebaseAuth;
      final googleSignIn = _googleSignIn;

      if (googleSignIn == null || auth == null) {
        // Fallback for desktop/local environments without native Firebase setup
        _isDemoMode = true;
        _currentUser = const AppUser(
          uid: 'demo_farmer_1',
          email: 'farmer@sowsmart.app',
          displayName: 'Rao (Demo Farmer)',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled sign-in
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _currentUser = AppUser.fromFirebase(userCredential.user!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Sign in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Demo sign-in for testing the app before running `flutterfire configure`
  void signInDemo({String? name, String? email}) {
    _isDemoMode = true;
    _currentUser = AppUser(
      uid: 'demo_user_123',
      email: email ?? 'farmer@sowsmart.app',
      displayName: name ?? 'Kisan Rao',
    );
    _errorMessage = null;
    notifyListeners();
  }

  /// Signs out of Firebase and Google
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final auth = _firebaseAuth;
      final googleSignIn = _googleSignIn;

      if (auth != null) {
        await auth.signOut();
      }
      if (googleSignIn != null) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
    } finally {
      _isDemoMode = false;
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
