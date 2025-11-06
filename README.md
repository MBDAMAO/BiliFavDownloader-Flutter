# Flutter Bilibili 收藏夹视频下载器

![](./assets/app.png)

一款基于 Flutter 开发的跨平台 B 站收藏夹视频下载工具，支持 Android 及 Windows 桌面端，让你轻松管理并下载 B 站收藏的视频内容，随时随地离线观看。

## 📱 应用特点

- **多平台支持**：基于 Flutter 开发，完美适配 Android 手机设备，同时支持 Windows 桌面系统

- **收藏夹同步**：登录 B 站账号后自动同步所有收藏夹，包括公开与私密收藏内容
- **多画质选择**：支持 1080P、720P、480P 等多种清晰度选择，满足不同场景需求
- **后台下载**：支持应用在后台继续下载任务，不影响正常使用手机
- **批量操作**：可选择单个或多个视频批量下载，也可一键下载整个收藏夹
- **下载管理**：暂停/继续/取消下载任务，支持断点续传
- **本地播放**：内置视频播放器，支持已下载视频的播放与管理
- **深色模式**：支持明暗主题自动切换，适应不同使用环境

## 📋 系统要求

| 平台    | 最低版本要求                |
| ------- | --------------------------- |
| Android | Android 8.0 (API 26) 及以上 |
| Windows | Windows 10 Windows 11       |

## 🚀 安装指南

### 移动端

#### Android

1. 从 Release 页面下载最新的 APK 文件（`bili_tracker_vx.x.x.apk`）
1. 在手机设置中开启"未知来源应用安装"权限
1. 点击 APK 文件完成安装

#### iOS

暂未支持

### 桌面端

#### Windows

1. 下载最新的 Windows 安装包（`bili_tracker_setup_vx.x.x.exe`）

2. 双击安装包，按照指引完成安装
3. 安装完成后可在开始菜单或桌面找到应用图标
4. 需要在命令行环境可访问的 ffmpeg

### mac & linux

暂未支持

## 💡 使用教程

### 1. 登录账号

- 打开应用，点击"我的"页面中的"登录"按钮
- 选择"扫码登录"或"账号密码登录"（推荐扫码登录，更安全便捷）
- 登录成功后将自动同步你的 B 站收藏夹

### 2. 浏览收藏夹

- 在首页或"收藏夹"页面查看所有同步的收藏夹
- 点击任意收藏夹可查看其中的视频列表
- 可通过顶部搜索框搜索特定收藏夹或视频

### 3. 下载视频

- 在视频列表中，点击视频右侧的"下载"按钮
- 选择所需的画质和是否下载弹幕
- 点击"确认下载"加入下载队列
- 可在"下载管理"页面查看下载进度

### 4. 管理已下载视频

- 在"本地视频"页面查看所有已下载完成的视频
- 支持播放、删除、分享等操作
- 可创建播放列表，自定义排序方式

## 🔧 开发与构建

如果你想自行构建或参与开发：

1. 确保已安装 Flutter SDK（3.7.2 及以上版本）

   ```bash
   # 检查Flutter版本
   flutter --version
   ```

2. 克隆代码仓库

   ```bash
   git clone https://github.com/MBDAMAO/bili_tracker.git
   cd bili_tracker
   ```

3. 获取依赖包

   ```bash
   flutter pub get
   ```

4. 运行调试版本

   ```bash
   # 运行在连接的设备或模拟器上
   flutter run
   ```

5. 构建发布版本

   ```bash
   # Android
   flutter build appbundle

   # iOS
   flutter build ipa

   # Windows
   flutter build windows

   # macOS
   flutter build macos

   # Linux
   flutter build linux
   ```

## 📝 注意事项

- 本工具仅用于个人学习和备份已收藏的视频，请勿用于商业用途
- 请遵守 B 站用户协议及版权相关法律法规，支持正版内容
- 部分付费视频、番剧、电影等受版权保护的内容可能无法下载
- 下载速度受网络环境影响，建议在 WiFi 环境下进行批量下载
- 应用不会存储你的账号密码，所有登录信息仅用于 B 站 API 验证

## 🤝 贡献指南

欢迎通过以下方式参与项目贡献：

1. 提交 Issue 报告 bug 或提出新功能建议
2. 提交 Pull Request 修复 bug 或实现新功能
3. 帮助完善文档或翻译多语言版本

## 📄 开源许可

本项目采用 GPL-3.0 许可证开源 - 详见 LICENSE 文件

## 💗 致谢

- [bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect)

