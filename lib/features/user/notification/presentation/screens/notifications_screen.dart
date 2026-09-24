import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/widgets/custom_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Thông báo',
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text(
          'Thông báo chuyến đi và ưu đãi',
          style: TextStyle(color: AppColors.neutral600),
        ),
      ),
    );
  }
}
