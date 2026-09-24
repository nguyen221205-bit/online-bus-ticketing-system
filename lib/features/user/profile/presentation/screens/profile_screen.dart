import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/widgets/custom_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Tài khoản',
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text(
          'Thông tin cá nhân & cài đặt',
          style: TextStyle(color: AppColors.neutral600),
        ),
      ),
    );
  }
}
