import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'vault.dart';
import 'login_screen.dart';

class ChangeMp extends StatefulWidget {
  final VoidCallback toggleTheme;

  const ChangeMp({
    super.key,
    required this.toggleTheme
  });

  @override
  _ChangeMpScreen createState() => _ChangeMpScreen();
}

class _ChangeMpScreen extends State<ChangeMp> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _secureStorage = FlutterSecureStorage();

  bool _obscurePassword_1 = true;
  bool _obscurePassword_2 = true;
  bool _obscurePassword_3 = true;

  void _savePassword() async {
    final currentPasswordInput = _currentPasswordController.text;
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Master Passwords do not match')),
      );
      return;
    }

    //Fetch stored password
    String? storedPassword = await _secureStorage.read(key: 'auth_token');

    //Verify current password
    if (storedPassword != currentPasswordInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Current Master Password is incorrect')),
      );
      return;
    }

    //Save securely in Flutter Secure Storage
    await _secureStorage.write(key: 'auth_token', value: newPassword);

    //Save to SQLite storage
    await Vault().updateMasterPassword(newPassword);

    //Alert user so they know they will be logged out
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Master Password changed. Logging out...'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(toggleTheme: widget.toggleTheme),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text("Change Master Password"),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                //Current Master Password
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscurePassword_1,
                  decoration: InputDecoration(
                    hintText: 'Current Master Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword_1 ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword_1 = !_obscurePassword_1;
                        });
                      },
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
                
                //New Master Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword_2,
                  decoration: InputDecoration(
                    hintText: 'New Master Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword_2 ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword_2 = !_obscurePassword_2;
                        });
                      },
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

                //Confirm Master Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm Master Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword_3 ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword_3 = !_obscurePassword_3;
                        });
                      },
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
                  child: const Text("Change Master Password"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}