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
        backgroundColor: const Color(0xFFC0C0C0),
        foregroundColor: Colors.black,
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
              const SizedBox(height: 4.0),
              /*
              Text(
                HelpPage.help_2_text5,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4.0),
              */
              Text(
                HelpPage.help_2_text6,
                style: TextStyle(fontSize: 16),
              ),

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
              const SizedBox(height: 4.0),
              Text(
                HelpPage.help_4_text2,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4.0),
              Text(
                HelpPage.help_4_text3,
                style: TextStyle(fontSize: 16),
              ),

            ],
          ),
        ),
      ),
    );      
  }
}