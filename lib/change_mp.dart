import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'encryption_helper.dart';
import 'vault.dart';
import 'login_screen.dart';

class ChangeMp extends StatefulWidget {

  const ChangeMp({
    Key? key,
  }): super(key: key);

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
  bool isChecked = false;
  bool isCheckboxValid = true;

  String? _currentPasswordError;

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

    final isVerified = await Vault().verifyMasterPassword(currentPasswordInput);
    if (!isVerified) {
      setState(() {
        _currentPasswordError = 'Current Master Password is incorrect';
      });
      return;
    } else {
      setState(() {
        _currentPasswordError = null;
      });
    }

    //Alert before proceed
    final confirm = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Change Master Password'),
        content: const Text('You are about to change your master password. Do you wish to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      //1) Update password via Vault with encryption
      await Vault().updateMasterPassword(newPassword);

      //2) Overwrite secure token
      final encryptedNewPassword = await EncryptionHelper.encryptText(newPassword);
      await _secureStorage.write(key: 'auth_token', value: encryptedNewPassword);

      //3) Force logout for security reasons
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Your master password has been changed. For security reasons, you will now be logged out.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text("Change Master Password"),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
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
                    labelText: "Current Master Password",
                    hintText: 'Current Master Password',
                    errorText: _currentPasswordError,
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
                    labelText: "New Master Password",
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
                  obscureText: _obscurePassword_3,
                  decoration: InputDecoration(
                    labelText: "Confirm Master Password",
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

                const SizedBox(height: 24),

                // Warning to change master password
                Center(
                  child: SizedBox(
                    width: 350.0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade700, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Warning 1
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  "You are about to change your master password.",
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16.0),

                          //Warning 2
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  "Always remember your master password. Never share it with anyone else.",
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                //const SizedBox(height: 16),

                //Checkbox
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
                      child: Text(
                        "I have read and understand the notes above.",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                        ),
                      ),
                    )
                  ],
                ),

                if (!isCheckboxValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0, left: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "You must agree with this",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

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
                    backgroundColor: Colors.amber,
                    foregroundColor: const Color(0xFF212121),
                    minimumSize: const Size(double.infinity, 48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    "Change Master Password",
                    style: TextStyle(fontWeight: FontWeight.w600)
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