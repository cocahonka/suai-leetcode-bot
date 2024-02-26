import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:suai_leetcode_bot/bot/repositories/telegram_state_repository.dart';
import 'package:suai_leetcode_bot/bot/scopes/admin/admin_query_event.dart';
import 'package:suai_leetcode_bot/bot/scopes/admin/admin_state.dart';
import 'package:suai_leetcode_bot/bot/scopes/register/register_state.dart';
import 'package:suai_leetcode_bot/bot/scopes/telegram_scope.dart';
import 'package:suai_leetcode_bot/constants/crud.dart';
import 'package:suai_leetcode_bot/data/database/database.dart';
import 'package:suai_leetcode_bot/service/logger_service.dart';
import 'package:televerse/telegram.dart';
import 'package:televerse/televerse.dart';

final class AdminScope extends TelegramScope<AdminState> {
  const AdminScope({
    required AppDatabase database,
    required super.repository,
    required super.onStateComplete,
    required TelegramStateRepository<RegisterState> registerRepository,
  })  : _database = database,
        _registerRepository = registerRepository;

  final AppDatabase _database;
  final TelegramStateRepository<RegisterState> _registerRepository;

  @override
  String get identificator => 'admin_scope';

  @override
  RegExp get commands => RegExp(r'^\/admin$');

  Future<bool> _isAdmin(int chatId) async {
    return _registerRepository.getState(chatId: chatId) is RegisterCompleted && await _database.isAdmin(chatId);
  }

  @override
  FutureOr<void> callbackOnCommand(Context<Session> context) async {
    final chatId = context.chat!.id;
    final command = context.message!.text!;

    if (!await _isAdmin(chatId)) return;

    if (RegExp('admin').hasMatch(command)) {
      repository.setState(chatId: chatId, state: const AdminWork());
      await callbackOnMessage(context);
    }
  }

  @override
  bool predicate(Context<Session> context) {
    final chatId = context.chat?.id;
    final message = context.message;

    if (chatId == null || message == null) return false;
    return repository.getState(chatId: chatId) is! AdminInitial;
  }

  @override
  FutureOr<void> callbackOnMessage(Context<Session> context) async {
    final chatId = context.chat!.id;

    if (!await _isAdmin(chatId)) return;

    switch (repository.getState(chatId: chatId)) {
      case AdminWaitForCRUD():
        await _takeCRUDForm(context);
      case AdminWork():
        await context.reply(
          'Выберите действие',
          replyMarkup: InlineKeyboard()
              .add('Выгрузить рейтинг', '${identificator}_${AdminQueryEvent.exportRating.name}')
              .row()
              .add('Выгрузить категории', '${identificator}_${AdminQueryEvent.exportCategories.name}')
              .row()
              .add('Внести изменения', '${identificator}_${AdminQueryEvent.requestCRUD.name}')
              .row()
              .add('Выход', '${identificator}_${AdminQueryEvent.exit.name}')
              .row(),
        );
      case AdminInitial():
    }
  }

  @override
  FutureOr<void> callbackOnQuery(Context<Session> context) async {
    final chatId = context.chat!.id;
    if (!await _isAdmin(chatId)) return;

    await context.answerCallbackQuery();

    final queryData = context.callbackQuery!.data!;
    final queryEventIdentificator = queryPattern.firstMatch(queryData)!.group(1)!;
    final queryEvent = AdminQueryEvent.values.firstWhereOrNull((value) => value.name == queryEventIdentificator);

    switch (queryEvent) {
      case AdminQueryEvent.exportRating:
        await _exportRating(context);
      case AdminQueryEvent.exportCategories:
        await _exportCategories(context);
      case AdminQueryEvent.requestCRUD:
        await _requestCRUD(context);
      case AdminQueryEvent.cancelCRUD:
        await _cancelCRUD(context);
      case AdminQueryEvent.exit:
        await _exit(context);
      case null:
    }
  }

  Future<void> _takeCRUDForm(Context<Session> context) async {
    final chatId = context.chat!.id;
    final document = context.message!.document;

    if (document == null && document?.mimeType != 'application/json') {
      await context.reply(
        'Нужно прислать файл .json, попробуйте еще раз!',
        replyMarkup: InlineKeyboard().add('Назад', '${identificator}_${AdminQueryEvent.cancelCRUD.name}').row(),
      );
      return;
    }

    const jsonDecoder = JsonDecoder();
    const utf8Decoder = Utf8Decoder();

    final Map<String, dynamic> json;

    try {
      final file = await context.getFile();
      final fileBytes = (await file.getBytes())!.toList();
      final fileContent = utf8Decoder.convert(fileBytes);
      json = jsonDecoder.convert(fileContent) as Map<String, dynamic>;
    } on Exception catch (e, s) {
      LoggerService().writeError(e, s);
      await context.reply('Произошла ошибка при скачивании файла');
      repository.setState(chatId: chatId, state: const AdminWork());
      callbackOnMessage(context);
      return;
    }

    final operations = _getParsedCRUD(json);

    if (operations == null) {
      await context.reply(
        'Файл не соответсвует формату example.json или не выполнены условия из правил, попробуйте еще раз!',
        replyMarkup: InlineKeyboard().add('Назад', '${identificator}_${AdminQueryEvent.cancelCRUD.name}').row(),
      );
      return;
    }

    final result = await _database.processCRUD(operations);
    if (result != null) {
      await context.reply(
        'Произошла ошибка: ${result.$1}\n, попробуйте еще раз',
        replyMarkup: InlineKeyboard().add('Назад', '${identificator}_${AdminQueryEvent.cancelCRUD.name}').row(),
      );
      final (e, s) = result;
      LoggerService().writeError(e is Exception ? e : Exception(e), s);
      return;
    }

    await context.reply('Изменения успешно внесены!');
    repository.setState(chatId: chatId, state: const AdminWork());
    callbackOnMessage(context);
  }

  CRUDOperations? _getParsedCRUD(Map<String, dynamic> json) {
    switch (json) {
      case {
          'categories': {
            'operations': {
              'create': final List<dynamic> categoriesCreate,
              'update': final List<dynamic> categoriesUpdate,
              'delete': final List<dynamic> categoriesDelete,
            },
          },
          'tasks': {
            'operations': {
              'create': final List<dynamic> tasksCreate,
              'update': final List<dynamic> tasksUpdate,
              'delete': final List<dynamic> tasksDelete,
            },
          },
        }:
        {
          return (
            categories: CRUD(
              create: categoriesCreate,
              update: categoriesUpdate,
              delete: categoriesDelete,
            ),
            tasks: CRUD(
              create: tasksCreate,
              update: tasksUpdate,
              delete: tasksDelete,
            )
          );
        }
    }

    return null;
  }

  Future<void> _exit(Context<Session> context) async {
    final chatId = context.chat!.id;
    repository.setState(chatId: chatId, state: const AdminInitial());
    onStateComplete?.call(context);
  }

  Future<void> _cancelCRUD(Context<Session> context) async {
    final chatId = context.chat!.id;

    repository.setState(chatId: chatId, state: const AdminWork());

    await callbackOnMessage(context);
  }

  Future<void> _requestCRUD(Context<Session> context) async {
    final chatId = context.chat!.id;
    const jsonEncoder = JsonEncoder.withIndent('  ');
    const utf8Encoder = Utf8Encoder();

    final exampleCrudBytes = utf8Encoder.convert(jsonEncoder.convert(kCrudExample));
    final emptyCrudBytes = utf8Encoder.convert(jsonEncoder.convert(kCrudEmpty));
    const message = '''
Если вы хотите внести изменения в категории или задачи то отправьте заполненный json файл или отмените операцию.

Правила:
1. В прикрепленном файле (example.json) содержится пример заполнения изменений.
2. В прикрепленном файле (form.json) содержится форма для заполнения.
3. При создании следует указать все поля.
4. При обновлении следует следует указать id или slug, другие поля опциональны.
5. При удалении следует указать только id или slug
6. При создании заданий необходимо знать id категории, для этого сначала создайте категорию, а потом выгрузите категорию, в выгруженном файле будут id категорий.''';

    await context.reply(message);
    await context.replyWithMediaGroup(
      [
        InputMediaDocument(media: InputFile.fromBytes(exampleCrudBytes, name: 'example.json')),
        InputMediaDocument(media: InputFile.fromBytes(emptyCrudBytes, name: 'form.json')),
      ],
      protectContent: true,
    );
    repository.setState(chatId: chatId, state: const AdminWaitForCRUD());
  }

  Future<void> _exportCategories(Context<Session> context) async {
    final tasksByCategories = await _database.tasksByCategories;
    final json = jsonDecode(jsonEncode(kCrudEmpty)) as Map<String, dynamic>;

    for (final (:category, :tasks) in tasksByCategories) {
      final categoryJson = category.toJson();
      // ignore: avoid_dynamic_calls
      json['categories']['operations']['create'].add(categoryJson);
      // ignore: avoid_dynamic_calls
      json['tasks']['operations']['create'].addAll(tasks.map((t) => t.toJson()));
    }

    const jsonEncoder = JsonEncoder.withIndent('  ');
    const utf8Encoder = Utf8Encoder();

    final bytes = utf8Encoder.convert(jsonEncoder.convert(json));

    await context.replyWithDocument(
      InputFile.fromBytes(bytes, name: 'Tasks by categories.json'),
    );
  }

  Future<void> _exportRating(Context<Session> context) async {
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

typedef CRUDOperations = ({CRUD categories, CRUD tasks});

final class CRUD {
  const CRUD({
    required this.create,
    required this.update,
    required this.delete,
  });
  final List<dynamic> create;
  final List<dynamic> update;
  final List<dynamic> delete;
}
