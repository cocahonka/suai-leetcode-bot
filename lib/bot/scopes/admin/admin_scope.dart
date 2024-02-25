import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:suai_leetcode_bot/bot/scopes/admin/admin_query_event.dart';
import 'package:suai_leetcode_bot/bot/scopes/admin/admin_state.dart';
import 'package:suai_leetcode_bot/bot/scopes/telegram_scope.dart';
import 'package:suai_leetcode_bot/data/database/database.dart';
import 'package:televerse/televerse.dart';

final class AdminScope extends TelegramScope<AdminState> {
  const AdminScope({
    required AppDatabase database,
    required super.repository,
  }) : _database = database;

  final AppDatabase _database;

  @override
  String get identificator => 'admin_scope';

  @override
  RegExp get commands => RegExp(r'^\/admin$');

  @override
  FutureOr<void> callbackOnCommand(Context<Session> context) async {
    final command = context.message!.text!;

    if (RegExp('admin').hasMatch(command)) {
      await callbackOnMessage(context);
    }
  }

  @override
  bool predicate(Context<Session> context) {
    return false;
  }

  @override
  FutureOr<void> callbackOnMessage(Context<Session> context) async {
    await context.reply(
      'Выберите действие',
      replyMarkup:
          InlineKeyboard().add('Выгрузить данные', '${identificator}_${AdminQueryEvent.exportData.name}').row(),
    );
  }

  @override
  FutureOr<void> callbackOnQuery(Context<Session> context) async {
    await context.answerCallbackQuery();

    final queryData = context.callbackQuery!.data!;
    final queryEventIdentificator = queryPattern.firstMatch(queryData)!.group(1)!;
    final queryEvent = AdminQueryEvent.values.firstWhereOrNull((value) => value.name == queryEventIdentificator);

    switch (queryEvent) {
      case AdminQueryEvent.exportData:
        await _exportData(context);
      case null:
    }
  }

  Future<void> _exportData(Context<Session> context) async {
    final excel = Excel.createExcel();
    final ratingPerCategory = await _database.getRatingPerCategory();

    for (final CategoryRating(:category, :tasks, :usersSubmissions) in ratingPerCategory) {
      final sheet = excel[category.shortTitle]
        ..merge(
          CellIndex.indexByString('A1'),
          CellIndex.indexByColumnRow(columnIndex: tasks.length + 3, rowIndex: 0),
          customValue: TextCellValue(category.title),
        )
        ..updateCell(CellIndex.indexByString('A2'), const TextCellValue('№'))
        ..updateCell(CellIndex.indexByString('B2'), const TextCellValue('Имя'))
        ..updateCell(CellIndex.indexByString('C2'), const TextCellValue('Ник'));

      for (final (index, leetCodeTask) in tasks.indexed) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: index + 3, rowIndex: 1),
          TextCellValue('${leetCodeTask.complexity.cutName}. ${leetCodeTask.id}. ${leetCodeTask.title}'),
        );
      }

      for (final (index, submissions) in usersSubmissions.indexed) {
        sheet.appendRow([
          TextCellValue('${index + 1}'),
          TextCellValue(submissions.user.name ?? 'unknown'),
          TextCellValue(submissions.account.nickname),
          ...[
            for (final _ in submissions.solvedTasks) const TextCellValue('+'),
          ],
        ]);
      }
    }

    final bytes = excel.save();
    if (bytes == null) {
      await context.reply('Не удалось составить таблицу, сообщите об этом Булату');
      return;
    }

    await context.replyWithDocument(
      InputFile.fromBytes(
        Uint8List.fromList(bytes),
        name: 'Data by ${DateTime.now()}.xlsx',
      ),
    );
  }
}
