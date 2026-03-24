import 'package:atom/config/constants.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            customHeader(
              label: "Terms & Conditions",
              icon: Icons.description,
              showBackButton: true,
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        "Terms and Conditions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Effective Date: 30/10/2025\nLast Updated: 10/11/2025",
                        style: TextStyle(fontSize: 14, color: kGrey),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Welcome to Orca, a fleet management and speed monitoring solution developed and operated by ATOMIOT (“we,” “our,” “us”). By downloading, installing, or using the Orca mobile or web application (“App”), you agree to comply with these Terms and Conditions (“Terms”). Please read them carefully before using the App.",
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        icon: Icons.check_circle_outline,
                        title: "1. Acceptance of Terms",
                        content: [
                          "By accessing or using the Orca App, you acknowledge that you have read, understood, and agree to be bound by these Terms. If you do not agree, you must discontinue use of the App immediately.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.info_outline,
                        title: "2. Service Description",
                        content: [
                          "Orca is an IoT-powered fleet management system designed to monitor vehicle speed, driver behavior, and performance in real time.",
                          "The App provides analytics, alerts, and reports through connected devices installed in vehicles.",
                          "We may update, modify, or enhance the features of the App at any time to improve performance or comply with regulations.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.person_outline,
                        title: "3. User Accounts",
                        content: [
                          "To access certain features, users must create an account and provide accurate, current information.",
                          "You are responsible for:",
                          "• Maintaining the confidentiality of your account credentials.",
                          "• All activities under your account.",
                          "• Notifying us immediately if you suspect unauthorized access or use.",
                          "ATOMIOT reserves the right to suspend or terminate accounts for misuse or violation of these Terms.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.gavel_outlined,
                        title: "4. Authorized Use",
                        content: [
                          "You agree to use the App only for lawful purposes and in accordance with these Terms.",
                          "You shall not:",
                          "• Reverse engineer, copy, or distribute any part of the App.",
                          "• Use the App to track or collect personal data without proper authorization.",
                          "• Interfere with servers, networks, or security features.",
                          "• Misuse data for purposes unrelated to fleet monitoring or safety compliance.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.privacy_tip_outlined,
                        title: "5. Data & Privacy",
                        content: [
                          "By using the App, you consent to our collection and processing of data as described in the Orca Privacy Policy.",
                          "Data collected includes GPS location, vehicle telemetry, and account information — used strictly for service delivery, compliance, and performance insights.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.copyright_outlined,
                        title: "6. Ownership & Intellectual Property",
                        content: [
                          "All content, software, logos, and technology in Orca are the exclusive property of ATOMIOT.",
                          "You are granted a limited, non-transferable, non-exclusive license to use the App for fleet management purposes only.",
                          "Unauthorized copying or resale is strictly prohibited.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.cloud_off_outlined,
                        title: "7. Service Availability",
                        content: [
                          "We strive to ensure 99.5% uptime; however, occasional downtime may occur due to maintenance, updates, or network issues.",
                          "ATOMIOT is not liable for losses arising from service interruptions or delays.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.warning_amber_outlined,
                        title: "8. Limitation of Liability",
                        content: [
                          "ATOMIOT shall not be held liable for:",
                          "• Indirect, incidental, or consequential damages.",
                          "• Data loss, downtime, or operational issues caused by third-party networks.",
                          "• Misuse or misinterpretation of data provided by the App.",
                          "Users are responsible for verifying data accuracy and ensuring compliance with local laws and NTSA regulations.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.cancel_outlined,
                        title: "9. Termination",
                        content: [
                          "We may suspend or terminate your access to the App at any time if:",
                          "• You violate these Terms.",
                          "• Your organization discontinues service.",
                          "• Required by law or regulation.",
                          "Upon termination, your right to use the App immediately ceases, but relevant data may be retained for regulatory compliance.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.system_update_alt_outlined,
                        title: "10. Updates & Modifications",
                        content: [
                          "We may modify or update these Terms at any time.",
                          "The updated version will be posted in the App and on our website, and continued use will signify your acceptance of the new Terms.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.flag_outlined,
                        title: "11. Governing Law",
                        content: [
                          "These Terms are governed by and construed under the laws of the Republic of Kenya.",
                          "Any disputes shall be resolved under Kenyan jurisdiction.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kDivider,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "12. Contact Information",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "If you have any questions or concerns about these Terms, please contact us at:",
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Email: info@atomiot.live",
                              style: TextStyle(
                                fontSize: 16,
                                color: kBlue,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Phone: +254 798 032 158",
                              style: TextStyle(
                                fontSize: 16,
                                color: kBlue,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Nairobi, Kenya",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: kBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...content.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 6),
            child: Text(
              item,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
