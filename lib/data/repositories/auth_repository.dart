import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';

class AuthRepository {
  final FirebaseAuthService _authService;

  AuthRepository({FirebaseAuthService? authService})
      : _authService = authService ?? FirebaseAuthService();

  Stream<User?> get authStateChanges => _authService.authStateChanges;
  User? get currentUser => _authService.currentUser;

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      return await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_authService.getErrorMessage(e.code));
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _authService.signIn(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authService.getErrorMessage(e.code));
    }
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authService.getErrorMessage(e.code));
    }
  }

  Future<UserModel?> getCurrentUserProfile() => _authService.getCurrentUserProfile();

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) =>
      _authService.updateUserProfile(
        uid: uid,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}
