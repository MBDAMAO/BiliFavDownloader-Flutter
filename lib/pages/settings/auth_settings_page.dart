import 'package:bili_tracker/pages/settings/auth/bilibili_auth_page.dart';
import 'package:bili_tracker/utils/ext.dart';
import 'package:flutter/material.dart';

class AuthSettingsPage extends StatefulWidget {
  const AuthSettingsPage({super.key});

  @override
  State<AuthSettingsPage> createState() => _AuthSettingsPageState();
}

class _AuthSettingsPageState extends State<AuthSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账号管理')),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          ListTile(
            leading: Icon(Icons.account_circle_outlined),
            title: Text('Bilibili账号'),
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (item) => const BilibiliAuthPage()),
              );
            },
          ).cardx,
        ]
      ),
    );
  }
}
