import '../models/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get user;
  AppUser? get currentUser;
  bool get isEmailVerified;
  bool get supportsPasswordReauthentication;
  bool get supportsGoogleReauthentication;

  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  );
  Future<void> sendEmailVerification();
  Future<bool> checkEmailVerification();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> reauthenticateWithPassword(String password);

  Future<void> reauthenticateWithGoogle();

  Future<void> deleteAccount();

  Future<void> signOut();
}
