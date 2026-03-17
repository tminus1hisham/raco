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
  String? userName;
  String? phone;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final fetchedRole = await StorageService.getData('userRole');
    final fetchedName = await StorageService.getData('userName');
    final fetchedPhone = await StorageService.getData('phone');
    setState(() {
      role = fetchedRole;
      userName = fetchedName;
      phone = fetchedPhone;
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildProfileHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),

                  // Account section
                  _buildSectionLabel('Account'),
                  const SizedBox(height: 8),
                  _buildCard([
                    _buildItem(
                      icon: Icons.person_outline_rounded,
                      iconBg: const Color(0xFF3B82F6),
                      title: 'Account Details',
                      subtitle: 'Manage your profile information',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AccountScreen()),
                      ),
                    ),
                    _buildDivider(),
                    _buildItem(
                      icon: Icons.lock_outline_rounded,
                      iconBg: const Color(0xFF8B5CF6),
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChangePassword()),
                      ),
                    ),
                    if (role == 'Admin') ...[
                      _buildDivider(),
                      _buildItem(
                        icon: Icons.group_outlined,
                        iconBg: const Color(0xFF0EA5E9),
                        title: 'Managers',
                        subtitle: 'Add and manage transport managers',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ManagerScreen()),
                        ),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 24),

                  // Legal & About section
                  _buildSectionLabel('Legal & About'),
                  const SizedBox(height: 8),
                  _buildCard([
                    _buildItem(
                      icon: Icons.privacy_tip_outlined,
                      iconBg: const Color(0xFFF59E0B),
                      title: 'Privacy Policy',
                      subtitle: 'Learn how we protect your data',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PrivacyPolicy()),
                      ),
                    ),
                    _buildDivider(),
                    _buildItem(
                      icon: Icons.info_outline_rounded,
                      iconBg: const Color(0xFF6366F1),
                      title: 'About Atom',
                      subtitle: 'Get to know about us',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AboutUs()),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Support section
                  _buildSectionLabel('Support'),
                  const SizedBox(height: 8),
                  _buildCard([
                    _buildItem(
                      icon: Icons.headset_mic_outlined,
                      iconBg: const Color(0xFF10B981),
                      title: 'Help & Support',
                      subtitle: 'Get help or contact our team',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ContactUs()),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Danger zone
                  _buildCard([
                    _buildItem(
                      icon: Icons.delete_outline_rounded,
                      iconBg: kRed,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account',
                      textColor: kRed,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DeleteAccount()),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Sign out button
                  _buildSignOutButton(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final initials = _getInitials(userName ?? 'User');
    return Container(
      color: kWhite,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF287ec3), Color(0xFF1a5a8a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kBlack,
                  ),
                ),
                if (phone != null && phone!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    phone!,
                    style: const TextStyle(fontSize: 14, color: kGrey),
                  ),
                ],
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(kRadiusPill),
                  ),
                  child: Text(
                    role ?? 'User',
                    style: const TextStyle(
                      fontSize: 12,
                      color: kBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: kGrey,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(kRadiusSM),
                ),
                child: Icon(icon, color: kWhite, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? kBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: kGrey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: kLightGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 70),
      height: 1,
      color: kDivider,
    );
  }

  Widget _buildSignOutButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(kRadiusMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusMD),
        onTap: () {
          showCupertinoDialog(
            context: context,
            builder: (context) => ActionDialog(
              title: "Sign Out",
              message: "Are you sure you want to sign out?",
              confirmText: "Sign Out",
              cancelText: "Cancel",
              onConfirm: () => _authController.logout(context),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: kRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(kRadiusMD),
            border: Border.all(
              color: kRed.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: kRed, size: 20),
              SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
