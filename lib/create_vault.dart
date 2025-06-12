import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_screen.dart';

class CreateVault extends StatefulWidget {
  final VoidCallback toggleTheme;

  const CreateVault({
    Key? key, 
    required this.toggleTheme
  }) : super(key: key);

  @override
  _CreateVaultScreen createState() => _CreateVaultScreen();
}

class _CreateVaultScreen extends State<CreateVault> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _secureStorage = FlutterSecureStorage();

  void _savePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Master Passwords do not match')),
      );
      return;
    }

    //Save securely in Flutter Secure Storage
    await _secureStorage.write(key: 'auth_token', value: password);

    //Save to SQLite storage
    final now = DateTime.now().toIso8601String();
    await Databasehelper().insertMasterPassword(password, now, now);

    //Navigate to login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(toggleTheme: widget.toggleTheme)
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            
            Center(
              child: Text("Let's create a new Vault!"),
            ),

            //Master Password
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Master Password',
                filled: true,
                fillColor: Color(0xFFF5FCF9),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 16.0,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 6) {
                  return 'Enter at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm Master Password',
                filled: true,
                fillColor: Color(0xFFF5FCF9),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 16.0,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                   _savePassword();
                }
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF085465),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: const StadiumBorder(),
              ),
              child: const Text("Create Vault"),
            ),
          ],
        ),
      ),
    );
  }
}
