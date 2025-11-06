import 'dart:io';
import 'package:bili_tracker/utils/platform.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:path/path.dart' as p;

class LogsPage extends StatefulWidget {
  final String? customLogDir; // 可自定义日志目录

  const LogsPage({super.key, this.customLogDir});

  @override
  LogsPageState createState() => LogsPageState();
}

class LogsPageState extends State<LogsPage> {
  List<FileSystemEntity> _logFiles = [];
  bool _isLoading = true;
  String _currentDir = '';

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  Future<void> _loadLogFiles() async {
    setState(() => _isLoading = true);

    try {
      Directory logDir;

      // 使用自定义目录或默认应用文档目录
      if (widget.customLogDir != null) {
        logDir = Directory(widget.customLogDir!);
      } else {
        logDir = Directory(p.join((await getRootPath()).path, 'logs'));
      }

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      List<FileSystemEntity> files = logDir.listSync();
      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );

      setState(() {
        _logFiles =
            files.where((f) => f.path.toLowerCase().endsWith('.log')).toList();
        _currentDir = logDir.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载日志失败: $e')));
    }
  }

  Future<void> _deleteLog(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('确认删除'),
            content: Text('确定要删除 ${_getFileName(_logFiles[index].path)} 吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _logFiles[index].delete();
        setState(() => _logFiles.removeAt(index));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除成功')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  Future<void> _viewLogContent(FileSystemEntity file) async {
    try {
      final content = await File(file.path).readAsString();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => Scaffold(
                appBar: AppBar(title: Text(_getFileName(file.path))),
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: SelectableText(
                    content,
                    style: TextStyle(fontFamily: 'Monospace', fontSize: 12),
                  ),
                ),
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('读取日志失败: $e')));
    }
  }

  String _getFileName(String path) => path.split('/').last;

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('日志文件'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadLogFiles),
          if (_currentDir.isNotEmpty)
            IconButton(
              icon: Icon(Icons.folder_open),
              onPressed:
                  () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('日志目录: $_currentDir'))),
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _logFiles.isEmpty
              ? Center(
                child: Text('没有找到日志文件', style: TextStyle(color: Colors.grey)),
              )
              : ListView.builder(
                physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: _logFiles.length,
                itemBuilder: (context, index) {
                  final file = _logFiles[index];
                  final stat = file.statSync();
                  return ListTile(
                    leading: Icon(Icons.insert_drive_file),
                    title: Text(_getFileName(file.path)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatDate(stat.modified)),
                        Text(_formatFileSize(stat.size)),
                      ],
                    ),
                    onTap: () => _viewLogContent(file),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _deleteLog(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
