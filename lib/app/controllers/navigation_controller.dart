import 'package:get/get.dart';

class NavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    if (index >= 0 && index <= 4) {
      currentIndex.value = index;
    }
  }

  void goToHome() => changeTab(0);
  void goToProjects() => changeTab(1);
  void goToInvestments() => changeTab(2);
  void goToReturns() => changeTab(3);
  void goToProfile() => changeTab(4);
}
