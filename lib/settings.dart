import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'policy/terms_of_service.dart';
import 'policy/privacy_policy.dart';
import 'vault_settings.dart';
import 'change_mp.dart';
import 'auto_lock.dart';
import 'alerts.dart';
import 'sort_provider.dart';

class Settings extends StatefulWidget {

  const Settings({
    Key? key,
  }): super(key: key);
  
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  static const platform = MethodChannel('com.ilhanidriss.wan_protector/screen');
  bool _allowScreenshot = true;

  @override
  void initState() {
    super.initState();
    _loadScreenshotPreference();
  }

  void _loadScreenshotPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final allowed = prefs.getBool('allowScreenshot') ?? false;

    setState(() {
      _allowScreenshot = allowed;
    });

    if (!allowed) {
      toggleScreenshot(false);
    }
  }

  //Setting contents
  final List<String> settings = <String>[
    'Show Alert Messages',
    'Auto-Lock',
    'Allow Screenshot',
    'Sort Entries',
    'Vault Settings',
    'Change Master Password',
    'Terms of Service',
    'Privacy Policy',
    'Rate us on Google Play',
    'Report a Bug',
  ];

  //leading icons
  final List<IconData> leadingIcons = <IconData>[
    Icons.notifications_active,
    Icons.lock_clock,
    Icons.screenshot,
    Icons.sort,
    Icons.storage,
    Icons.lock_reset,
    Icons.description,
    Icons.privacy_tip,
    Icons.star_rate,
    Icons.bug_report,
  ];

  //Icons theme
  final List<Color> iconColors = <Color>[
    const Color(0xFF2196F3),
    const Color(0xFF4CAF50),
    const Color(0xFF9C27B0),
    const Color(0xFF607D8B),
    const Color(0xFF607D8B),
    const Color(0xFFFF9800),
    const Color(0xFF3F51B5),
    const Color(0xFF009688),
    const Color(0xFFFFC107),
    const Color(0xFFF44336),
  ];

  //Toggle Screenshot
  Future<void> toggleScreenshot(bool allow) async {
    try {
      await platform.invokeMethod(allow ? 'enableScreenshot' : 'disableScreenshot');
    } catch (e) {
      debugPrint('Failed to toggle screenshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: settings.length,
        itemBuilder: (BuildContext context, int index) {

          final setting = settings[index];

          //Show Alert Messages
          if (setting == 'Show Alert Messages') {

            final alerts = context.watch<AlertsProvider>();

            return SwitchListTile(
              secondary: Icon(leadingIcons[index], color: iconColors[index]),
              title: const Text('Show Alert Messages'),
              subtitle: const Text(
                'Control whether the app shows brief alerts when you perform actions.',
              ),
              value: alerts.showAlerts,
              onChanged: (value) {
                alerts.toggleAlerts(value, context);
              },
            );
          }

          //Auto-Lock
          if (setting == 'Auto-Lock') {

            final autoLock = context.watch<AutoLockState>();

            return SwitchListTile(
              secondary: Icon(leadingIcons[index], color: iconColors[index]),
              title: const Text('Auto-Lock'),
              subtitle: const Text(
                'Lock the app after 1 minute in the background or when your screen is off.',
              ),
              value: autoLock.isAutoLockEnabled,
              onChanged: (value) {
                autoLock.setAutoLockEnabled(value, context);
              },
            );
          }

          //Allow Screenshot
          if (setting == 'Allow Screenshot') {
            return SwitchListTile(
              secondary: Icon(leadingIcons[index], color: iconColors[index]),
              title: const Text('Allow Screenshots'),
              // subtitle: const Text(
              //   'Enable or disable the ability to take screenshots within the app. Turning this off adds extra privacy.',
              // ),
              value: _allowScreenshot,
              onChanged: (value) async {

                final prefs = await SharedPreferences.getInstance();

                setState(() {
                  _allowScreenshot = value;
                  prefs.setBool('allowScreenshot', value);
                  if (value) {
                    //Enable screenshots
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      
                      toggleScreenshot(true);

                      //Snackbar message
                      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                      if (alertsEnabled && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Screenshot Allowed'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }

                    });
                  } else {
                    //Disable screenshots
                    WidgetsBinding.instance.addPostFrameCallback((_) {

                      toggleScreenshot(false);

                      //Snackbar message
                      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                      if (alertsEnabled && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Screenshot Not Allowed'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    });
                  }
                });
              },
            );
          }

          //Sort Entries
          if (setting == 'Sort Entries') {

            final sortProvider = Provider.of<SortProvider>(context);

            return ListTile(
              leading: Icon(leadingIcons[index], color: iconColors[index]),
              title: const Text('Sort Entries by'),
              trailing: DropdownButton<String>(
                value: sortProvider.sortMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'Recently Added', child: Text('Recently Added')),
                  DropdownMenuItem(value: 'Title (A-Z)', child: Text('Title (A-Z)')),
                  DropdownMenuItem(value: 'Username (A-Z)', child: Text('Username (A-Z)'),),
                  DropdownMenuItem(value: 'Last Updated', child: Text('Last Updated')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    sortProvider.setSortMode(value);

                    //Snackbar message
                    final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                    if (alertsEnabled && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Entries Sorted by "$value"'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            );
          }

          return ListTile(
            leading: Icon(
              leadingIcons[index],
              color: iconColors[index],
            ),
            title: Text(settings[index]),
            onTap: () async {
              if (settings[index] == 'Vault Settings') {
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