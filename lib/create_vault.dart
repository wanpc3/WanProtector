import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'models/master_password.dart';
import 'vault.dart';
import 'login_screen.dart';
import 'encryption_helper.dart';
import 'policy/terms_of_service.dart';
import 'policy/privacy_policy.dart';

class CreateVault extends StatefulWidget {

  const CreateVault({
    Key? key,
  }) : super(key: key);

  @override
  _CreateVaultScreen createState() => _CreateVaultScreen();
}

class _CreateVaultScreen extends State<CreateVault> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _secureStorage = FlutterSecureStorage();
  
  bool _obscurePassword_1 = true;
  bool _obscurePassword_2 = true;
  bool isChecked = false;
  bool isCheckboxValid = true;

  void _savePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Master Passwords do not match')),
      );
      return;
    }

    final now = DateTime.now().toIso8601String();

    //1) Encrypt and save using model
    final masterPassword = MasterPassword(
      id: 1,
      password: password,
      createdAt: now,
      lastUpdated: now,
    );

    await Vault().insertMasterPassword(
      password,
      masterPassword.createdAt,
      masterPassword.lastUpdated,
    );

    //2) Also store it in secure storage for auto login
    final encryptedPassword = await EncryptionHelper.encryptText(password);
    await _secureStorage.write(key: 'auth_token', value: encryptedPassword);

    //3) Go to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text("Create Vault"),
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                
                Center(
                  child: const Text(
                    "Let's create a new Vault!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                //Master Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword_1,
                  decoration: InputDecoration(
                    hintText: 'Master Password',
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

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword_2,
                  decoration: InputDecoration(
                    hintText: 'Confirm Master Password',
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
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                //Important notes
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    //color: const Color(0xFF121212),
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: const Text(
                          "Important notes:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      const Text(
                        "1. Always remember your master password."
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "2. Never share your master password with anyone else."
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "3. This password manager stores all your passwords locally on your device. We recommend backing up your vault to prevent data loss."
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                //Checkboxes
                Row(
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: (value) => setState(() {
                        isChecked = value ?? false;
                        isCheckboxValid = true;
                      }),
                      checkColor: Colors.white,
                      activeColor: Colors.green,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: "I have read the important notes above, and I agree with WanProtector's ",
                          style: TextStyle(color: Colors.black),
                          children: [

                            //Terms of Service
                            TextSpan(
                              text: "Terms of Service",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TermsOfService(),
                                  ),
                                );
                              },
                            ),

                            const TextSpan(text: " and "),

                            //Privacy Policy
                            TextSpan(
                              text: "Privacy Policy",
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacyPolicy(),
                                  ),
                                );
                              }
                            ),
                            const TextSpan(text: "."),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (!isCheckboxValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "You must agree to the terms of service and privacy policy.",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: () {
                    final isFormValid = _formKey.currentState!.validate();

                    if (!isChecked) {
                      setState(() {
                        isCheckboxValid = false;
                      });
                    }

                    if (isFormValid && isChecked) {
                      _savePassword();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    "Create Vault",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
