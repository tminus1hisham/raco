import 'package:atom/config/constants.dart';
import 'package:atom/controllers/auth_controller.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/views/settings/about_us.dart';
import 'package:atom/views/settings/account_screen.dart';
import 'package:atom/views/settings/change_password.dart';
import 'package:atom/views/settings/contact_us.dart';
import 'package:atom/views/settings/delete_account.dart';
import 'package:atom/views/settings/privacy_policy.dart';
import 'package:atom/views/transport%20%20managers/manager_screen.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthController _authController = Get.put(AuthController());
  String? role;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final fetchedRole = await StorageService.getData('userRole');
    setState(() {
      role = fetchedRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            customHeader(label: "Settings", icon: Icons.settings),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 20),
                children: [
                  // Account Settings Section
                  _buildSectionHeader('Account'),
                  _buildSettingsCard(
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.person_outline,
                          title: 'Account Details',
                          subtitle: 'Manage your profile information',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AccountScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          subtitle: 'Update your account password',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangePassword(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        if (role == 'SuperAdmin') ...[
                          _buildSettingsItem(
                            icon: Icons.person_add_alt,
                            title: 'Transport Managers',
                            subtitle: 'Add and manage transport managers.',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManagerScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                        ],
                        _buildSettingsItem(
                          icon: Icons.delete_outline,
                          title: 'Delete Account',
                          subtitle: 'Permanently remove your account',
                          textColor: Colors.red.shade600,
                          iconColor: Colors.red.shade600,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeleteAccount(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Legal & About Section
                  _buildSectionHeader('Legal & About'),
                  _buildSettingsCard(
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'Learn how we protect your data',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrivacyPolicy(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: Icons.info_outline,
                          title: 'About Atom',
                          subtitle: 'Get to know about us',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AboutUs(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  _buildSectionHeader('Support'),
                  _buildSettingsCard(
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Get help or contact support',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ContactUs(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  _buildSectionHeader('Logout'),
                  _buildSettingsCard(
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Sign out of Atom',
                          textColor: Colors.red.shade600,
                          iconColor: Colors.red.shade600,
                          onTap: () {
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => ActionDialog(
                                title: "Logout",
                                message: "Are you sure you want to logout?",
                                confirmText: "Logout",
                                cancelText: "Cancel",
                                onConfirm: () =>
                                    _authController.logout(context),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                      ],
                    ),
                  ),

                  SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child, VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? kBlue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor ?? kBlue, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.only(left: 56),
      height: 1,
      color: Colors.grey.shade100,
    );
  }
}
