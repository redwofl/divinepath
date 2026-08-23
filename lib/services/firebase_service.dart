import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._private();
  factory FirebaseService() => _instance;
  static FirebaseService get instance => _instance;
  FirebaseService._private();

  // Firebase instances
  late final FirebaseApp _app;
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;
  late final FirebaseMessaging _messaging;

  // Google Sign-In (lazy init to avoid web crash when not configured)
  GoogleSignIn? _googleSignIn;
  GoogleSignIn get _googleSignInInstance => _googleSignIn ??= GoogleSignIn();
  bool _isAvailable = true;

  /// Mark Firebase as unavailable (no config)
  void markAsUnavailable() {
    _isAvailable = false;
  }

  /// Check if Firebase is available
  bool get isAvailable => _isAvailable;

  // Getters - safe even if not initialized
  FirebaseAuth? get auth => _isAvailable ? _auth : null;
  FirebaseFirestore? get firestore => _isAvailable ? _firestore : null;
  FirebaseStorage? get storage => _isAvailable ? _storage : null;
  FirebaseMessaging? get messaging => _isAvailable ? _messaging : null;
  User? get currentUser => _isAvailable ? _auth.currentUser : null;

  /// Initialize Firebase
  Future<void> initialize() async {
    _app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _auth = FirebaseAuth.instanceFor(app: _app);
    _firestore = FirebaseFirestore.instanceFor(app: _app);
    _storage = FirebaseStorage.instanceFor(app: _app);
    _messaging = FirebaseMessaging.instance;

    // Request notification permissions
    await _requestNotificationPermissions();

    // Get FCM token
    await _getFcmToken();
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  /// Get FCM token
  Future<String?> _getFcmToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Listen to FCM messages
  void listenToMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Message received: ${message.notification?.title}');
      // Handle foreground messages
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened: ${message.notification?.title}');
      // Handle notification tap
    });

    // Handle app opened from terminated state
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from notification: ${message.notification?.title}');
      }
    });
  }

  /// Throw if Firebase not available
  void _checkAvailable() {
    if (!_isAvailable) {
      throw Exception('Firebase is not configured. Configure in lib/config/app_config.dart');
    }
  }

  // ==================== AUTH METHODS ====================

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) {
    _checkAvailable();
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmail(String email, String password) {
    _checkAvailable();
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    _checkAvailable();
    try {
      final GoogleSignInAccount? googleUser = await _googleSignInInstance.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  /// Sign in as guest
  Future<UserCredential> signInAsGuest() {
    _checkAvailable();
    return _auth.signInAnonymously();
  }

  /// Sign out
  Future<void> signOut() async {
    _checkAvailable();
    if (_googleSignIn != null) await _googleSignIn!.signOut();
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) {
    _checkAvailable();
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    _checkAvailable();
    final user = _auth.currentUser;
    if (user != null) {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  // ==================== USER METHODS ====================

  /// Get user document reference
  DocumentReference getUserRef(String uid) {
    _checkAvailable();
    return _firestore.collection('users').doc(uid);
  }

  /// Get user data from Firestore
  Future<DocumentSnapshot> getUserData(String uid) {
    _checkAvailable();
    return _firestore.collection('users').doc(uid).get();
  }

  /// Create/update user data in Firestore
  Future<void> setUserData(String uid, Map<String, dynamic> data) {
    _checkAvailable();
    return _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Check if user exists
  Future<bool> userExists(String uid) async {
    _checkAvailable();
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  // ==================== COLLECTION HELPERS ====================

  /// Get a collection reference
  CollectionReference getCollection(String path) {
    _checkAvailable();
    return _firestore.collection(path);
  }

  /// Get a document reference
  DocumentReference getDocument(String collectionPath, String docId) {
    _checkAvailable();
    return _firestore.collection(collectionPath).doc(docId);
  }

  /// Add a document to a collection
  Future<DocumentReference> addDocument(String collectionPath, Map<String, dynamic> data) {
    _checkAvailable();
    return _firestore.collection(collectionPath).add(data);
  }

  /// Update a document
  Future<void> updateDocument(String collectionPath, String docId, Map<String, dynamic> data) {
    _checkAvailable();
    return _firestore.collection(collectionPath).doc(docId).update(data);
  }

  /// Delete a document
  Future<void> deleteDocument(String collectionPath, String docId) {
    _checkAvailable();
    return _firestore.collection(collectionPath).doc(docId).delete();
  }

  /// Query collection with conditions
  Query queryCollection(String collectionPath) {
    _checkAvailable();
    return _firestore.collection(collectionPath);
  }
}
