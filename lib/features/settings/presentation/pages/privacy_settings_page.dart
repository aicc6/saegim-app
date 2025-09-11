import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(showBackButton: true),
      body: Center(child: Text('개인정보 설정 페이지')),
    );
  }
}