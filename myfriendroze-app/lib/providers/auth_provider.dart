import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider({FirebaseAuth? firebaseAuth}) : _auth = (firebaseAuth ?? FirebaseAuth.instance) {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = result.user;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      debugPrint('[Auth] signIn error: code=${e.code} message=${e.message}');
      switch (e.code) {
        case 'user-not-found':
          _setError('No user found for that email.');
          break;
        case 'wrong-password':
        case 'invalid-credential':
          _setError('Invalid email or password.');
          break;
        case 'invalid-email':
          _setError('Invalid email address.');
          break;
        case 'operation-not-allowed':
          _setError('Email/Password sign-in is not enabled in Firebase.');
          break;
        default:
          _setError('Authentication failed: ${e.message}');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = result.user;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      debugPrint('[Auth] register error: code=${e.code} message=${e.message}');
      switch (e.code) {
        case 'weak-password':
          _setError('The password provided is too weak.');
          break;
        case 'email-already-in-use':
          _setError('The account already exists for that email.');
          break;
        case 'invalid-email':
          _setError('Invalid email address.');
          break;
        case 'operation-not-allowed':
          _setError('Email/Password sign-in is not enabled in Firebase.');
          break;
        case 'unauthorized-domain':
          _setError('This domain is not authorized in Firebase Authentication settings.');
          break;
        default:
          _setError('Registration failed: ${e.message}');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _setError(null);
    } catch (e) {
      _setError('Sign out failed.');
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      await _auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      debugPrint('[Auth] reset error: code=${e.code} message=${e.message}');
      switch (e.code) {
        case 'invalid-email':
          _setError('Invalid email address.');
          break;
        case 'user-not-found':
          _setError('No user found for that email.');
          break;
        default:
          _setError('Password reset failed: ${e.message}');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  void clearError() {
    _setError(null);
  }
}
