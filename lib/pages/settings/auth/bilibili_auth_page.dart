import 'package:bili_tracker/apis/bilibili_api.dart';
import 'package:bili_tracker/pages/settings/login_page.dart';
import 'package:bili_tracker/providers/settings_provider.dart';
import 'package:bili_tracker/utils/ext.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BilibiliAuthPage extends StatefulWidget {
  const BilibiliAuthPage({super.key});

  @override
  State<BilibiliAuthPage> createState() => _BilibiliAuthPageState();
}

class _BilibiliAuthPageState extends State<BilibiliAuthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bilibili账号')),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(8),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              _buildUserInfo(context, settingsProvider),
              // _buildNotificationsSwitch(context, settingsProvider),
              // _buildLanguageSelection(context, settingsProvider),
              // _buildFontSizeSlider(context, settingsProvider),
              // _buildTrackingUserSelection(context, settingsProvider),
              _buildCookiesInput(context, settingsProvider),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('扫码登录'),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (item) => const LoginPage()),
                  );
                },
              ).cardx,
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInfo(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return ListTile(
      leading: const Icon(Icons.person),
      title: const Text('用户信息'),
      subtitle: Text(
        '${settingsProvider.settings.username} ${settingsProvider.settings.rank}',
      ),
      onTap: () {},
    ).cardx;
  }

  Widget _buildCookiesInput(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    final TextEditingController controller = TextEditingController(
      text: settingsProvider.settings.cookies,
    );

    return ListTile(
      leading: const Icon(Icons.link),
      title: const Text('Bilibili Cookies (SESSDATA)'),
      subtitle:
          settingsProvider.settings.cookies != ''
              ? Text(settingsProvider.settings.cookies, maxLines: 1)
              : const Text('Not set'),
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Bilibili Cookies'),
              content: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Enter Cookies'),
                keyboardType: TextInputType.url,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await settingsProvider.changeCookies(controller.text);
                      final selfInfo = await BilibiliApi.selfInfo();
                      final mid = selfInfo['data']['mid'];
                      final uname = selfInfo['data']['uname'];
                      final userid = selfInfo['data']['userid'];
                      final info = await BilibiliApi.getUserSpaceInfo(mid);
                      final rank = info['data']['vip']['label']['text'];

                      settingsProvider.changeMid(mid.toString());
                      settingsProvider.changeUsername(uname.toString());
                      settingsProvider.changeUid(userid.toString());
                      settingsProvider.changeRank(rank.toString());
                    } catch (e) {
                      print(e.toString());
                    }
                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).cardx;
  }
}
