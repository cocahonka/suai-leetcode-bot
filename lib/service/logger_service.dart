import 'dart:io';

import 'package:path/path.dart' as path;

final class LoggerService {
  factory LoggerService() => _instance;

  LoggerService._internal();

  static final LoggerService _instance = LoggerService._internal();

  File get _file {
    final scriptFolderPath = File(Platform.script.toFilePath()).parent.path;
    final logsFolderPath = path.join(scriptFolderPath, 'logs');
    final logsFile = File(path.join(logsFolderPath, 'logs.logs'));
    return logsFile;
  }

  void writeError(Exception e, StackTrace s) {
    _file
      ..writeAsString('${"-" * 10} BEGIN OF ERROR ${"-" * 10}')
      ..writeAsString('Error $e with StackTrace $s')
      ..writeAsString('${"-" * 10} END OF ERROR ${"-" * 10}')
      ..writeAsString('\n\n');
  }
}
