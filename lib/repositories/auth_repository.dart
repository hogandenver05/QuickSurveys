import '../models/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get user;
  AppUser? get currentUser;

  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> createUserWithEmailAndPassword(
      String email,
      String password,
      String name,
      );
  Future<void> signOut();
}