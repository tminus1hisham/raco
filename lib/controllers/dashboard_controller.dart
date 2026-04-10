import 'package:get/get.dart';

class DashboardController extends GetxController {
  var isNavVisible = true.obs;
  var selectedIndex = 0.obs;

  void setIndex(int index) {
    selectedIndex.value = index;
  }
}
