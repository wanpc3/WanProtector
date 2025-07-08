import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'help_page.dart';

class Help extends StatelessWidget {
  const Help({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //Appbar
      appBar: AppBar(
        title: Text(
          HelpPage.help_page,
        ),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //Header
              Text(
                HelpPage.help_page_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              //1. I forgot my master password. How do I reset it?
              Text(
                HelpPage.help_1_title,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                HelpPage.help_1_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16.0),
              Text(
                HelpPage.help_1_text2,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16.0),
              Text(
                HelpPage.help_1_text3,
                style: TextStyle(fontSize: 16),
              ),
              // const SizedBox(height: 16.0),
              // Text(
              //   HelpPage.help_1_text4,
              //   style: TextStyle(fontSize: 16),
              // ),
              const SizedBox(height: 20.0),

              //2. Trouble Logging In?
              Text(
                HelpPage.help_2_title,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                HelpPage.help_2_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4.0),
              Text(
                HelpPage.help_2_text2,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4.0),
              Text(
                HelpPage.help_2_text3,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4.0),
              Text(
                HelpPage.help_2_text4,
                style: TextStyle(fontSize: 16),
              ),
              //const SizedBox(height: 4.0),
              /*
              Text(
                HelpPage.help_2_text5,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4.0),
              */
              /*
              Text(
                HelpPage.help_2_text6,
                style: TextStyle(fontSize: 16),
              ),
              */

              const SizedBox(height: 20.0),

              //3. Biometric Not Working?
              /*
              Text(
                HelpPage.help_3_title,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                HelpPage.help_3_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4.0),
              Text(
                HelpPage.help_3_text2,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20.0),
              */

              //4. Need More Help?
              Text(
                HelpPage.help_4_title,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                HelpPage.help_4_text1,
                style: TextStyle(fontSize: 16),
              ),
              
              const SizedBox(height: 8.0),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5, // 50% of the screen
                height: 40, // Optional: set fixed height
                child: ElevatedButton(
                  onPressed: () => _contactUs(context),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFEF5350),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Contact us'),
                ),
              ),

              /*
              Text(
                HelpPage.help_4_text2,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4.0),
              Text(
                HelpPage.help_4_text3,
                style: TextStyle(fontSize: 16),
              ),
              */
            ],
          ),
        ),
      ),
    );
  }

  //Contact WanProtector
  Future<void> _contactUs(BuildContext context) async {
    final String subject = Uri.encodeComponent('Contact - WanProtector');
    final String body = Uri.encodeComponent('Hello WanProtector team,\n\n');

    final String emailUri = 'mailto:idrissilhan@gmail.com?subject=$subject&body=$body';

    try {
      await launchUrl(Uri.parse(emailUri), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open email app. Please email idrissilhan@gmail.com manually.')),
      );
    }
  }
}