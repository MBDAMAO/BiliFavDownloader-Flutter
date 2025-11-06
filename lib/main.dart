import 'dart:io';

import 'package:bili_tracker/repo/saved_repository.dart';
import 'package:bili_tracker/pages/downloads/download_page.dart';
import 'package:bili_tracker/pages/fav/fav_screen.dart';
import 'package:bili_tracker/pages/settings/settings_page.dart';
import 'package:bili_tracker/providers/download_tasks_provider.dart';
import 'package:bili_tracker/providers/settings_provider.dart';
import 'package:bili_tracker/utils/download_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';
import 'di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
  }
  await setupDependencies();
  await DownloadManager.initialize(
    getIt<DownloadTasksProvider>(),
    getIt<SavedRepository>(),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => getIt<SettingsProvider>()),
        ChangeNotifierProvider(
          create: (context) => getIt<DownloadTasksProvider>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp(
          navigatorKey: getIt<GlobalKey<NavigatorState>>(),
          debugShowCheckedModeBanner: true,
          title: '哔哩追踪器',
          themeMode: settingsProvider.settings.themeMode,
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: settingsProvider.settings.themeColor,
            brightness: Brightness.dark,
            appBarTheme: AppBarTheme(scrolledUnderElevation: 0.0),
            fontFamily: 'MiSans',
          ),
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: settingsProvider.settings.themeColor,
            brightness: Brightness.light,
            appBarTheme: AppBarTheme(scrolledUnderElevation: 0.0),
            fontFamily: 'MiSans',
          ),
          builder: (BuildContext context, Widget? child) {
            MediaQueryData mediaQuery = MediaQuery.of(context);
            double safeTop = mediaQuery.padding.top;
            if (safeTop > 80 || safeTop < 0) {
              safeTop = 24.0;
            }
            return MediaQuery(
              data: mediaQuery.copyWith(
                padding: mediaQuery.padding.copyWith(top: safeTop),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 底部导航栏对应的页面
  final List<Widget> _screens = [
    const FavScreen(),
    const DownloadPage(),
    const SettingsPage(),
  ];

  // 导航项配置
  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.favorite_outline),
      selectedIcon: Icon(Icons.favorite),
      label: '收藏',
      tooltip: '我的收藏',
    ),
    NavigationDestination(
      icon: Icon(Icons.download_outlined),
      selectedIcon: Icon(Icons.download),
      label: '下载',
      tooltip: '下载管理',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: '设置',
      tooltip: '应用设置',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // 使用Material3的NavigationBar替代BottomNavigationBar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _destinations,
        // 增加动画效果
        animationDuration: const Duration(milliseconds: 300),
        // 配置高度和外观
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        // 使用主题颜色
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}
