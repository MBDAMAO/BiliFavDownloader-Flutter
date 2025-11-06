import 'package:bili_tracker/models/saved.dart';
import 'package:bili_tracker/pages/settings/auth_settings_page.dart';
import 'package:bili_tracker/pages/settings/ensure_switch_page.dart';
import 'package:bili_tracker/pages/settings/memory_analyse_page.dart';
import 'package:bili_tracker/pages/settings/save_quality_page.dart';
import 'package:bili_tracker/pages/settings/test_page.dart';
import 'package:bili_tracker/pages/settings/theme_settings.dart';
import 'package:bili_tracker/utils/ext.dart';
import 'package:bili_tracker/utils/toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../repo/saved_repository.dart';
import '../../di.dart';
import '../../providers/settings_provider.dart';
import 'logs_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(8),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // 仅在debug下有
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('测试页（仅在debug下）'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (item) => WashingMachinePage(),
                      ),
                    );
                  },
                ).cardx,

              // _buildNotificationsSwitch(context, settingsProvider),
              // _buildLanguageSelection(context, settingsProvider),
              // _buildFontSizeSlider(context, settingsProvider),
              // _buildTrackingUserSelection(context, settingsProvider),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('主题设置'),
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (item) => const ThemeSettings()),
                  );
                },
              ).cardx,
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('账号管理'),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (item) => const AuthSettingsPage(),
                    ),
                  );
                },
              ).cardx,
              ListTile(
                leading: const Icon(Icons.tips_and_updates_outlined),
                title: const Text('提示提醒设置'),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (item) => const EnsureSwitchPage(),
                    ),
                  );
                },
              ).cardx,
              // ListTile(
              //   leading: const Icon(Icons.storage),
              //   title: const Text('存储占用'),
              //   onTap: () async {
              //     await Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (item) => const MemoryAnalysePage(),
              //       ),
              //     );
              //   },
              // ).cardx,
              // ListTile(
              //   leading: const Icon(Icons.video_settings),
              //   title: Text('音视频下载质量'),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (item) => const SaveQualityPage(),
              //       ),
              //     );
              //   },
              // ).cardx,
              ListTile(
                leading: const Icon(Icons.import_export),
                title: const Text('导入导出数据'),
                onTap: () {
                  final controller = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (innerContext) {
                      return AlertDialog(
                        title: const Text('导入导出数据'),
                        content: TextField(
                          controller: controller,
                          maxLines: 5,
                          minLines: 1,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '请输入数据',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              List<Saved> allData =
                                  await getIt<SavedRepository>().findAllSaved();
                              String dataExport = "";
                              if (allData.isEmpty) return;
                              for (var saved in allData) {
                                dataExport +=
                                    '[aid:${saved.aid},cid:${saved.cid}]\n';
                              }
                              // remove last \n
                              dataExport = dataExport.substring(
                                0,
                                dataExport.length - 1,
                              );
                              controller.text = dataExport;
                              // saved to clip board
                              await Clipboard.setData(
                                ClipboardData(text: dataExport),
                              );
                              // Navigator.pop(innerContext);
                            },
                            child: const Text('导出'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                final rawInput = controller.text;
                                List<String> rawData = rawInput.split('\n');
                                List<Saved> savedData = [];
                                for (var raw in rawData) {
                                  if (raw.isEmpty) continue;
                                  List<String> data = raw.split(',');
                                  if (data.length != 2) continue;
                                  final aid = int.parse(
                                    data[0].replaceAll('[aid:', ''),
                                  );
                                  final cid = int.parse(
                                    data[1]
                                        .replaceAll('cid:', '')
                                        .replaceAll(']', ''),
                                  );
                                  final saved = Saved(
                                    id: 0,
                                    aid: aid,
                                    cid: cid,
                                    createTime: DateTime.now().toString(),
                                  );
                                  saved.status = Status.completed;
                                  savedData.add(saved);
                                }
                                await getIt<SavedRepository>()
                                    .batchInsertSavedOptimized(savedData);
                                toastInfo('导入成功');
                              } catch (e) {
                                controller.text = '导入失败$e';
                              }
                            },
                            child: const Text('导入'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(innerContext);
                            },
                            child: const Text('关闭'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ).cardx,
              // ListTile(
              //   leading: const Icon(Icons.drive_file_rename_outline),
              //   title: const Text('文件保存命名规则'),
              //   subtitle: Text(settingsProvider.settings.fileNameRule),
              //   onTap: () {
              //     final con = TextEditingController(
              //       text: settingsProvider.settings.fileNameRule,
              //     );

              //     // 定义允许使用的业务参数列表（注意：这里只包含参数名，不包含{}）
              //     final allowedParams = {
              //       'title',
              //       'avid',
              //       'cid',
              //       'date',
              //       'time',
              //       'timestamp',
              //       'userId',
              //       'projectId',
              //       'fileName',
              //       'ext',
              //       'sequence',
              //     };

              //     // 校验命名规则格式的函数
              //     bool isValidFileNameRule(String rule) {
              //       // 查找所有用{}包裹的参数（正确的正则表达式）
              //       final regex = RegExp(r'\{(\w+)\}');
              //       final matches = regex.allMatches(rule);

              //       // 检查每个匹配项是否为允许的参数
              //       for (var match in matches) {
              //         // 提取{}中的参数名（第一个分组）
              //         final param = match.group(1);
              //         if (param == null || !allowedParams.contains(param)) {
              //           return false;
              //         }
              //       }
              //       return true;
              //     }

              //     showDialog(
              //       context: context,
              //       builder: (innerContext) {
              //         return AlertDialog(
              //           title: const Text('文件保存命名规则'),
              //           content: StatefulBuilder(
              //             builder: (context, setState) {
              //               return Column(
              //                 mainAxisSize: MainAxisSize.min,
              //                 children: [
              //                   TextField(
              //                     controller: con,
              //                     maxLines: 5,
              //                     minLines: 1,
              //                     decoration: InputDecoration(
              //                       border: const OutlineInputBorder(),
              //                       hintText: '请输入命名规则',
              //                       errorText:
              //                           !isValidFileNameRule(con.text)
              //                               ? '格式错误！请使用允许的参数，参数需用{}包裹：${allowedParams.map((p) => '{$p}').join(', ')}'
              //                               : null,
              //                     ),
              //                     onChanged: (value) {
              //                       // 实时输入变化时重新校验
              //                       setState(() {});
              //                     },
              //                   ),
              //                   const SizedBox(height: 8),
              //                   const Text(
              //                     '可用参数说明：\n'
              //                     '{title} - 视频标题\n'
              //                     '{avid} - 视频ID\n'
              //                     '{cid} - 视频PID\n'
              //                     '{date} - 日期(yyyyMMdd)\n'
              //                     '{time} - 时间(HHmmss)\n'
              //                     '{timestamp} - 时间戳\n'
              //                     '{userId} - 用户ID\n'
              //                     '{projectId} - 项目ID\n'
              //                     '{fileName} - 原始文件名\n'
              //                     '{ext} - 文件扩展名\n'
              //                     '{sequence} - 序号',
              //                     style: TextStyle(
              //                       fontSize: 12,
              //                       color: Colors.grey,
              //                     ),
              //                   ),
              //                 ],
              //               );
              //             },
              //           ),
              //           actions: [
              //             TextButton(
              //               onPressed: () {
              //                 Navigator.pop(context);
              //               },
              //               child: const Text('取消'),
              //             ),
              //             TextButton(
              //               onPressed: () async {
              //                 if (isValidFileNameRule(con.text)) {
              //                   await settingsProvider.changeFileNameRule(
              //                     con.text,
              //                   );
              //                   Navigator.pop(context);
              //                 }
              //               },
              //               child: const Text('保存'),
              //               // 校验不通过时禁用保存按钮
              //               // enabled: isValidFileNameRule(con.text),
              //             ),
              //           ],
              //         );
              //       },
              //     );
              //   },
              // ).cardx,
              // Theme(
              //   data: Theme.of(
              //     context,
              //   ).copyWith(dividerColor: Colors.transparent),
              //   child:
              //       ExpansionTile(
              //         leading: const Icon(Icons.speed),
              //         title: const Text('下载限速'),
              //         subtitle: Text(
              //           '${settingsProvider.settings.maxDownloadSpeed.toStringAsPrecision(2)} MBps' ==
              //                   "10 MBps"
              //               ? "不限速"
              //               : "${settingsProvider.settings.maxDownloadSpeed.toStringAsPrecision(2)} MBps",
              //         ),
              //         children: [
              //           Slider(
              //             value: settingsProvider.settings.maxDownloadSpeed,
              //             min: 1,
              //             max: 10,
              //             onChanged: (value) {
              //               settingsProvider.changeMaxSpeed(value);
              //             },
              //           ),
              //         ],
              //       ).cardx,
              // ),
              ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('日志'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (item) => const LogsPage()),
                  );
                },
              ).cardx,
            ],
          );
        },
      ),
    );
  }
}
