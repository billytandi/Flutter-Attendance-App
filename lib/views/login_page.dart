import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart'; // Halaman Home yang telah kamu buat

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S-Life'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Masukkan email',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Masukkan password',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                      TextButton(
                        onPressed: _showPasswordResetDialog,
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
            const SizedBox(height: 16.0),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  // Fungsi login
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Jika login berhasil, arahkan ke halaman Home
      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login gagal. Periksa email dan password Anda.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Dialog untuk reset password
  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _resetEmailController =
            TextEditingController();

        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: _resetEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Masukkan email untuk reset password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _resetPassword(_resetEmailController.text.trim());
                Navigator.of(context).pop(); // Close dialog after request
              },
              child: const Text('Reset Password'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi reset password
  Future<void> _resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email has been sent.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error sending password reset email. Please try again.'),
        ),
      );
    }
  }
}
