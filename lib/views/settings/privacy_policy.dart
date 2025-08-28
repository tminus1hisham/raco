import 'package:atom/config/constants.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            customHeader(label: "Privacy Policy", icon: Icons.security),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildSection(
                        icon: Icons.data_usage,
                        title: 'Information We Collect',
                        content: [
                          '• Phone number for account login',
                          '• Encrypted password for security',
                          '• Speed governor settings',
                          '• Vehicle identification data',
                          '• Usage statistics and preferences',
                        ],
                      ),
                      const SizedBox(height: 20),

                      // How We Use Information
                      _buildSection(
                        icon: Icons.how_to_reg,
                        title: 'How We Use Your Information',
                        content: [
                          '• Authenticate your account access',
                          '• Manage speed governor configurations',
                          '• Improve app functionality',
                          '• Provide customer support',
                          '• Ensure system security',
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Data Security
                      _buildSection(
                        icon: Icons.lock,
                        title: 'Data Security',
                        content: [
                          '• All data is encrypted in transit',
                          '• Secure storage of personal information',
                          '• Regular security audits',
                          '• No sharing with third parties',
                          '• Access controls and authentication',
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Your Rights
                      _buildSection(
                        icon: Icons.account_circle,
                        title: 'Your Rights',
                        content: [
                          '• Access your personal data',
                          '• Update or correct information',
                          '• Delete your account',
                          '• Export your data',
                          '• Contact support for questions',
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Contact Information
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Us',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'For privacy concerns or questions, contact us at:',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Email: privacy@speedgov.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
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

  Widget _buildSection({
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
            padding: const EdgeInsets.only(left: 28, bottom: 4),
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
