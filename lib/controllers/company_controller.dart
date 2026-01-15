import 'package:atom/models/company_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class CompanyController extends GetxController {
  var isLoading = true.obs;
  var companyModel = Rxn<CompanyModel>();

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
  }

  Future<void> fetchCompanies({bool silent = false}) async {
    try {
      if (!silent) {
        isLoading(true);
      }
      var fetchedModel = await ApiService.fetchCompanies();
      debugPrint('Fetched CompanyModel: ${fetchedModel}');
      companyModel.value = fetchedModel;
    } finally {
      if (!silent) {
        isLoading(false);
      }
    }
  }
}
