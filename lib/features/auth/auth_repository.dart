import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  Stream<UserModel?> userDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = 'customer',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final newUser = UserModel(
      uid: cred.user!.uid,
      name: name,
      phone: phone,
      email: email,
      avatar: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=$name',
      balance: 0,
      role: role,
    );

    await _firestore
        .collection('users')
        .doc(cred.user!.uid)
        .set(newUser.toMap());

    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateBalance(String uid, double amount) async {
    await _firestore.collection('users').doc(uid).update({
      'wallet.balance': FieldValue.increment(amount),
    });
    await _firestore.collection('transactions').add({
      'userId': uid,
      'amount': amount,
      'type': 'topup',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'profile.name': name,
      'profile.phone': phone,
    });
  }

  // Xác thực lại với mật khẩu hiện tại — Firebase yêu cầu trước khi đổi mật khẩu
  Future<void> reauthenticate(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user found');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');
    await user.updatePassword(newPassword);
  }

  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
