import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            customHeader(
              label: "Privacy Policy",
              icon: Icons.security,
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

                      Text(
                        "Our Privacy Policy",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: col.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Effective Date: 30/10/2025\nLast Updated: 10/11/2025",
                        style: TextStyle(
                          fontSize: 14,
                          color: col.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "ATOMIOT (\"we,\" \"our,\" or \"us\") operates the Orca mobile and web application (\"the App\") to help fleet managers monitor vehicle speed, performance, and driver behavior. This Privacy Policy explains how we collect, use, protect, and share your information when you use our app and services.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: col.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        icon: Icons.data_usage,
                        title: "1. Information We Collect",
                        content: [
                          "• Personal Information: Name, phone number, email address, and account login details when you register or contact us.",
                          "• Device & Vehicle Data: GPS location, speed, diagnostic data (OBD-II), and driving behavior collected through the Orca device.",
                          "• Usage Data: Log data, device identifiers, IP addresses, and app performance analytics.",
                          "• Communication Data: Messages, support requests, or feedback sent through the app.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.settings,
                        title: "2. How We Use Your Information",
                        content: [
                          "• Provide and improve our fleet management services.",
                          "• Display real-time tracking and driver analytics.",
                          "• Send alerts, notifications, or reports to authorized users.",
                          "• Ensure safety, compliance, and accurate performance monitoring.",
                          "• Communicate updates, support, or service-related information.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.share,
                        title: "3. Data Sharing & Disclosure",
                        content: [
                          "• We do not sell or rent your personal data.",
                          "• We may share limited information only when necessary:",
                          "   - With your authorized organization or fleet manager.",
                          "   - With service providers who help us operate and maintain the app.",
                          "   - To comply with legal obligations or NTSA regulatory requirements.",
                          "   - In case of security threats or fraud prevention.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.lock,
                        title: "4. Data Security",
                        content: [
                          "• We use advanced security protocols, encryption (TLS 1.2+), and access controls to protect your data.",
                          "• However, no online platform is 100% secure — we encourage users to safeguard their login credentials and devices.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.history,
                        title: "5. Data Retention",
                        content: [
                          "• We retain your information only as long as necessary to provide our services, comply with legal obligations, or resolve disputes.",
                          "• You may request data deletion by contacting us directly.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.verified_user,
                        title: "6. Your Rights",
                        content: [
                          "• Access and review your personal data.",
                          "• Request correction or deletion of inaccurate data.",
                          "• Withdraw consent for certain processing activities.",
                          "• Contact us for assistance or clarification regarding your data.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.cookie,
                        title: "7. Cookies & Tracking",
                        content: [
                          "• The app may use cookies or analytics tools to improve performance and user experience.",
                          "• You can disable these in your browser or device settings, but some features may not function properly.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.integration_instructions,
                        title: "8. Third-Party Services",
                        content: [
                          "• Orca may integrate third-party APIs (e.g., Google Maps, Firebase) for enhanced functionality.",
                          "• These services have their own privacy policies governing data use.",
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.update,
                        title: "9. Changes to This Policy",
                        content: [
                          "• We may update this Privacy Policy periodically.",
                          "• Any changes will be posted within the app and on our website with the updated effective date.",
                        ],
                      ),

                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: col.divider,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Contact Us",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: col.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "For privacy concerns or questions, contact us at:",
                              style: TextStyle(
                                fontSize: 16,
                                color: col.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Email: info@atomiot.live",
                              style: TextStyle(fontSize: 16, color: kBlue),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Phone: +254 798 032 158",
                              style: TextStyle(fontSize: 16, color: kBlue),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Nairobi, Kenya",
                              style: TextStyle(
                                fontSize: 16,
                                color: col.textPrimary,
                              ),
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
