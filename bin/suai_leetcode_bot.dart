import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqlite3/open.dart' as sqlite;
import 'package:suai_leetcode_bot/bot/telegram_bot.dart';
import 'package:suai_leetcode_bot/config/config.dart';
import 'package:suai_leetcode_bot/database/database.dart';

void main() {
  sqlite.open
    ..overrideFor(sqlite.OperatingSystem.linux, _openOnLinux)
    ..overrideFor(sqlite.OperatingSystem.windows, _openOnWindows);

  final database = AppDatabase();
  final config = _readConfig();

  TelegramBot(config: config, database: database).start();
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
