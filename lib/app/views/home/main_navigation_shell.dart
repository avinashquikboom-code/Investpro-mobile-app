import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/navigation_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../investments/my_investments_view.dart';
import '../profile/profile_view.dart';
import '../projects/projects_view.dart';
import '../returns/returns_view.dart';
import 'home_view.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.find<NavigationController>();

    final pages = [
      const HomeView(),
      const ProjectsView(isTab: true),
      const MyInvestmentsView(isTab: true),
      const ReturnsView(isTab: true),
      const ProfileView(isTab: true),
    ];

    return Scaffold(
      body: Obx(() {
        return IndexedStack(
          index: navCtrl.currentIndex.value,
          children: pages,
        );
      }),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}
