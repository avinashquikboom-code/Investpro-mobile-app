import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/demo_repository.dart';
import '../utils/validators.dart';

class ProfileController extends GetxController {
  final DemoRepository _repo;

  ProfileController(this._repo);

  UserModel get user => _repo.currentUser.value;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    populateFields();
  }

  void populateFields() {
    nameController.text = user.fullName;
    emailController.text = user.email;
    phoneController.text = user.mobileNumber;
  }

  Future<bool> saveProfile() async {
    final nameError = Validators.validateName(nameController.text);
    if (nameError != null) {
      Get.snackbar('Validation Error', nameError, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    final emailError = Validators.validateEmail(emailController.text);
    if (emailError != null) {
      Get.snackbar('Validation Error', emailError, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    final phoneError = Validators.validateMobile(phoneController.text);
    if (phoneError != null) {
      Get.snackbar('Validation Error', phoneError, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    isSaving.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    isSaving.value = false;

    _repo.updateProfile(
      fullName: nameController.text.trim(),
      email: emailController.text.trim(),
      mobileNumber: phoneController.text.trim(),
    );

    Get.back();
    Get.snackbar(
      'Profile Updated',
      'Your profile information has been saved successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE8F8F0),
      colorText: const Color(0xFF006B3C),
    );
    return true;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
