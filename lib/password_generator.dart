import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class PasswordGenerator extends StatefulWidget {
  @override
  _PasswordGeneratorState createState() => _PasswordGeneratorState();
}

class _PasswordGeneratorState extends State<PasswordGenerator> {
  final controller = TextEditingController();

  int passwordLength = 25;
  bool includeUppercase = true;
  bool includeLowercase = true;
  bool includeNumbers = true;
  bool includeSpecial = true;

  final tips = [
    '"I recommend using passwords of twenty-five characters or more." – Kevin Mitnick, *The Art of Invisibility*',
    '"The more characters in your password, the longer it will take password-guessing programs to run through all the possible variations." – Kevin Mitnick, *The Art of Invisibility*',
    "Avoid using your birthdate or names in passwords",
    "Use a password manager to avoid reusing passwords",
    "Update important passwords regularly"
  ];

  int currentTipIndex = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void generatePassword() {
    String chars = '';
    if (includeLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (includeNumbers) chars += '0123456789';
    if (includeSpecial) chars += '@#=+!£\$%&(){}[]|:;<>?,./~`^()-=_';

    if (chars.isEmpty) {
      controller.text = "Select at least 1 option.";
      return;
    }

    final password = List.generate(passwordLength, (index) {
      final indexRandom = Random.secure().nextInt(chars.length);
      return chars[indexRandom];
    }).join('');

    setState(() {
      controller.text = password;
    });
  }

  void rotateTip() {
    setState(() {
      currentTipIndex = (currentTipIndex + 1) % tips.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const Text(
              'Generate Secure Password',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              readOnly: true,
              enableInteractiveSelection: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: controller.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text("Password Length: $passwordLength"),
            Slider(
              value: passwordLength.toDouble(),
              min: 6,
              max: 64,
              divisions: 58,
              label: passwordLength.toString(),
              onChanged: (value) {
                setState(() {
                  passwordLength = value.toInt();
                });
              },
            ),

            CheckboxListTile(
              title: const Text("Include Uppercase"),
              value: includeUppercase,
              onChanged: (val) => setState(() => includeUppercase = val!),
            ),
            CheckboxListTile(
              title: const Text("Include Lowercase"),
              value: includeLowercase,
              onChanged: (val) => setState(() => includeLowercase = val!),
            ),
            CheckboxListTile(
              title: const Text("Include Numbers"),
              value: includeNumbers,
              onChanged: (val) => setState(() => includeNumbers = val!),
            ),
            CheckboxListTile(
              title: const Text("Include Special Characters"),
              value: includeSpecial,
              onChanged: (val) => setState(() => includeSpecial = val!),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF085465),
                foregroundColor: Colors.white,
              ),
              child: const Text('Generate Password'),
              onPressed: generatePassword,
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tips[currentTipIndex],
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: rotateTip,
                  tooltip: "New tip",
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}