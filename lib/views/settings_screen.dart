import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
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

  void _handleBack() {
    final dashboard = _dashboardControllerOrNull;
    if (dashboard != null) {
      dashboard.setIndex(0);
      return;
    }
    Navigator.maybePop(context);
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
    final col = context.col;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: context.isDark ? col.surface : kWhite,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDark ? 0.22 : 0.08,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: col.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'More Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _headlineColor(col),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSheetAction(
                  icon: Icons.info_outline_rounded,
                  title: 'About Orca',
                  subtitle: 'Learn more about the product',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openScreen(const AboutUs());
                  },
                ),
                _buildSheetAction(
                  icon: Icons.headset_mic_outlined,
                  title: 'Help & Support',
                  subtitle: 'Reach out to our support team',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openScreen(const ContactUs());
                  },
                ),
                _buildSheetAction(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Account',
                  subtitle: 'Permanently remove this profile',
                  titleColor: kRed,
                  iconColor: kRed,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openScreen(DeleteAccount());
                  },
                ),
              ],
            ),
          ),
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

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return 'P';
  }

  Color _pageBackground(AppColors col) {
    return context.isDark ? col.bg : const Color(0xFFF6F7FE);
  }

  Color _primaryBlue(AppColors col) {
    return context.isDark ? const Color(0xFF8FB6FF) : const Color(0xFF1C55D6);
  }

  Color _headlineColor(AppColors col) {
    return context.isDark ? col.textPrimary : const Color(0xFF172E69);
  }

  Color _supportingTextColor(AppColors col) {
    return context.isDark ? col.textSecondary : const Color(0xFF536995);
  }

  Color _sectionLabelColor(AppColors col) {
    return context.isDark ? col.textSecondary : const Color(0xFF6B7EAA);
  }

  Color _groupBackground(AppColors col) {
    return context.isDark ? col.surface : const Color(0xFFEFF2FF);
  }

  Color _iconBackground(AppColors col) {
    return context.isDark
        ? kBlue.withValues(alpha: 0.16)
        : const Color(0xFFD9E6FF);
  }

  Color _activeOptionFill(AppColors col) {
    return context.isDark ? col.surface : kWhite;
  }

  Color _inactiveOptionFill(AppColors col) {
    return context.isDark ? col.surface.withValues(alpha: 0.78) : kWhite;
  }

  Color _logoutBackground(AppColors col) {
    return context.isDark ? const Color(0xFF40242B) : const Color(0xFFF4DFE8);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;

    return Obx(() {
      final user = _userController.user.value;
      final displayName = _displayName(user);
      final email = _emailOrFallback(user);

      return Scaffold(
        backgroundColor: _pageBackground(col),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshProfile,
            color: _primaryBlue(col),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _buildTopBar(col),
                const SizedBox(height: 16),
                _buildProfileBlock(
                  col: col,
                  user: user,
                  displayName: displayName,
                  email: email,
                ),
                const SizedBox(height: 22),
                _buildSectionLabel('Appearance', col),
                const SizedBox(height: 10),
                _buildAppearanceSelector(col),
                const SizedBox(height: 22),
                _buildSectionLabel('General Settings', col),
                const SizedBox(height: 10),
                _buildSettingsCard(
                  col,
                  [
                    _buildSettingsTile(
                      col: col,
                      icon: Icons.person_rounded,
                      title: 'Account Details',
                      subtitle: 'Profile info and address',
                      onTap: () => _openScreen(const AccountScreen()),
                    ),
                    _buildSettingsTile(
                      col: col,
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications',
                      subtitle: 'Alerts and app sounds',
                      onTap: _openNotifications,
                    ),
                    _buildSettingsTile(
                      col: col,
                      icon: Icons.lock_reset_rounded,
                      title: 'Change Password',
                      subtitle: 'Security and authentication',
                      onTap: () => _openScreen(ChangePassword()),
                    ),
                    _buildSettingsTile(
                      col: col,
                      icon: Icons.confirmation_number_outlined,
                      title: 'Support Tickets',
                      subtitle: 'Raise and track maintenance requests',
                      onTap: () => _openScreen(const TicketsScreen()),
                    ),
                    if (_role == 'Admin')
                      _buildSettingsTile(
                        col: col,
                        icon: Icons.groups_rounded,
                        title: 'Managers',
                        subtitle: 'Add and manage transport managers',
                        onTap: () => _openScreen(const ManagerScreen()),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                _buildSectionLabel('Information', col),
                const SizedBox(height: 10),
                _buildSettingsCard(
                  col,
                  [
                    _buildSettingsTile(
                      col: col,
                      icon: Icons.verified_user_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Your data and privacy rights',
                      onTap: () => _openScreen(PrivacyPolicy()),
                    ),
                    _buildSettingsTile(
                      col: col,
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      subtitle: 'User agreement and guidelines',
                      onTap: () => _openScreen(const TermsAndConditions()),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _buildLogoutButton(col),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopBar(AppColors col) {
    final accent = _primaryBlue(col);

    return Row(
      children: [
        // _TopBarButton(
        //   icon: Icons.arrow_back_rounded,
        //   color: accent,
        //   onTap: _handleBack,
        // ),
        // const SizedBox(width: 10),
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        const Spacer(),
        _TopBarButton(
          icon: Icons.settings_rounded,
          color: accent,
          onTap: _showQuickActions,
        ),
      ],
    );
  }

  Widget _buildProfileBlock({
    required AppColors col,
    required UserModel? user,
    required String displayName,
    required String email,
  }) {
    final accent = _primaryBlue(col);
    final imageUrl = user?.profileImage.trim() ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: 122,
          height: 120,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.isDark
                      ? col.surface
                      : const Color(0xFFE9D8BE),
                  border: Border.all(color: kWhite, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: context.isDark ? 0.20 : 0.08,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarFallback(
                              col: col,
                              displayName: displayName,
                            );
                          },
                        )
                      : _buildAvatarFallback(
                          col: col,
                          displayName: displayName,
                        ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openScreen(const AccountScreen()),
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.edit_rounded, color: kWhite),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: _headlineColor(col),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: _supportingTextColor(col),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback({
    required AppColors col,
    required String displayName,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? const [Color(0xFF2D3652), Color(0xFF1C2440)]
              : const [Color(0xFFDAB98B), Color(0xFF8A6A46)],
        ),
      ),
      child: Center(
        child: Text(
          _initials(displayName),
          style: const TextStyle(
            color: kWhite,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, AppColors col) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
        color: _sectionLabelColor(col),
      ),
    );
  }

  Widget _buildAppearanceSelector(AppColors col) {
    return Obx(() {
      final controller = ThemeController.to;
      return Row(
        children: [
          Expanded(
            child: _buildThemeOption(
              col: col,
              label: 'Light',
              icon: Icons.light_mode_rounded,
              themeMode: ThemeMode.light,
              controller: controller,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildThemeOption(
              col: col,
              label: 'Dark',
              icon: Icons.dark_mode_rounded,
              themeMode: ThemeMode.dark,
              controller: controller,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildThemeOption(
              col: col,
              label: 'System',
              icon: Icons.settings_suggest_rounded,
              themeMode: ThemeMode.system,
              controller: controller,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildThemeOption({
    required AppColors col,
    required String label,
    required IconData icon,
    required ThemeMode themeMode,
    required ThemeController controller,
  }) {
    final isSelected = controller.mode.value == themeMode;
    final accent = _primaryBlue(col);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.setMode(themeMode),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 84,
          decoration: BoxDecoration(
            color: isSelected ? _activeOptionFill(col) : _inactiveOptionFill(col),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? accent
                  : context.isDark
                  ? Colors.transparent
                  : const Color(0xFFE7EBFB),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? accent : _supportingTextColor(col),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? accent : _headlineColor(col),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(AppColors col, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _groupBackground(col),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.16 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required AppColors col,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconBackground(col),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: _primaryBlue(col), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _headlineColor(col),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: _supportingTextColor(col),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _sectionLabelColor(col),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AppColors col) {
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
            color: _logoutBackground(col),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
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

  Widget _buildSheetAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    final col = context.col;
    final resolvedIconColor = iconColor ?? _primaryBlue(col);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: resolvedIconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: resolvedIconColor),
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
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? _headlineColor(col),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: _supportingTextColor(col),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _sectionLabelColor(col),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 28, color: color),
        ),
      ),
    );
  }
}
