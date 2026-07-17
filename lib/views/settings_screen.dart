import 'package:atom/config/constants.dart';
import 'package:atom/config/profile_palette.dart';
import 'package:atom/controllers/auth_controller.dart';
import 'package:atom/controllers/dashboard_controller.dart';
import 'package:atom/controllers/theme_controller.dart';
import 'package:atom/controllers/user_data_controller.dart';
import 'package:atom/models/user_model.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/views/settings/about_us.dart';
import 'package:atom/views/settings/account_screen.dart';
import 'package:atom/views/settings/change_password.dart';
import 'package:atom/views/settings/contact_us.dart';
import 'package:atom/views/settings/delete_account.dart';
import 'package:atom/views/settings/privacy_policy.dart';
import 'package:atom/views/settings/terms_and_conditions.dart';
import 'package:atom/views/tickets/tickets_screen.dart';
import 'package:atom/views/transport%20%20managers/manager_screen.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:atom/widgets/profile/profile_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  final UserProfileController _userController =
      Get.isRegistered<UserProfileController>()
      ? Get.find<UserProfileController>()
      : Get.put(UserProfileController());

  DashboardController? get _dashboardControllerOrNull =>
      Get.isRegistered<DashboardController>()
      ? Get.find<DashboardController>()
      : null;

  String? _role;
  String? _fallbackName;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
  }

  Future<void> _loadLocalProfile() async {
    final fetchedRole = await StorageService.getData('userRole');
    final fetchedName = await StorageService.getData('userName');
    final fetchedPhone = await StorageService.getData('phone');

    if (!mounted) return;
    setState(() {
      _role = fetchedRole?.toString();
      _fallbackName = fetchedName?.toString();
      _phone = fetchedPhone?.toString();
    });
  }

  Future<void> _refreshProfile() async {
    await Future.wait([_userController.fetchUserProfile(), _loadLocalProfile()]);
  }

  void _openNotifications() {
    final dashboard = _dashboardControllerOrNull;
    if (dashboard != null) {
      dashboard.setIndex(1);
      return;
    }
    Navigator.of(context).pushNamed('notifications');
  }

  void _openScreen(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showQuickActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ProfileSheet(
          title: 'More Options',
          children: [
            ProfileActionTile(
              icon: Icons.info_outline_rounded,
              title: 'About Orca',
              subtitle: 'Learn more about the product',
              onTap: () {
                Navigator.pop(sheetContext);
                _openScreen(const AboutUs());
              },
            ),
            const SizedBox(height: 6),
            ProfileActionTile(
              icon: Icons.headset_mic_outlined,
              title: 'Help & Support',
              subtitle: 'Reach out to our support team',
              onTap: () {
                Navigator.pop(sheetContext);
                _openScreen(const ContactUs());
              },
            ),
            const SizedBox(height: 6),
            ProfileActionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove this profile',
              tint: kRed,
              onTap: () {
                Navigator.pop(sheetContext);
                _openScreen(DeleteAccount());
              },
            ),
          ],
        );
      },
    );
  }

  String _displayName(UserModel? user) {
    final apiName = user?.fullName.trim() ?? '';
    if (apiName.isNotEmpty) return apiName;

    final storedName = _fallbackName?.trim() ?? '';
    if (storedName.isNotEmpty) return storedName;

    return 'Profile User';
  }

  String _emailOrFallback(UserModel? user) {
    final email = user?.emailAddress.trim() ?? '';
    if (email.isNotEmpty) return email;

    final phone = _phone?.trim() ?? '';
    if (phone.isNotEmpty) return phone;

    return 'Profile details unavailable';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.profile;

    return Obx(() {
      final user = _userController.user.value;
      final displayName = _displayName(user);
      final email = _emailOrFallback(user);

      return Scaffold(
        backgroundColor: palette.bg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshProfile,
            color: palette.accent,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                ProfileTopBar(
                  title: 'Profile',
                  actionIcon: Icons.settings_rounded,
                  onAction: _showQuickActions,
                ),
                const SizedBox(height: 16),
                _buildHero(user: user, displayName: displayName, email: email),
                const SizedBox(height: 22),
                const ProfileSectionLabel('Appearance'),
                const SizedBox(height: 10),
                _buildAppearanceSelector(),
                const SizedBox(height: 22),
                const ProfileSectionLabel('General Settings'),
                const SizedBox(height: 10),
                ProfileGroupCard(
                  children: [
                    ProfileActionTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications',
                      subtitle: 'Alerts and app sounds',
                      onTap: _openNotifications,
                    ),
                    ProfileActionTile(
                      icon: Icons.lock_reset_rounded,
                      title: 'Change Password',
                      subtitle: 'Security and authentication',
                      onTap: () => _openScreen(ChangePassword()),
                    ),
                    ProfileActionTile(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Support Tickets',
                      subtitle: 'Raise and track maintenance requests',
                      onTap: () => _openScreen(const TicketsScreen()),
                    ),
                    if (_role == 'Admin')
                      ProfileActionTile(
                        icon: Icons.groups_rounded,
                        title: 'Managers',
                        subtitle: 'Add and manage transport managers',
                        onTap: () => _openScreen(const ManagerScreen()),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                const ProfileSectionLabel('Information'),
                const SizedBox(height: 10),
                ProfileGroupCard(
                  children: [
                    ProfileActionTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Your data and privacy rights',
                      onTap: () => _openScreen(PrivacyPolicy()),
                    ),
                    ProfileActionTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      subtitle: 'User agreement and guidelines',
                      onTap: () => _openScreen(const TermsAndConditions()),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _buildLogoutButton(palette),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHero({
    required UserModel? user,
    required String displayName,
    required String email,
  }) {
    return ProfileHeroCard(
      displayName: displayName,
      subtitle: email,
      imageUrl: user?.profileImage ?? '',
      avatarBadge: ProfileCircleButton(
        icon: Icons.edit_rounded,
        size: 30,
        onTap: () => _openScreen(const AccountScreen()),
      ),
      chips: [
        if (user != null)
          ProfileChip(
            label: user.userActive ? 'Active' : 'Inactive',
            icon: user.userActive
                ? Icons.check_circle_outline_rounded
                : Icons.pause_circle_outline_rounded,
            color: user.userActive ? kSuccessGreen : kWhite,
          ),
      ],
      footer: ProfileHeroAction(
        icon: Icons.manage_accounts_outlined,
        label: 'Account Details',
        onTap: () => _openScreen(const AccountScreen()),
      ),
    );
  }

  Widget _buildAppearanceSelector() {
    return Obx(
      () => ProfileSegmentedControl<ThemeMode>(
        value: ThemeController.to.mode.value,
        onChanged: ThemeController.to.setMode,
        segments: const [
          ProfileSegment(
            value: ThemeMode.light,
            label: 'Light',
            icon: Icons.light_mode_rounded,
          ),
          ProfileSegment(
            value: ThemeMode.dark,
            label: 'Dark',
            icon: Icons.dark_mode_rounded,
          ),
          ProfileSegment(
            value: ThemeMode.system,
            label: 'System',
            icon: Icons.settings_suggest_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ProfilePalette palette) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: palette.dangerBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: kRed, size: 24),
              SizedBox(width: 12),
              Text(
                'Log Out',
                style: TextStyle(
                  color: kRed,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
