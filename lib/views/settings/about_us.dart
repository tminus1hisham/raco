import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            customHeader(
              label: "About Us",
              icon: Icons.info_outline,
              showBackButton: true,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      _buildSection(
                        icon: Icons.info_outline,
                        title: 'About Our App',
                        content:
                            'Speed Governor is a comprehensive solution for managing vehicle speed control systems. Our app helps users monitor, configure, and maintain speed governors with ease and reliability.',
                      ),
                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.flag,
                        title: 'Our Mission',
                        content:
                            'To provide safe, efficient, and user-friendly speed management solutions that promote road safety and regulatory compliance for vehicle operators.',
                      ),
                      const SizedBox(height: 20),

                      _buildSection(
                        icon: Icons.star,
                        title: 'Key Features',
                        content:
                            '• Real-time speed monitoring\n• Easy configuration management\n• Secure user authentication\n• Comprehensive reporting\n• 24/7 technical support',
                      ),
                      const SizedBox(height: 32),

                      // Contact Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.contact_mail, color: kBlue),
                                const SizedBox(width: 8),
                                Text(
                                  'Get in Touch',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: col.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildContactItem(
                              Icons.email,
                              'info@atomiot.co.ke',
                              col,
                            ),
                            const SizedBox(height: 8),
                            _buildContactItem(
                              Icons.phone,
                              '+254 798 032 158',
                              col,
                            ),
                            const SizedBox(height: 8),
                            _buildContactItem(
                              Icons.pin_drop,
                              'Nairobi, Kenya',
                              col,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          '© ${DateTime.now().year} Atom. All rights reserved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: col.textSecondary,
                          ),
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
    required String content,
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
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text, AppColors col) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kBlue),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 14, color: col.textPrimary)),
      ],
    );
  }
}
