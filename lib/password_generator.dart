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
    '"I recommend using passwords of twenty-five characters or more." - Kevin Mitnick, *The Art of Invisibility*',
    '"The more characters in your password, the longer it will take password-guessing programs to run through all the possible variations." - Kevin Mitnick, *The Art of Invisibility*',
    '"Passwords should be long, unpredictable, and unique for every account." - Troy Hunt, *Have I Been Pwned*',
    "Avoid using your birthdate, pet names, or common words in passwords.",
    "Update your passwords for financial or email accounts every 6–12 months.",
    "Reusing the same password? That's how hackers gain access to multiple accounts.",
    "A passphrase like 'CoffeeTableRains@7am' is easier to remember and harder to crack.",
    "The longer your password, the harder it is to brute-force. Aim for 16+ characters.",
    "Don’t rely on browser-saved passwords. Use a real password manager.",
    "Use 2FA (Two-Factor Authentication) wherever possible for added security.",
    "A mix of letters, numbers, and symbols boosts password strength.",
    "Avoid patterns like 'abcd', '1234', or keyboard walks like 'qwerty'.",
    "Hackers love simple passwords. Make yours complex and unpredictable.",
    "Got hacked? Change your password *immediately* on all reused accounts.",
    "Avoid storing passwords in notes apps or text files.",
    "Security questions are weak points—treat them like passwords too.",
    "Don't copy others. Your password should be unique, like your fingerprint.",
    "Even strong passwords become weak if reused. Generate a fresh one.",
    "A password manager remembers complex passwords, so you don’t have to.",
    "Never share your password—even with people you trust.",
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
                backgroundColor: const Color(0xFF0A708A),
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