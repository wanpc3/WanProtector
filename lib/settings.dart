import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'policy/terms_of_service.dart';
import 'policy/privacy_policy.dart';
import 'app_theme.dart';
import 'vault_settings.dart';
import 'change_mp.dart';
import 'auto_lock.dart';

class Settings extends StatefulWidget {
  final VoidCallback toggleTheme;

  Settings({
    required this.toggleTheme
  });
  
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  //Setting contents
  final List<String> settings = <String>[
    'App Theme',
    //'Sort Entries', //Reserve for the next version
    'Auto-Lock',
    'Vault Settings',
    'Change Master Password',
    'Terms of Service',
    'Privacy Policy',
    'Rate us on Google Play',
    'Report a Bug',
  ];

  //leading icons
  final List<IconData> leadingIcons = <IconData>[
    Icons.palette,
    //Icons.sort,
    Icons.lock_clock,
    Icons.storage,
    Icons.lock_reset,
    Icons.description,
    Icons.privacy_tip,
    Icons.star_rate,
    Icons.bug_report,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: settings.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: Icon(leadingIcons[index]),
            title: Text(settings[index]),
            onTap: () {
              if (settings[index] == 'App Theme') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => AppTheme(),
                    transitionsBuilder:(context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              } else if (settings[index] == 'Auto-Lock') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => AutoLock(),
                    transitionsBuilder:(context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              } else if (settings[index] == 'Vault Settings') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => VaultSettings(),
                    transitionsBuilder:(context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              } else if (settings[index] == 'Change Master Password') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => ChangeMp(
                      toggleTheme: widget.toggleTheme
                    ),
                    transitionsBuilder:(context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              } else if (settings[index] == 'Terms of Service') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => TermsOfService(),
                    transitionsBuilder:(context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              } else if (settings[index] == 'Privacy Policy') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => PrivacyPolicy(),
                    transitionsBuilder:(context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              } else if (settings[index] == 'Rate us on Google Play') {
                _rateOnGooglePlay();
              } else if (settings[index] == 'Report a Bug') {
                _reportBug();
              }
            },
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
    );
  }

  //Rate on Google Play
  Future<void> _rateOnGooglePlay() async {
    const url = 'https://play.google.com/store/apps/details?id=com.ilhanidriss.wan_protector';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  //Report a Bug
  Future<void> _reportBug() async {
    final String subject = Uri.encodeComponent('Report a Bug - WanProtector');
    final String body = Uri.encodeComponent('Hello WanProtector team,\n\n');

    final String emailUri = 'mailto:idrissilhan@gmail.com?subject=$subject&body=$body';

    try {
      await launchUrl(Uri.parse(emailUri), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email app. Please email idrissilhan@gmail.com manually.')),
        );
      }
    }
  }
}