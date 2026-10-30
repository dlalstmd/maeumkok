import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _initialized = false;

  /// Firebase 콘솔 > Authentication > Google > 웹 클라이언트 ID.
  /// `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` 로 주입.
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '101787008056-92b0ch0tm5ouhng0bc35ccbjfonv231r.apps.googleusercontent.com',
  );

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureInit();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    await _upsertUser(result.user!);
    return result;
  }

  /// Apple 로그인 (iOS 네이티브 시트, Firebase AppleAuthProvider)
  Future<UserCredential> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final result = await _auth.signInWithProvider(provider);
    await _upsertUser(result.user!);
    return result;
  }

  Future<void> _upsertUser(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    final data = <String, Object?>{
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!snap.exists) data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _ensureInit();
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
