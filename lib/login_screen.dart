import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'help.dart';

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
  final FocusNode _passwordFocusNode = FocusNode();
  final _secureStorage = const FlutterSecureStorage();
  String? _errorText;
  bool _isLoading = false;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_passwordFocusNode);
      });
    });

    _passwordController.addListener(() {
      if (_errorText != null) {
        setState(() {
          _errorText = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword() async {
    final enteredPassword = _passwordController.text;
    final storedPassword = await _secureStorage.read(key: 'auth_token');

    if (enteredPassword == storedPassword) {
      setState(() {
        _isLoading = true;
      });

      // Dismiss keyboard
      FocusScope.of(context).unfocus();

      // Short delay to show loading spinner
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return; // To avoid calling Navigator after dispose

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => HomeScreen(toggleTheme: widget.toggleTheme),
          transitionsBuilder: (_, animation, __, child) {
            final offsetAnimation = Tween<Offset>(
              begin: Offset(0.0, 1.0), // from bottom
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Incorrect master password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text("Login Vault"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [

                  Center(
                    child: Text(
                      "Welcome to WanProtector Password Manager!",
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Ubuntu'
                      ),
                    ),
                  ),

                  Form(
                    key: _formKey,
                    child: TextFormField(
                      focusNode: _passwordFocusNode,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Master Password",
                        errorText: _errorText,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        )
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter master password";
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _validatePassword();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF085465),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("OK"),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Help()
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: const Color(0xFF808080),
                    ),
                    child: const Text("Help"),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}