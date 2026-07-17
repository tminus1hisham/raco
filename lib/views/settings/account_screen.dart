import 'package:atom/config/constants.dart';
import 'package:atom/config/profile_palette.dart';
import 'package:atom/controllers/update_profile_controller.dart';
import 'package:atom/controllers/update_user_data.dart';
import 'package:atom/controllers/user_data_controller.dart';
import 'package:atom/models/user_model.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/services/upload_image_service.dart';
import 'package:atom/views/camera_screen.dart';
import 'package:atom/widgets/buttons/primary_gradient_button.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:atom/widgets/profile/profile_widgets.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final UserProfileController controller = Get.isRegistered<UserProfileController>()
      ? Get.find<UserProfileController>()
      : Get.put(UserProfileController());

  String profileUrl = '';
  XFile? profileImage;
  bool isUploadingImage = false;

  final ImageUploaderService uploadPictureService = ImageUploaderService();
  final UpdateProfileController updateController = Get.put(
    UpdateProfileController(),
  );

  final UpdateUserDataController updateUserDataController = Get.put(
    UpdateUserDataController(),
  );

  // Controllers for edit form
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _onImagePicked(XFile? image) async {
    if (image == null) return;

    setState(() {
      profileImage = image;
      isUploadingImage = true;
    });

    String? uploadedUrl = await uploadPictureService.uploadPicture(image);
    if (!mounted) return;

    if (uploadedUrl == null) {
      setState(() => isUploadingImage = false);
      Get.snackbar("Error", "Image upload failed");
      return;
    }

    setState(() {
      profileUrl = uploadedUrl;
      StorageService.storeData({'profileUrl': profileUrl});
    });

    updateController.image.value = uploadedUrl;
    bool success = await updateController.updateProfile(context);
    if (!mounted) return;

    if (success) {
      await CustomAlertDialog(
        context: context,
        title: "Success",
        message: "Your profile picture has been updated successfully.",
        icon: "assets/animations/Success.json",
        buttonColor: kSuccessGreen,
      );
      controller.fetchUserProfile();
    } else {
      await CustomAlertDialog(
        context: context,
        title: "Error",
        message: "Failed to update profile picture.",
        icon: "assets/animations/Failed.json",
        buttonColor: kRed,
      );
    }

    if (!mounted) return;
    setState(() => isUploadingImage = false);
  }

  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ProfileSheet(
          title: 'Profile Photo',
          children: [
            ProfileActionTile(
              icon: Icons.photo_library_outlined,
              title: 'Choose from Gallery',
              subtitle: 'Pick an existing picture',
              onTap: () async {
                Navigator.pop(sheetContext);
                final picker = ImagePicker();
                final pickedImage = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                _onImagePicked(pickedImage);
              },
            ),
            const SizedBox(height: 6),
            ProfileActionTile(
              icon: Icons.photo_camera_outlined,
              title: 'Take a Photo',
              subtitle: 'Use the front camera',
              onTap: () async {
                Navigator.pop(sheetContext);
                final capturedImage = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraCaptureScreen(
                      preferredCamera: CameraLensDirection.front,
                    ),
                  ),
                );

                if (capturedImage != null) {
                  _onImagePicked(capturedImage);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile(BuildContext sheetContext) async {
    FocusScope.of(sheetContext).unfocus();

    final user = controller.user.value;
    if (user == null) return;

    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Full name and email cannot be empty.",
        backgroundColor: kRed.withValues(alpha: 0.1),
        colorText: kRed,
      );
      return;
    }

    try {
      updateUserDataController.isLoading(true);

      await updateUserDataController.updateProfile(
        user.userId.toString(),
        emailController.text.trim(),
        fullNameController.text.trim(),
      );

      await controller.fetchUserProfile();

      if (sheetContext.mounted) Navigator.pop(sheetContext);
      if (!mounted) return;

      await CustomAlertDialog(
        context: context,
        title: "Success",
        message: "Your profile details have been updated successfully.",
        icon: "assets/animations/Success.json",
        buttonColor: kSuccessGreen,
      );
    } catch (e) {
      if (!mounted) return;
      await CustomAlertDialog(
        context: context,
        title: "Error",
        message: "Failed to update profile: $e",
        icon: "assets/animations/Failed.json",
        buttonColor: kRed,
      );
    } finally {
      updateUserDataController.isLoading(false);
    }
  }

  void _showEditProfileModal(BuildContext context) {
    final user = controller.user.value;
    if (user == null) return;

    fullNameController.text = user.fullName;
    emailController.text = user.emailAddress;
    phoneController.text = user.phoneNumber;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final palette = sheetContext.profile;

        return SingleChildScrollView(
          child: ProfileSheet(
            title: 'Edit Profile',
            children: [
              InputField(
                hintText: 'Full Name',
                controller: fullNameController,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              InputField(
                hintText: 'Email Address',
                controller: emailController,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              InputField(
                hintText: 'Phone Number',
                controller: phoneController,
                prefixIcon: Icons.phone_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: palette.supporting,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your phone number is used to sign in and cannot be '
                      'changed here. Contact support to update it.',
                      style: TextStyle(fontSize: 12, color: palette.supporting),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Obx(
                () => PrimaryGradientButton(
                  onPressed: () => _saveProfile(sheetContext),
                  isLoading: updateUserDataController.isLoading.value,
                  text: "Save Changes",
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.profile;

    return Obx(() {
      final user = controller.user.value;

      return Scaffold(
        backgroundColor: palette.bg,
        body: SafeArea(
          child: Stack(
            children: [
              if (controller.isLoading.value && user == null)
                Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: palette.accent,
                    size: 50,
                  ),
                )
              else if (user == null)
                _buildEmptyState(palette)
              else
                _buildContent(palette, user),
              if (isUploadingImage)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Center(
                      child: LoadingAnimationWidget.fourRotatingDots(
                        color: kWhite,
                        size: 50,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(ProfilePalette palette) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: ProfileTopBar(
            title: 'Account Details',
            onBack: () => Navigator.pop(context),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProfileIconChip(icon: Icons.person_off_outlined, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No user data found',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: palette.headline,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We could not load your account details. Pull to refresh '
                    'or try again in a moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: palette.supporting),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: controller.fetchUserProfile,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ProfilePalette palette, UserModel user) {
    return RefreshIndicator(
      onRefresh: controller.fetchUserProfile,
      color: palette.accent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          ProfileTopBar(
            title: 'Account Details',
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          _buildHero(user),
          const SizedBox(height: 24),
          const ProfileSectionLabel('Personal Information'),
          const SizedBox(height: 10),
          ProfileGroupCard(
            children: [
              _buildInfoRow(
                palette,
                icon: Icons.person_outline,
                label: 'Full Name',
                value: user.fullName,
              ),
              _buildInfoRow(
                palette,
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: user.emailAddress,
              ),
              _buildInfoRow(
                palette,
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: user.phoneNumber,
                locked: true,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ProfileSectionLabel('Account'),
          const SizedBox(height: 10),
          ProfileGroupCard(
            children: [
              _buildInfoRow(
                palette,
                icon: Icons.event_available_outlined,
                label: 'Member Since',
                value: _formatDate(user.createdAt),
              ),
              _buildInfoRow(
                palette,
                icon: Icons.login_rounded,
                label: 'Last Sign In',
                value: _formatDateTime(user.lastLogin),
              ),
            ],
          ),
          const SizedBox(height: 26),
          PrimaryGradientButton(
            onPressed: () => _showEditProfileModal(context),
            text: "Edit Profile",
            icon: Icons.edit_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildHero(UserModel user) {
    final displayName = user.fullName.trim().isEmpty
        ? 'Profile User'
        : user.fullName.trim();
    final email = user.emailAddress.trim().isEmpty
        ? user.phoneNumber
        : user.emailAddress.trim();

    return ProfileHeroCard(
      displayName: displayName,
      subtitle: email,
      imageUrl: user.profileImage,
      avatarBadge: ProfileCircleButton(
        icon: Icons.photo_camera_rounded,
        size: 30,
        onTap: isUploadingImage ? null : () => _showImageSourceModal(context),
      ),
      chips: [
        ProfileChip(
          label: user.userActive ? 'Active' : 'Inactive',
          icon: user.userActive
              ? Icons.check_circle_outline_rounded
              : Icons.pause_circle_outline_rounded,
          color: user.userActive ? kSuccessGreen : kWhite,
        ),
      ],
      footer: ProfileHeroAction(
        icon: Icons.photo_camera_outlined,
        label: 'Change Profile Photo',
        onTap: isUploadingImage ? () {} : () => _showImageSourceModal(context),
      ),
    );
  }

  Widget _buildInfoRow(
    ProfilePalette palette, {
    required IconData icon,
    required String label,
    required String value,
    bool locked = false,
  }) {
    final hasValue = value.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          ProfileIconChip(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.supporting,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasValue ? value : 'Not provided',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: hasValue ? palette.headline : palette.supporting,
                  ),
                ),
              ],
            ),
          ),
          if (locked) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: palette.sectionLabel,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy').format(date.toLocal());
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy • HH:mm').format(date.toLocal());
  }
}
