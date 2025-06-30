import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'policy/terms_of_service.dart';
import 'policy/privacy_policy.dart';
import 'vault_settings.dart';
import 'change_mp.dart';
import 'auto_lock.dart';
import 'alerts.dart';

class Settings extends StatefulWidget {

  const Settings({
    Key? key,
  }): super(key: key);
  
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  //Setting contents
  final List<String> settings = <String>[
    //'App Theme', //Reserve for the next version
    //'Sort Entries', //Reserve for the next version
    'Alerts',
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
    //Icons.palette,
    //Icons.sort,
    Icons.notifications_active_outlined,
    Icons.lock_clock_outlined,
    Icons.storage_outlined,
    Icons.lock_reset_outlined,
    Icons.description_outlined,
    Icons.privacy_tip_outlined,
    Icons.star_rate_outlined,
    Icons.bug_report_outlined,
  ];

  //Icons theme
  final List<Color> iconColors = <Color>[
    const Color(0xFF2196F3),
    const Color(0xFF4CAF50),
    const Color(0xFF607D8B),
    const Color(0xFFFF9800),
    const Color(0xFF3F51B5),
    const Color(0xFF009688),
    const Color(0xFFFFC107),
    const Color(0xFFF44336),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: settings.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: Icon(
              leadingIcons[index],
              color: iconColors[index],
            ),
            title: Text(settings[index]),
            onTap: () async {
              if (settings[index] == 'Alerts') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => Alerts(),
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

                final confirmed = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                        return AlertDialog(
                            title: const Text("Important Notice"),
                            content: const Text(
                                "After changing your master password:\n\n"
                                "• You will still be able to restore any backups created after the change.\n"
                                "• Backups made before the change will require the old master password.\n"
                                "• It is recommended to create a new backup after updating your master password."
                            ),
                            actions: [
                                TextButton(
                                  child: const Text("Cancel"),
                                  onPressed: () => Navigator.of(context).pop(false),
                                ),
                                TextButton(
                                  child: const Text("I Understand"),
                                  onPressed: () => Navigator.of(context).pop(true),
                                ),
                            ],
                        );
                    }
                );

                if (confirmed == true) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => ChangeMp(),
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
                }
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