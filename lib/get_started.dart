import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'create_vault.dart';
import 'dart:io';

class GetStarted extends StatefulWidget {
  const GetStarted({
    Key? key,
  }) : super(key: key);

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  DateTime? _lastBackPressed;
  int pageCount = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        final isExiting = _lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2);

        if (isExiting) {
          _lastBackPressed = now;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Press back again to exit'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
          return false;
        }

        //Exit the app
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        } else {
          exit(0);
        }

        return true;
      },
      child: Scaffold(

        //Appbar
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Welcome to WanProtector!'),
          backgroundColor: const Color(0xFF424242),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 14,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 2,
                  onPageChanged: (value) {
                    setState(() {
                      pageCount = value;
                    });
                  },
                  itemBuilder: (context, index) {
                    final cardColor = Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF212121)
                        : Colors.white;

                    final pointTitleColor = Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0), // Added vertical padding
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index == 0) ...[
                                Text(
                                  "Get Started with WanProtector Password Manager 🔑",
                                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24.0),
                                ...description.take(3).map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item["title"],
                                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: pointTitleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        item["text"],
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ] else if (index == 1) ...[
                                // Text(
                                //   "Key Features",
                                //   style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                //     fontWeight: FontWeight.bold,
                                //     color: textColor,
                                //   ),
                                //   textAlign: TextAlign.center,
                                // ),
                                const SizedBox(height: 24.0),
                                ...description.sublist(3, 8).map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item["title"],
                                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: pointTitleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        item["text"],
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  2,
                  (index) => DotIndicator(
                    isActive: index == pageCount,
                    activeColor: Colors.amber,
                    inActiveColor: textColor.withOpacity(0.5),
                  ),
                ),
              ),

              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: const Color(0xFF212121),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => CreateVault(),
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
          ),
        ),
      ),
    );
  }
}

class DotIndicator extends StatelessWidget {
  const DotIndicator({
    super.key,
    this.isActive = false,
    this.activeColor = Colors.amber,
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
      width: isActive ? 20 : 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inActiveColor.withOpacity(0.5),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
    );
  }
}

//description of each get started page
List<Map<String, dynamic>> description = [
  //Slide 1: Get Started with WanProtector Password Manager
  {
    "title": "✅ Secure your account",
    "text": "WanProtector is a standalone password manager application. It keeps your passwords safe, securely and easily.",
  },
  {
    "title": "✅ Protect passwords at all costs",
    "text": "WanProtector stores your passwords in a secure vault that only you can access using a special key called the master password.",
  },
  {
    "title": "✅ Saved and encrypted",
    "text": "WanProtector will ensure that all your passwords are fully secured and encrypted, reducing your worries about data loss or breaches.",
  },

  //Slide 2: Key Features
  {
    "title": "🔐 Encrypted Vault",
    "text": "Your vault is protected with secure AES-256 encryption.",
  },
  {
    "title": "📥 Backup / Restore",
    "text": "Safely back up your vault and restore it when needed.",
  },
  {
    "title": "🔑 Password Generator",
    "text": "Quickly generate secure passwords to protect all your accounts in just a few seconds.",
  },
  {
    "title": "🗑️ Delete & Restore",
    "text": "Easily delete entries and restore them when needed.",
  },
  {
    "title": "⏱️ Auto-Lock",
    "text": "Automatically locks the app after 1 minute of inactivity or when the screen turns off.",
  },
];