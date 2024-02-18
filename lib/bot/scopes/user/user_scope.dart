import 'dart:async';

import 'package:collection/collection.dart';
import 'package:suai_leetcode_bot/bot/scopes/telegram_scope.dart';
import 'package:suai_leetcode_bot/bot/scopes/user/user_query_event.dart';
import 'package:suai_leetcode_bot/bot/scopes/user/user_state.dart';
import 'package:suai_leetcode_bot/config/config.dart';
import 'package:suai_leetcode_bot/data/database/database.dart';
import 'package:televerse/televerse.dart';

final class UserScope extends TelegramScope<UserState> {
  UserScope({
    required AppDatabase database,
    required UserMessages messages,
    required super.repository,
  })  : _database = database,
        _messages = messages;

  final AppDatabase _database;
  final UserMessages _messages;

  @override
  String get identificator => 'user_scope';

  @override
  RegExp get commands => RegExp(r'^$');

  @override
  FutureOr<void> callbackOnCommand(Context<Session> context) async {}

  @override
  bool predicate(Context<Session> context) {
    final chatId = context.chat?.id;
    final message = context.message;

    if (chatId == null || message == null) return false;

    return true;
  }

  @override
  FutureOr<void> callbackOnMessage(Context<Session> context) async {
    await context.reply(
      'Выберите действие',
      replyMarkup: InlineKeyboard()
          .addUrl('О кружке', 'https://vk.com/cocahonka')
          .row()
          .addUrl('Олимпиады', 'https://vk.com/cocahonka')
          .row()
          .addUrl('Записаться', 'https://vk.com/cocahonka')
          .row()
          .add('Список категорий', generateQueryData(UserQueryEvent.showCategories))
          .row(),
    );
  }

  @override
  FutureOr<void> callbackOnQuery(Context<Session> context) async {
    final chatId = context.chat!.id;
    final queryData = context.callbackQuery!.data!;
    final queryEventIdentificator = queryPattern.firstMatch(queryData)!.group(1)!;
    final queryEvent = UserQueryEvent.values.firstWhereOrNull(
      (value) => value.name == queryEventIdentificator,
    );

    switch (queryEvent) {
      case UserQueryEvent.showCategories:
        return;
      case UserQueryEvent.showCategoryDetails:
        return;
      case null:
        throw StateError('Event ($queryEventIdentificator) not recognized');
    }
  }
}
