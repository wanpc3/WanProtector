import 'package:flutter/material.dart';
import 'policy_page.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({
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
          "Privacy Policy",
        ),
        backgroundColor: Colors.black,
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
                "Privacy Policy",
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

              //1. Introduction Header
              Text(
                PolicyPage.introduction_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //Introduction Text
              Text(
                PolicyPage.introduction_text,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //2. Information We Collect - Header
              Text(
                PolicyPage.info_collect_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //Information We Collect - Text1
              Text(
                PolicyPage.info_collect_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //Information We Collect - Text2
              Text(
                PolicyPage.info_collect_text2,
                style: TextStyle(fontSize: 16),
              ),
              //Information We Collect - Text3
              Text(
                PolicyPage.info_collect_text3,
                style: TextStyle(fontSize: 16),
              ),
              //Information We Collect - Text4
              Text(
                PolicyPage.info_collect_text4,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //Information We Collect - Text5
              Text(
                PolicyPage.info_collect_text5,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //3. How We Use Your Information - Header
              Text(
                PolicyPage.use_info_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //How We Use Your Information - Text1
              Text(
                PolicyPage.use_info_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //How We Use Your Information - Text2
              Text(
                PolicyPage.use_info_text2,
                style: TextStyle(fontSize: 16),
              ),
              //How We Use Your Information - Text3
              Text(
                PolicyPage.use_info_text3,
                style: TextStyle(fontSize: 16),
              ),
              //How We Use Your Information - Text4
              Text(
                PolicyPage.use_info_text4,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //Information We Collect - Text5
              Text(
                PolicyPage.info_collect_text5,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //4. Data Security and Storage - Header
              Text(
                PolicyPage.data_storage_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //Data Security and Storage - Text1
              Text(
                PolicyPage.data_storage_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //Data Security and Storage - Text2
              Text(
                PolicyPage.data_storage_text2,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //5. Children's Privacy
              Text(
                PolicyPage.child_privacy_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //Children's Privacy - Text1
              Text(
                PolicyPage.child_privacy_text,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //6. Third-Party Services
              Text(
                PolicyPage.third_party_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //Third-Party Services - Text1
              Text(
                PolicyPage.third_party_text,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //7. User Rights - Header
              Text(
                PolicyPage.user_rights_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //User Rights - Text1
              Text(
                PolicyPage.user_rights_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //User Rights - Text2
              Text(
                PolicyPage.user_rights_text2,
                style: TextStyle(fontSize: 16),
              ),
              //User Rights - Text3
              Text(
                PolicyPage.user_rights_text3,
                style: TextStyle(fontSize: 16),
              ),
              //User Rights - Text4
              Text(
                PolicyPage.user_rights_text4,
                style: TextStyle(fontSize: 16),
              ),
              //User Rights - Text5
              Text(
                PolicyPage.user_rights_text5,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //User Rights - Text6
              Text(
                PolicyPage.user_rights_text6,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //8. California Consumer Privacy Act (CCPA) - Header
              /*
              Text(
                PolicyPage.ccpa_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //California Consumer Privacy Act (CCPA) - Text1
              Text(
                PolicyPage.ccpa_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //California Consumer Privacy Act (CCPA) - Text2
              Text(
                PolicyPage.ccpa_text2,
                style: TextStyle(fontSize: 16),
              ),
              //California Consumer Privacy Act (CCPA) - Text3
              Text(
                PolicyPage.ccpa_text3,
                style: TextStyle(fontSize: 16),
              ),
              //California Consumer Privacy Act (CCPA) - Text4
              Text(
                PolicyPage.ccpa_text4,
                style: TextStyle(fontSize: 16),
              ),
              //California Consumer Privacy Act (CCPA) - Text5
              Text(
                PolicyPage.ccpa_text5,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //California Consumer Privacy Act (CCPA) - Text6
              Text(
                PolicyPage.ccpa_text6,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //9. General Data Protection Regulation (GDPR) - Header
              Text(
                PolicyPage.gdpr_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //General Data Protection Regulation (GDPR) - Text1
              Text(
                PolicyPage.gdpr_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //General Data Protection Regulation (GDPR) - Text2
              Text(
                PolicyPage.gdpr_text2,
                style: TextStyle(fontSize: 16),
              ),
              //General Data Protection Regulation (GDPR) - Text3
              Text(
                PolicyPage.gdpr_text3,
                style: TextStyle(fontSize: 16),
              ),
              //General Data Protection Regulation (GDPR) - Text4
              Text(
                PolicyPage.gdpr_text4,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              //10. California Online Privacy Protection Act (CalOPPA) - Header
              Text(
                PolicyPage.caloppa_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //California Online Privacy Protection Act (CalOPPA) - Text1
              Text(
                PolicyPage.caloppa_text1,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              //California Online Privacy Protection Act (CalOPPA) - Text2
              Text(
                PolicyPage.caloppa_text2,
                style: TextStyle(fontSize: 16),
              ),
              //California Online Privacy Protection Act (CalOPPA) - Text3
              Text(
                PolicyPage.caloppa_text3,
                style: TextStyle(fontSize: 16),
              ),
              //California Online Privacy Protection Act (CalOPPA) - Text4
              Text(
                PolicyPage.caloppa_text4,
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 20),
              */

              //8. Policy Updates - Header
              Text(
                PolicyPage.policy_update_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //Policy Updates - Text1
              Text(
                PolicyPage.policy_update_text,
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 20),

              //9. Contact - Header
              Text(
                PolicyPage.contact_header,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              //Contact - Text1
              Text(
                PolicyPage.contact_text,
                style: TextStyle(fontSize: 16),
              ),
              //Contact - Text2
              Text(
                PolicyPage.contact_email,
                style: TextStyle(fontSize: 16),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
