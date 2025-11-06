import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:bili_tracker/apis/bilibili_api.dart';
import 'package:bili_tracker/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../di.dart';
import '../../utils/net.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  QRLoginPageState createState() => QRLoginPageState();
}

class QRLoginPageState extends State<LoginPage> {
  String? qrUrl;
  String? qrcodeKey;
  Timer? _pollingTimer;
  String statusMessage = '等待扫描...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQRCode() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 模拟API调用 - 实际项目中替换为真实的API调用
      final loginData = await BilibiliApi.getLoginQRCode();
      setState(() {
        qrcodeKey = loginData['data']['qrcode_key'];
        qrUrl = loginData['data']['url'];
        isLoading = false;
      });

      // 开始轮询登录状态
      _startPollingLoginStatus();
    } catch (e) {
      setState(() {
        statusMessage = '生成二维码失败: $e';
        isLoading = false;
      });
    }
  }

  Future _downloadQRCode() async {
    try {
      if (qrUrl == null) return;

      // Create a painter for the QR code
      final qrPainter = QrPainter(
        data: qrUrl!,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      // Convert the QR code to an image
      ByteData? byteData = await qrPainter.toImageData(300);

      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();

      // Get the temporary directory and save the file
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      final name = 'bili_login_qrcode_$time.png';

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(buffer, name: name);

      if (result != null && result['isSuccess'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('二维码已保存到相册')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('保存失败')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  void _startPollingLoginStatus() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (qrcodeKey == null) return;

      try {
        final status = await BilibiliApi.getLoginStatus(qrcodeKey!);
        final code = status['body']['data']['code'];
        final message = status['body']['data']['message'];

        setState(() {
          statusMessage = message ?? '未知状态';
        });

        if (code == 0) {
          // 登录成功
          timer.cancel();
          _handleLoginSuccess(status['headers']);
        } else if (code == 86038) {
          // 二维码已失效
          timer.cancel();
          _handleQRCodeExpired();
        } else if (code == 86090) {
          // 二维码已扫描
          setState(() {
            statusMessage = '二维码已扫描，等待确认...';
          });
        }
        // 其他状态码可以继续轮询
      } catch (e) {
        setState(() {
          statusMessage = '检查登录状态失败: $e';
        });
      }
    });
  }

  void _handleLoginSuccess(Map<String, dynamic> headers) async {
    final settingsProvider = getIt<SettingsProvider>();
    String cookiesStr = headers['set-cookie'];
    await settingsProvider.changeCookies(cookiesStr);
    await Network.updateCookie(cookiesStr);
    final selfInfo = await BilibiliApi.selfInfo();
    final mid = selfInfo['data']['mid'];
    final uname = selfInfo['data']['uname'];
    final userid = selfInfo['data']['userid'];
    final info = await BilibiliApi.getUserSpaceInfo(mid);
    final rank = info['data']['vip']['label']['text'];

    await settingsProvider.changeMid(mid.toString());
    await settingsProvider.changeUsername(uname.toString());
    await settingsProvider.changeUid(userid.toString());
    await settingsProvider.changeRank(rank.toString());

    setState(() {
      statusMessage = '登录成功! $uname';
    });
    if (mounted) {
      Navigator.of(context).pop(cookiesStr);
    }
  }

  void _handleQRCodeExpired() {
    setState(() {
      statusMessage = '二维码已失效，点击刷新';
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final qrSize = size.width * 0.8 > 400 ? 400.0 : size.width * 0.8;

    return Scaffold(
      appBar: AppBar(title: const Text('二维码登录')),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child:
            isLoading
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (qrUrl != null)
                      GestureDetector(
                        onTap: qrUrl == null ? null : _generateQRCode,
                        child: SizedBox(
                          width: qrSize,
                          height: qrSize,
                          child: QrImageView(
                            data: qrUrl!,
                            version: QrVersions.auto,
                            size: qrSize,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      statusMessage,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    if (Platform.isAndroid || Platform.isIOS)
                      ElevatedButton(
                        onPressed: _downloadQRCode,
                        child: const Text('下载到相册'),
                      ),
                    if (statusMessage.contains('失效'))
                      ElevatedButton(
                        onPressed: _generateQRCode,
                        child: const Text('刷新二维码'),
                      ),
                  ],
                ),
      ),
    );
  }
}
