import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const LoginScreen({
    Key? key, 
    required this.toggleTheme
  }) : super(key: key);
  
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  void _validatePassword() async {
    final enteredPassword = _passwordController.text;
    final storedPassword = await _secureStorage.read(key: 'auth_token');

    if (enteredPassword == storedPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful')),
      );

      Navigator.pushReplacement(
      context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(toggleTheme: widget.toggleTheme)
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid Master Password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Image.network(
                MediaQuery.of(context).platformBrightness == Brightness.light
                    ? "https://i.postimg.cc/nz0YBQcH/Logo-light.png"
                    : "https://i.postimg.cc/MHH0DKv1/Logo-dark.png",
                height: 146,
              ),
              const Spacer(),

              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Master Password"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter master password";
                    }
                    return null;
                  },
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: _validatePassword,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF085465),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const StadiumBorder(),
                ),
                child: const Text("OK"),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const StadiumBorder(),
                  backgroundColor: const Color(0xFF808080),
                ),
                child: const Text("Help"),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}