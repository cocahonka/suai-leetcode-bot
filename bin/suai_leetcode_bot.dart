import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqlite3/open.dart' as sqlite;

Future<void> main() async {
  sqlite.open
    ..overrideFor(sqlite.OperatingSystem.linux, _openOnLinux)
    ..overrideFor(sqlite.OperatingSystem.windows, _openOnWindows);
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
