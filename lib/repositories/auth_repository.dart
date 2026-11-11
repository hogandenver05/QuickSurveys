import '../models/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get user;
  AppUser? get currentUser;
  bool get isEmailVerified;

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

  Future<void> signOut();
}
