import 'dart:io';

extension FileX on File {
  Future<bool> get isEmpty async => (await readAsBytes()).isEmpty;

  bool get isEmptySync => readAsBytesSync().isEmpty;
}
