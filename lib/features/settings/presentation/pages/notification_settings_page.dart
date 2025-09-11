import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(showBackButton: true),
      body: Center(child: Text('알림 설정 페이지')),
    );
  }
}