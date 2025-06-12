import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'policy/terms_of_service.dart';
import 'policy/privacy_policy.dart';
import 'app_theme.dart';
import 'vault_settings.dart';
import 'change_mp.dart';

class Settings extends StatefulWidget {
  final VoidCallback toggleTheme;

  Settings({required this.toggleTheme});
  
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  final List<String> settings = <String>[
    'App Theme',
    'Auto-Lock',
    'Vault Settings',
    'Change Master Password',
    'Terms of Service',
    'Privacy Policy',
    'Rate us on Google Play',
    'Report a Bug',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: settings.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(settings[index]),
            onTap: () {
              if (settings[index] == 'App Theme') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppTheme(toggleTheme: widget.toggleTheme),
                  ),
                );
              } else if (settings[index] == 'Vault Settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VaultSettings(),
                  ),
                );
              } else if (settings[index] == 'Change Master Password') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeMp(toggleTheme: widget.toggleTheme),
                  ),
                );
              } else if (settings[index] == 'Terms of Service') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TermsOfService(),
                  ),
                );
              } else if (settings[index] == 'Privacy Policy') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivacyPolicy(),
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
    const url = 'https://play.google.com/store/apps/details?id=com.example.wan_protector';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  //Report a Bug
  Future<void> _reportBug() async {
    try {
      final Uri uri = Uri(
        scheme: 'mailto',
        path: 'idrissilhan@gmail.com',
        queryParameters: {
          'subject': 'Report a Bug - WanProtector',
          'body': 'Hello WanProtector team,\n\n',
        },
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No email app found. Please contact us at idrissilhan@gmail.com')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: ${e.toString()}')),
        );
      }
    }
  }

  //Email formatter
  String buildMailtoUri({
    required String email,
    String? subject,
    String? body,
  }) {
    String uri = 'mailto:$email';
    List<String> queryParams = [];

    if (subject != null && subject.isNotEmpty) {
      queryParams.add('subject=${Uri.encodeComponent(subject)}');
    }
    if (body != null && body.isNotEmpty) {
      queryParams.add('body=${Uri.encodeComponent(body)}');
    }

    if (queryParams.isNotEmpty) {
      uri += '?${queryParams.join('&')}';
    }

    return uri;
  }

}