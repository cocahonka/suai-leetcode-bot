import 'dart:async';

import 'package:collection/collection.dart';
import 'package:suai_leetcode_bot/bot/scopes/telegram_scope.dart';
import 'package:suai_leetcode_bot/bot/scopes/user/user_query_event.dart';
import 'package:suai_leetcode_bot/bot/scopes/user/user_state.dart';
import 'package:suai_leetcode_bot/config/config.dart';
import 'package:suai_leetcode_bot/data/database/database.dart';
import 'package:suai_leetcode_bot/service/leetcode_service.dart';
import 'package:televerse/telegram.dart';
import 'package:televerse/televerse.dart';

final class UserScope extends TelegramScope<UserState> {
  UserScope({
    required AppDatabase database,
    required UserMessages messages,
    required super.repository,
  })  : _database = database,
        _messages = messages {
    LeetCodeService.nextTimerRun.listen((time) => nextTimerRun = time);
  }

  final AppDatabase _database;
  final UserMessages _messages;
  DateTime? nextTimerRun;

  @override
  String get identificator => 'user_scope';

  @override
  RegExp get commands => RegExp(r'^(\/help|\/info|\/update)$');

  @override
  FutureOr<void> callbackOnCommand(Context<Session> context) async {
    if (context.chat?.isForum ?? false) return;

    final command = context.message!.text!;

    if (RegExp('help').hasMatch(command)) {
      await context.reply(_messages.howItWorks);
      return;
    }

    if (RegExp('info').hasMatch(command)) {
      await context.reply(_messages.howItWorks);
      return;
    }

    if (RegExp('update').hasMatch(command)) {
      if (nextTimerRun case final time?) {
        final (hour, minute) = (time.hour, time.minute);
        await context.reply(_messages.whenNextUpdate.replaceFirst(r'$', 'в $hour:$minute'));
        return;
      }

      await context.reply('Время неизвестно, попробуйте позже');

      return;
    }
  }

  @override
  bool predicate(Context<Session> context) {
    if (context.chat?.isForum ?? false) return false;

    final chatId = context.chat?.id;
    final message = context.message;

    if (chatId == null || message == null) return false;

    return true;
  }

  @override
  FutureOr<void> callbackOnMessage(Context<Session> context) async {
    await context.reply(
      _messages.chooseMenuItem,
      replyMarkup: InlineKeyboard()
          .addUrl(_messages.aboutClubCaption, _messages.aboutClubLink)
          .row()
          .addUrl(_messages.olympiadsCaption, _messages.olympiadsLink)
          .row()
          .addUrl(_messages.joinClubCaption, _messages.joinClubLink)
          .row()
          .add(_messages.categoryListCaption, '${identificator}_${UserQueryEvent.showCategories.name}')
          .row(),
    );
  }

  @override
  FutureOr<void> callbackOnQuery(Context<Session> context) async {
    if (context.chat?.isForum ?? false) return;

    await context.answerCallbackQuery();

    final queryData = context.callbackQuery!.data!;
    final queryEventIdentificator = queryPattern.firstMatch(queryData)!.group(1)!;
    final queryEvent = UserQueryEvent.values.firstWhereOrNull((value) => value.name == queryEventIdentificator);

    switch (queryEvent) {
      case UserQueryEvent.showCategories:
        await _showCategories(context);
      case UserQueryEvent.showCategoryDetails:
        final categoryUri = Uri.parse(queryData);
        final categoryId = categoryUri.queryParameters['id']!;
        await _showCategory(context, int.parse(categoryId));
      case UserQueryEvent.backToMenu:
        await callbackOnMessage(context);
      case UserQueryEvent.backToCategories:
        await _showCategories(context);
      case null:
    }
  }

  Future<void> _showCategories(Context<Session> context) async {
    final categories = await _database.allCategories;
    final keyboard = InlineKeyboard();
    for (final Category(:id, :shortTitle) in categories) {
      keyboard
        ..add(shortTitle, '${identificator}_${UserQueryEvent.showCategoryDetails.name}?id=$id')
        ..row();
    }

    keyboard
      ..add(_messages.backToMenu, '${identificator}_${UserQueryEvent.backToMenu.name}')
      ..row();

    await context.reply(_messages.chooseCategory, replyMarkup: keyboard);
  }

  Future<void> _showCategory(Context<Session> context, int categoryId) async {
    final chatId = context.chat!.id;
    final category = await _database.getCategory(categoryId);
    final tasks = await _database.getTasksWithUserSolutions(categoryId: categoryId, telegramId: chatId);

    final keyboard = InlineKeyboard().add(
      _messages.backToCategories,
      '${identificator}_${UserQueryEvent.backToCategories.name}',
    );

    final content = StringBuffer()
      ..writeln(category.title)
      ..writeln(category.description)
      ..writeln();

    for (final (:task, :isSolved) in tasks) {
      final taskMarker = isSolved ? '✅' : '❌';
      content
        ..write(taskMarker)
        ..write(' ${task.complexity.cutName}')
        ..write(' ${task.title}')
        ..write(' <a href="${task.link}">${_messages.taskLinkCaption}</a>')
        ..writeln();
    }

    await context.reply(
      content.toString(),
      replyMarkup: keyboard,
      parseMode: ParseMode.html,
      linkPreviewOptions: const LinkPreviewOptions(isDisabled: true),
    );
  }

  @override
  FutureOr<void> executeInitialStatePoint(Context<Session> context) async {
    await callbackOnMessage(context);
  }
}
