import 'dart:io';

import 'package:path/path.dart' as path;

final class LoggerService {
  factory LoggerService() => _instance;

  LoggerService._internal();

  static final LoggerService _instance = LoggerService._internal();

  File get _file {
    final scriptFolderPath = File(Platform.script.toFilePath()).parent.path;
    final logsFolderPath = path.join(scriptFolderPath, 'logs');
    final logsFile = File(path.join(logsFolderPath, 'logs.logs'))..createSync(recursive: true);
    return logsFile;
  }

  void writeError(Exception e, StackTrace s) {
    final buffer = StringBuffer()
      ..writeln('${"-" * 10} BEGIN OF ERROR ${"-" * 10}')
      ..writeln('Error $e with StackTrace $s')
      ..writeln('${"-" * 10} END OF ERROR ${"-" * 10}')
      ..writeln('\n');

    _file.writeAsStringSync(buffer.toString(), mode: FileMode.append);
  }
}
