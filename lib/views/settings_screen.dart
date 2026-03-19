import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/auth_controller.dart';
import 'package:atom/controllers/theme_controller.dart';
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
      backgroundColor: context.col.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildProfileHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),

                  // ── Appearance ──────────────────────────────────────
                  _buildSectionLabel('Appearance'),
                  const SizedBox(height: 8),
                  _buildAppearanceCard(),

                  const SizedBox(height: 24),

                  // ── Account ─────────────────────────────────────────
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

                  // ── Legal & About ────────────────────────────────────
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

                  // ── Support ──────────────────────────────────────────
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

                  // ── Danger zone ──────────────────────────────────────
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

  // ─── Profile header ──────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    final initials = _getInitials(userName ?? 'User');
    return Container(
      color: context.col.surface,
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.col.textPrimary,
                  ),
                ),
                if (phone != null && phone!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    phone!,
                    style: TextStyle(
                        fontSize: 14, color: context.col.textSecondary),
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

  // ─── Appearance card ─────────────────────────────────────────────────────

  Widget _buildAppearanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(kRadiusSM),
                ),
                child: const Icon(Icons.brightness_6_rounded,
                    color: kBlue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.col.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose your preferred theme',
                      style: TextStyle(
                          fontSize: 13,
                          color: context.col.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            final ctrl = ThemeController.to;
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.col.bg,
                borderRadius: BorderRadius.circular(kRadiusMD),
              ),
              child: Row(
                children: [
                  _themeOption(
                      'System', Icons.brightness_auto_rounded,
                      ThemeMode.system, ctrl),
                  _themeOption(
                      'Light', Icons.light_mode_rounded,
                      ThemeMode.light, ctrl),
                  _themeOption(
                      'Dark', Icons.dark_mode_rounded,
                      ThemeMode.dark, ctrl),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _themeOption(
    String label,
    IconData icon,
    ThemeMode themeMode,
    ThemeController ctrl,
  ) {
    final isActive = ctrl.mode.value == themeMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.setMode(themeMode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? kBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(kRadiusSM),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? kWhite : context.col.textSecondary,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? kWhite : context.col.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section label ───────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: context.col.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }

  // ─── Card ────────────────────────────────────────────────────────────────

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
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
                        color: textColor ?? context.col.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: context.col.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.col.border, size: 20),
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
      color: context.col.divider,
    );
  }

  // ─── Sign out ────────────────────────────────────────────────────────────

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
              title: 'Sign Out',
              message: 'Are you sure you want to sign out?',
              confirmText: 'Sign Out',
              cancelText: 'Cancel',
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
