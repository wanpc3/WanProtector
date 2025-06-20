import 'package:flutter/material.dart';
import 'create_vault.dart';

class GetStarted extends StatefulWidget {
  final VoidCallback toggleTheme;

  const GetStarted({
    super.key,
    required this.toggleTheme
  });

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  int pageCount = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              flex: 14,
              child: PageView.builder(
                itemCount: description.length,
                onPageChanged: (value) {
                  setState(() {
                    pageCount = value;
                  });
                },
                itemBuilder: (context, index) => GetStartedContent(
                  illustration: description[index]["illustration"],
                  title: description[index]["title"],
                  text: description[index]["text"],
                ),
              ),
            ),

            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                description.length,
                (index) => DotIndicator(isActive: index == pageCount),
              ),
            ),

            const Spacer(flex: 2),
            //Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text("Get Started".toUpperCase()),
                onPressed: () async {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => CreateVault(
                        toggleTheme: widget.toggleTheme,
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      }
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
          ],
        )
      )
    );
  }
}

class GetStartedContent extends StatelessWidget {
  const GetStartedContent({
    super.key,
    required this.illustration,
    required this.title,
    required this.text,
  });

  final String illustration, title, text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset(
              illustration,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class DotIndicator extends StatelessWidget {
  const DotIndicator({
    super.key,
    this.isActive = false,
    this.activeColor = const Color.fromARGB(255, 73, 73, 73),
    this.inActiveColor = const Color(0xFF868686),
  });

  final bool isActive;
  final Color activeColor, inActiveColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16 / 2),
      height: 5,
      width: 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inActiveColor.withOpacity(0.25),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
    );
  }
}

//description of each get started page
List<Map<String, dynamic>> description = [
  {
    "illustration": "assets/get_started_1.png",
    "title": "Secure your account",
    "text": "WanProtector is a standalone password manager application. It keeps your passwords safe, securely and easily.",
  },
  {
    "illustration": "assets/get_started_2.png",
    "title": "Protect passwords at all costs",
    "text": "WanProtector stores your passwords in a secure vault that only you can access using a special key called the master password.",
  },
  {
    "illustration": "assets/get_started_3.png",
    "title": "Saved and encrypted",
    "text": "WanProtector will ensure that all your passwords are fully secured and encrypted, reducing your worries about data loss or breaches.",
  },
];