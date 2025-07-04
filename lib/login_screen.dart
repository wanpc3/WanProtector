import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'encryption_helper.dart';
import 'main.dart';
import 'help.dart';

class LoginScreen extends StatefulWidget {

  const LoginScreen({
    Key? key,
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

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        }
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

    try {
      final storedToken = await _secureStorage.read(key: 'auth_token');
      final decryptedPassword = storedToken != null
          ? await EncryptionHelper.decryptText(storedToken)
          : null;

      if (enteredPassword == decryptedPassword) {
        
        FocusScope.of(context).unfocus();
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) => HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          ),
        );
      } else {
        setState(() {
          _errorText = "Incorrect master password";
        });
      }
    } catch (e) {
      setState(() {
        _errorText = "An error occurred during login";
      });
      debugPrint("Login error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        centerTitle: true,
        title: const Text("Enter Master Password"),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
      ),

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SingleChildScrollView(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [

                      Center(
                        child: Text(
                          "Welcome to WanProtector Password Manager 🔑",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Ubuntu'
                          ),
                        ),
                      ),

                      const SizedBox(height: 18.0),

                      Form(
                        key: _formKey,
                        child: TextFormField(
                          focusNode: _passwordFocusNode,
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _validatePassword(),
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
                          backgroundColor: Colors.amber,
                          foregroundColor: const Color(0xFF212121),
                          minimumSize: const Size(double.infinity, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          "Help",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }
}