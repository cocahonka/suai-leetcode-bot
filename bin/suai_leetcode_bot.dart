import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:sqlite3/open.dart' as sqlite;
import 'package:suai_leetcode_bot/bot/repositories/runtime_repository.dart';
import 'package:suai_leetcode_bot/bot/scopes/register/register_scope.dart';
import 'package:suai_leetcode_bot/bot/scopes/register/register_state.dart';
import 'package:suai_leetcode_bot/bot/telegram_bot.dart';
import 'package:suai_leetcode_bot/config/config.dart';
import 'package:suai_leetcode_bot/data/api/leetcode_api.dart';
import 'package:suai_leetcode_bot/data/database/database.dart';
import 'package:suai_leetcode_bot/data/repositories/leetcode_repository.dart';

void main() {
  sqlite.open
    ..overrideFor(sqlite.OperatingSystem.linux, _openOnLinux)
    ..overrideFor(sqlite.OperatingSystem.windows, _openOnWindows);

  final database = AppDatabase();
  final config = _readConfig();
  final httpClient = http.Client();

  final leetCodeRepository = HttpLeetCodeRepository(
    api: const LeetCodeApi(),
    client: httpClient,
  );

  final scopes = [
    RegisterScope(
      database: database,
      repository: RuntimeRepository(initialState: const RegisterInitial()),
      leetCodeRepository: leetCodeRepository,
    ),
  ];

  TelegramBot(
    config: config,
    database: database,
    scopes: scopes,
  ).start();
}

Config _readConfig() {
  final scriptFolderPath = File(Platform.script.toFilePath()).parent.path;
  final configFolderPath = path.join(scriptFolderPath, 'config');
  final jsonConfig = File(path.join(configFolderPath, 'env.config.json'));

  final content = jsonConfig.readAsStringSync();
  final json = jsonDecode(content) as Map<String, dynamic>;
  return Config.fromJson(json);
}

DynamicLibrary _openOnLinux() {
  final scriptFolderPath = File(Platform.script.toFilePath()).parent.path;
  final libsFolderPath = path.join(scriptFolderPath, 'libs');
  final libraryNextToDatabase = path.join(libsFolderPath, 'sqlite3.so');
  return DynamicLibrary.open(libraryNextToDatabase);
}

DynamicLibrary _openOnWindows() {
  final scriptFolderPath = File(Platform.script.toFilePath()).parent.path;
  final libsFolderPath = path.join(scriptFolderPath, 'libs');
  final libraryNextToDatabase = path.join(libsFolderPath, 'sqlite3.dll');
  return DynamicLibrary.open(libraryNextToDatabase);
}
