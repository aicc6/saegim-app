import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(showBackButton: true),
      body: Center(child: Text('비밀번호 변경 페이지')),
    );
  }
}