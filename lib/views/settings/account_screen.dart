import 'package:atom/config/constants.dart';
import 'package:atom/controllers/update_profile_controller.dart';
import 'package:atom/controllers/user_data_controller.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/services/upload_image_service.dart';
import 'package:atom/views/camera_screen.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final UserResourceController controller = Get.put(UserResourceController());
  String profileUrl = '';
  XFile? profileImage;
  bool isUploadingImage = false;

  final ImageUploaderService uploadPictureService = ImageUploaderService();
  final UpdateProfileController updateController = Get.put(
    UpdateProfileController(),
  );

  Future<void> _onImagePicked(XFile? image) async {
    if (image != null) {
      setState(() {
        profileImage = image;
        isUploadingImage = true;
      });

      String? uploadedUrl = await uploadPictureService.uploadPicture(image);

      if (uploadedUrl != null) {
        setState(() {
          profileUrl = uploadedUrl;
          StorageService.storeData({'profileUrl': profileUrl});
        });

        updateController.image.value = uploadedUrl;
        bool success = await updateController.updateProfile(context);

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

        setState(() {
          isUploadingImage = false;
        });
      } else {
        setState(() {
          isUploadingImage = false;
        });
        Get.snackbar("Error", "Image upload failed");
      }
    }
  }

  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo, color: kBlue),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final picker = ImagePicker();
                    final pickedImage = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    _onImagePicked(pickedImage);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: kBlue),
                  title: const Text('Take a Photo'),
                  onTap: () async {
                    Navigator.pop(context);
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
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          backgroundColor: kBgGrey,
          body: Center(
            child: LoadingAnimationWidget.fourRotatingDots(
              color: kBlue,
              size: 50,
            ),
          ),
        );
      }

      final user = controller.user.value;
      if (user == null) {
        return Scaffold(
          backgroundColor: kBgGrey,
          body: const Center(
            child: Text(
              "No user data found",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: kBgGrey,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  customHeader(label: "Profile", icon: Icons.person),
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 130,
                              width: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child:
                                  (user.profileImage != null &&
                                      user.profileImage!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        user.profileImage!,
                                        fit: BoxFit.cover,
                                        width: 130,
                                        height: 130,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                Icons.person,
                                                size: 80,
                                                color: Colors.grey,
                                              );
                                            },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                            ),

                            Positioned(
                              bottom: 0,
                              right: 100,
                              child: GestureDetector(
                                onTap: () async {
                                  _showImageSourceModal(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: kBlue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _buildInfoRow(
                          Icons.person_outline,
                          'Full Name',
                          user.fullName,
                        ),
                        const SizedBox(height: 16),

                        _buildInfoRow(
                          Icons.email_outlined,
                          'Email',
                          user.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Phone',
                          user.phoneNumber,
                        ),
                        const SizedBox(height: 32),

                        CustomButton(
                          callBackFunction: () {},
                          label: "Edit Profile",
                          backgroundColor: kBlue,
                          txtColor: kWhite,
                        ),
                        const SizedBox(height: 10),

                        CustomBorderButton(
                          callBackFunction: () {
                            Navigator.pop(context);
                          },
                          label: "Back",
                          borderColor: kLightGrey,
                          txtColor: kBlack,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isUploadingImage)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: kBlue,
                    size: 50,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kBlue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
