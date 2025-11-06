import 'package:bili_tracker/di.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TipWithChoice extends StatefulWidget {
  final String choiceKey;
  final Widget content;

  const TipWithChoice({
    super.key,
    required this.choiceKey,
    required this.content,
  });

  @override
  State<TipWithChoice> createState() => _TipWithChoiceState();
}

class _TipWithChoiceState extends State<TipWithChoice> {
  bool tip = true;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    tip = prefs.getBool(widget.choiceKey) ?? true;
  }

  void _onConfirm(BuildContext context) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool(widget.choiceKey, tip);
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('提示'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.content,
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: !tip,
                  onChanged: (value) {
                    setState(() {
                      tip = !(value ?? false);
                    });
                  },
                ),
                const Text("不再提示"),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => _onConfirm(context),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

Future<bool> showTipWithChoice(
  BuildContext context, {
  required String choiceKey,
  required Widget content,
}) async {
  final prefs = getIt<SharedPreferences>();
  if (prefs.getBool(choiceKey) == false) return true;
  bool choice = await showDialog(
    context: context,
    builder: (context) => TipWithChoice(content: content, choiceKey: choiceKey),
  );
  return choice;
}
