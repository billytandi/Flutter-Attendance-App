import 'package:firebase_auth/firebase_auth.dart';

class AuthViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      // Handle error
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
