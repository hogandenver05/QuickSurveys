import 'dart:async';

import '../models/app_user.dart';
import 'auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  final _userController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  Stream<AppUser?> get user => _userController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _currentUser = AppUser(
      id: 'test-user',
      email: email,
      name: 'Test User',
      createdAt: DateTime.now(),
    );
    _userController.add(_currentUser);
  }

  @override
  Future<void> signInWithGoogle() async {
    _currentUser = AppUser(
      id: 'google-user',
      email: 'test@gmail.com',
      name: 'Google User',
      createdAt: DateTime.now(),
    );
    _userController.add(_currentUser);
  }

  @override
  Future<void> createUserWithEmailAndPassword(
      String email,
      String password,
      String name,
      ) async {
    _currentUser = AppUser(
      id: 'new-user',
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );
    _userController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _userController.add(null);
  }

  void dispose() {
    _userController.close();
  }
}