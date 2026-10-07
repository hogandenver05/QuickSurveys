import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    _authSubscription = _firebaseAuth.authStateChanges().listen((firebaseUser) {
      _docSubscription?.cancel();
      if (firebaseUser == null) {
        _updateUser(null);
      } else {
        _docSubscription = _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots()
            .listen(
              (doc) {
                if (doc.exists && doc.data() != null) {
                  _updateUser(AppUser.fromMap(doc.data()!, doc.id));
                } else {
                  _updateUser(null);
                }
              },
              onError: (e) {
                _updateUser(null);
              },
            );
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
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _firebaseAuth
        .signInWithCredential(credential);

    if (userCredential.user != null) {
      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!doc.exists) {
        final appUser = AppUser(
          id: userCredential.user!.uid,
          name: googleUser.displayName ?? '',
          email: googleUser.email,
          createdAt: DateTime.now(),
          surveyIds: [],
        );
        await _firestore
            .collection('users')
            .doc(appUser.id)
            .set(appUser.toMap());
      }
    }
  }

  @override
  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      final appUser = AppUser(
        id: credential.user!.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
        surveyIds: [],
      );

      await _firestore.collection('users').doc(appUser.id).set(appUser.toMap());
    }
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
