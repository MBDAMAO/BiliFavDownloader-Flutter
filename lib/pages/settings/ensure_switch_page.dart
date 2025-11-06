import 'package:bili_tracker/di.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnsureSwitchPage extends StatefulWidget {
  const EnsureSwitchPage({super.key});

  @override
  State<EnsureSwitchPage> createState() => _EnsureSwitchPageState();
}

class _EnsureSwitchPageState extends State<EnsureSwitchPage> {
  @override
  Widget build(BuildContext context) {
    final prefs = getIt<SharedPreferences>();
    return Scaffold(
      appBar: AppBar(title: const Text('提示偏好设置')),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          buildSwitch("本地文件删除提示", "删除文件前，是否确认", "delete_local_file", prefs),
          buildSwitch("任务删除提示", "清除任务前，是否确认", "delete_task", prefs),
        ],
      ),
    );
  }

  Widget buildSwitch(
    String title,
    String subtitle,
    String key,
    SharedPreferences prefs,
  ) {
    bool value = prefs.getBool(key) ?? true;
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: (changed) async {
          await prefs.setBool(key, changed);
          setState(() {
            value = changed;
          });
        },
      ),
    );
  }
}

Future navigateToEnsureSwitchPage(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const EnsureSwitchPage(),
    ),
  );
}