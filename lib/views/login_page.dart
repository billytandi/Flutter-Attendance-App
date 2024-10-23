import 'package:flutter/material.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthViewModel _authViewModel = AuthViewModel();
  String? _errorMessage;

  void _login() async {
    var user = await _authViewModel.login(_emailController.text.trim(), _passwordController.text.trim());
    if (user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
    } else {
      setState(() {
        _errorMessage = 'Login gagal. Periksa email dan password Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Password')),
            ElevatedButton(onPressed: _login, child: Text('Login')),
            if (_errorMessage != null) Text(_errorMessage!, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
