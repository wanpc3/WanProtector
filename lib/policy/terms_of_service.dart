import 'package:flutter/material.dart';
import 'tos_page.dart';

class TermsOfService extends StatelessWidget {
  const TermsOfService({
    super.key
  });

  //Static enforcement date
  static const String enforceDate = "May 1, 2025";
  static const String lastUpdatedDate = "May 1, 2025";
  static const String developerName = "ILHAN IDRISS";
  static const String emailAddress = "idrissilhan@gmail.com";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar
      appBar: AppBar(
        title: const Text(
          "Terms of Service",
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //Header
              Text(
                TermsOfServicePage.tos_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              //Date of enforcement
              Text(
                "Effective Date: $enforceDate",
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),

              //Last Updated Date
              Text(
                "Last Updated: $lastUpdatedDate",
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),

              //Developer name
              Text(
                "Developer: $developerName",
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),

              //Contact email
              Text(
                "Contact Email: $emailAddress",
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 20),

              //1. Acceptance of Terms
              Text(
                TermsOfServicePage.tos_1_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_1_text,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //2. About the App
              Text(
                TermsOfServicePage.tos_2_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_2_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_2_text2,
                style: TextStyle(fontSize: 16),
              ),
              Text(
                TermsOfServicePage.tos_2_text3,
                style: TextStyle(fontSize: 16),
              ),
              Text(
                TermsOfServicePage.tos_2_text4,
                style: TextStyle(fontSize: 16),
              ),
              Text(
                TermsOfServicePage.tos_2_text5,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //3. User Data and Privacy
              Text(
                TermsOfServicePage.tos_3_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_3_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_3_text2,
                style: TextStyle(fontSize: 16),
              ),
              Text(
                TermsOfServicePage.tos_3_text3,
                style: TextStyle(fontSize: 16),
              ),
              Text(
                TermsOfServicePage.tos_3_text4,
                style: TextStyle(fontSize: 16),
              ),
              Text(
                TermsOfServicePage.tos_3_text5,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //4. User Responsibilities
              Text(
                TermsOfServicePage.tos_4_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_4_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_4_text2,
                style: TextStyle(fontSize: 16),
              ),
              Text(
                TermsOfServicePage.tos_4_text3,
                style: TextStyle(fontSize: 16),
              ),
              Text(
                TermsOfServicePage.tos_4_text4,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //5. Children's Use
              Text(
                TermsOfServicePage.tos_5_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_5_text,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //6. Intellectual Property
              Text(
                TermsOfServicePage.tos_6_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_6_text,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //7. Disclaimer
              Text(
                TermsOfServicePage.tos_7_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_7_text,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //8. Limitation of Liability
              Text(
                TermsOfServicePage.tos_8_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_8_text,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //9. Changes to the Terms
              Text(
                TermsOfServicePage.tos_9_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_9_text,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //10. Contact
              Text(
                TermsOfServicePage.tos_10_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                TermsOfServicePage.tos_10_text,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                emailAddress,
                style: TextStyle(fontSize: 16),
              ),

            ],
          ),
        ),
      ),
    );
  }
}