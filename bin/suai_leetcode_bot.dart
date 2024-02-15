import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqlite3/open.dart' as sqlite;
import 'package:suai_leetcode_bot/database/database.dart';

Future<void> main() async {
  sqlite.open
    ..overrideFor(sqlite.OperatingSystem.linux, _openOnLinux)
    ..overrideFor(sqlite.OperatingSystem.windows, _openOnWindows);

  final database = AppDatabase();

  await database.into(database.articles).insert(
        ArticlesCompanion.insert(
          title: 'Test title',
          content: 'Test database works',
        ),
      );

  final allArticles = await database.select(database.articles).get();

  // ignore: avoid_print
  print('Articles in database: $allArticles');
  exit(0);
}

DynamicLibrary _openOnLinux() {
  final scriptFolderPath = File(Platform.script.toFilePath()).parent.path;
  final libraryNextToScript = path.join(scriptFolderPath, 'sqlite3.so');
  return DynamicLibrary.open(libraryNextToScript);
}

DynamicLibrary _openOnWindows() {
  final scriptFolderPath = File(Platform.script.toFilePath()).parent.path;
  final libraryNextToScript = path.join(scriptFolderPath, 'sqlite3.dll');
  return DynamicLibrary.open(libraryNextToScript);
}
