import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  final StreamController<AppUser?> _userController =
  StreamController<AppUser?>.broadcast();
  AppUser? _cachedUser;
  bool _initialized = false;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSubscription;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn() {
    _init();
  }

  void _init() {
    _authSubscription =
        _firebaseAuth.authStateChanges().listen((firebaseUser) async {
          await _docSubscription?.cancel();

          if (firebaseUser == null) {
            _updateUser(null);
            return;
          }

          final userRef = _firestore
              .collection('users')
              .doc(firebaseUser.uid);

          final doc = await userRef.get();

          if (doc.exists && doc.data() != null) {
            var appUser = AppUser.fromMap(
              doc.data()!,
              doc.id,
            );

            // Repair an empty Firestore name when Firebase Auth
            // already has a display name.
            if (appUser.name.trim().isEmpty &&
                firebaseUser.displayName != null &&
                firebaseUser.displayName!.trim().isNotEmpty) {
              appUser = appUser.copyWith(
                name: firebaseUser.displayName!.trim(),
              );

              await userRef.set(
                appUser.toMap(),
                SetOptions(merge: true),
              );
            }

            _updateUser(appUser);
            return;
          }

          final appUser = AppUser(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? '',
            email: firebaseUser.email ?? '',
            createdAt: DateTime.now(),
            surveyIds: [],
          );

          try {
            await userRef.set(appUser.toMap());
            _updateUser(appUser);
          } catch (e) {
            debugPrint('Error creating Firestore user: $e');
            _updateUser(null);
          }
        });
  }

  void _updateUser(AppUser? user) {
    _cachedUser = user;
    _initialized = true;
    if (!_userController.isClosed) {
      _userController.add(user);
    }
  }

  @override
  Stream<AppUser?> get user => Stream.multi((controller) {
    if (_initialized) {
      controller.add(_cachedUser);
    }
    final subscription = _userController.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = () => subscription.cancel();
  }, isBroadcast: true);

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    UserCredential userCredential;

    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();

      userCredential = await _firebaseAuth.signInWithPopup(
        googleProvider,
      );
    } else {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
    }

    final firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      return;
    }

    final userRef = _firestore
        .collection('users')
        .doc(firebaseUser.uid);

    final doc = await userRef.get();

    if (!doc.exists) {
      final appUser = AppUser(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        createdAt: DateTime.now(),
        surveyIds: [],
      );

      await userRef.set(appUser.toMap());
    }
  }

  @override
  Future<void> createUserWithEmailAndPassword(
      String email,
      String password,
      String name,
      ) async {
    final trimmedName = name.trim();

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      return;
    }

    // Store the name in Firebase Authentication too.
    await firebaseUser.updateDisplayName(trimmedName);

    final appUser = AppUser(
      id: firebaseUser.uid,
      name: trimmedName,
      email: email,
      createdAt: DateTime.now(),
      surveyIds: [],
    );

    // Save/update the Firestore user document.
    await _firestore
        .collection('users')
        .doc(appUser.id)
        .set(
      appUser.toMap(),
      SetOptions(merge: true),
    );

    _updateUser(appUser);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  void dispose() {
    _authSubscription?.cancel();
    _docSubscription?.cancel();
    _userController.close();
  }
}