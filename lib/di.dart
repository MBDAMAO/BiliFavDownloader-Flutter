import 'package:bili_tracker/providers/download_tasks_provider.dart';
import 'package:bili_tracker/providers/platform_provider.dart';
import 'package:bili_tracker/repo/download_cursor_repo.dart';
import 'package:bili_tracker/repo/search_history_repository.dart';
import 'package:bili_tracker/services/settings_service.dart';
import 'package:bili_tracker/providers/settings_provider.dart';
import 'package:bili_tracker/utils/platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repo/saved_repository.dart';
import 'repo/stared_folder_repository.dart';
import 'repo/task_repository.dart';

import 'objectbox.g.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  getIt.registerSingleton<SettingsService>(SettingsService());

  getIt.registerSingleton<SettingsProvider>(
    SettingsProvider(getIt<SettingsService>()),
  );

  getIt.registerSingleton<PlatformProvider>(PlatformProvider());

  final databaseDir = await getDatabaseDirectory();
  final Store store = await openStore(directory: databaseDir.path);
  final taskRepository = TaskRepository(store);
  final savedRepository = SavedRepository(store);
  final searchHistoryRepository = SearchHistoryRepository(store);
  getIt.registerSingleton<SearchHistoryRepository>(searchHistoryRepository);

  getIt.registerSingleton<StaredFolderRepository>(
    StaredFolderRepository(store),
  );
  getIt.registerSingleton<TaskRepository>(taskRepository);
  getIt.registerSingleton<SavedRepository>(savedRepository);
  getIt.registerSingleton<DownloadCursorRepository>(
    DownloadCursorRepository(store),
  );
  getIt.registerSingleton<DownloadTasksProvider>(
    DownloadTasksProvider(taskRepository),
  );
  getIt.registerSingleton<GlobalKey<NavigatorState>>(
    GlobalKey<NavigatorState>(),
  );
  await getIt<DownloadTasksProvider>().initializeTasks();
}
