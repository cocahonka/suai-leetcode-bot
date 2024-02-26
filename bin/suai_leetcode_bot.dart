import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:sqlite3/open.dart' as sqlite;
import 'package:suai_leetcode_bot/bot/repositories/runtime_repository.dart';
import 'package:suai_leetcode_bot/bot/scopes/admin/admin_scope.dart';
import 'package:suai_leetcode_bot/bot/scopes/admin/admin_state.dart';
import 'package:suai_leetcode_bot/bot/scopes/register/register_scope.dart';
import 'package:suai_leetcode_bot/bot/scopes/register/register_state.dart';
import 'package:suai_leetcode_bot/bot/scopes/telegram_scope.dart';
import 'package:suai_leetcode_bot/bot/scopes/user/user_scope.dart';
import 'package:suai_leetcode_bot/bot/scopes/user/user_state.dart';
import 'package:suai_leetcode_bot/bot/telegram_bot.dart';
import 'package:suai_leetcode_bot/config/config.dart';
import 'package:suai_leetcode_bot/data/api/leetcode_api.dart';
import 'package:suai_leetcode_bot/data/database/database.dart';
import 'package:suai_leetcode_bot/data/repositories/leetcode_repository.dart';
import 'package:suai_leetcode_bot/service/leetcode_service.dart';

void main() async {
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

  final registerRepository = RuntimeRepository<RegisterState>(initialState: const RegisterInitial());
  for (final User(:telegramId) in await database.authorizedUsers) {
    registerRepository.setState(chatId: telegramId, state: const RegisterCompleted());
  }

  final userScope = UserScope(
    messages: config.userMessages,
    database: database,
    repository: RuntimeRepository<UserState>(initialState: const UserInitial()),
  );

  final registerScope = RegisterScope(
    messages: config.registerMessages,
    database: database,
    repository: registerRepository,
    leetCodeRepository: leetCodeRepository,
    onStateComplete: userScope.executeInitialStatePoint,
  );

  final adminScope = AdminScope(
    database: database,
    messages: config.adminMessages,
    repository: RuntimeRepository<AdminState>(initialState: const AdminInitial()),
    registerRepository: registerRepository,
    onStateComplete: userScope.executeInitialStatePoint,
  );

  final scopes = <TelegramScope<dynamic>>[userScope, adminScope, registerScope];

  TelegramBot(
    config: config,
    scopes: scopes,
  ).start();

  LeetCodeService(
    leetCodeUpdateIntervalInSeconds: config.leetCodeUpdateIntervalInSeconds,
    database: database,
    leetCodeRepository: leetCodeRepository,
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
