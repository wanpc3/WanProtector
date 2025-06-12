import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class PasswordGenerator extends StatefulWidget {
  @override
  _PasswordGeneratorState createState() => _PasswordGeneratorState();
}

class _PasswordGeneratorState extends State<PasswordGenerator> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Random Password Generator',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              readOnly: true,
              enableInteractiveSelection: false,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    final generatedPassword = ClipboardData(text: controller.text);
                    Clipboard.setData(generatedPassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              child: Text('Generate Password'),
              onPressed: () {
                generatePassword();
              },
            )
          ],
        ),
      ),
    );
  }

  void generatePassword() {
    const length = 25;
    const lettersLowercase = 'abcdefghijklmnopqrstuvwxyz';
    const lettersUppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const special = '@#=+!£\$%&(){}[]|:;<>?,./~`^()-=_';

    String chars = lettersLowercase + lettersUppercase + numbers + special;

    final password = List.generate(length, (index) {
      final indexRandom = Random.secure().nextInt(chars.length);
      return chars[indexRandom];
    }).join('');

    setState(() {
      controller.text = password;
    });
  }
}