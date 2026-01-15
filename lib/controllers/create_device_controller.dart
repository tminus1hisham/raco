import 'package:atom/models/register_device_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterDeviceController extends GetxController {
  var company = ''.obs;
  var name = ''.obs;
  var id = ''.obs;
  var phone = ''.obs;
  var reg = ''.obs;
  var chassis = ''.obs;
  var make = ''.obs;
  var certNo = ''.obs;
  var type = ''.obs;
  var serial = ''.obs;
  var date = ''.obs;
  var agent = ''.obs;
  var agentID = ''.obs;
  var location = ''.obs;
  var email = ''.obs;
  var agentPhone = ''.obs;
  var businessReg = ''.obs;
  var group = ''.obs;

  var isLoading = false.obs;

  final ApiService _apiService = ApiService();

  Future<bool> registration(BuildContext context) async {
    isLoading.value = true;

    try {
      final registerModel = RegisterDeviceModel(
        company: company.value.trim(),
        name: name.value.trim(),
        id: id.value.trim(),
        phone: phone.value.trim(),
        reg: reg.value.trim(),
        chassis: chassis.value.trim(),
        make: make.value.trim(),
        certNo: certNo.value.trim(),
        type: type.value.trim(),
        serial: serial.value.trim(),
        date: date.value.trim(),
        agent: agent.value.trim(),
        agentID: agentID.value.trim(),
        location: location.value.trim(),
        email: email.value.trim(),
        agentPhone: agentPhone.value.trim(),
        businessReg: businessReg.value.trim(),
        group: group.value.trim(),
      );

      final result = await ApiService.registerDevice(registerModel);

      if (result != null) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Registration failed: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

// user name and id
