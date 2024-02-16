import 'dart:async';

import 'package:drift/drift.dart';
import 'package:suai_leetcode_bot/bot/scopes/register/register_state.dart';
import 'package:suai_leetcode_bot/bot/scopes/telegram_scope.dart';
import 'package:suai_leetcode_bot/database/database.dart';
import 'package:televerse/televerse.dart';

// TODO(cocahonka): Refactor.
final class RegisterScope extends TelegramScope<RegisterState> {
  RegisterScope({
    required AppDatabase database,
    required super.repository,
  }) : _database = database;

  final AppDatabase _database;

  @override
  String get name => 'Register scope';

  @override
  bool predicate(Context<Session> context) {
    final chatId = context.chat?.id;
    final message = context.message;

    if (chatId == null || message == null) return false;

    final state = repository.getState(chatId: chatId);
    return state is! RegisterCompleted;
  }

  @override
  FutureOr<void> callback(Context<Session> context) async {
    final chatId = context.chat!.id;
    final state = repository.getState(chatId: chatId);
    switch (state) {
      case RegisterInitial():
        await _requestName(context, chatId);
      case RegisterWaitingForName():
        await _takeName(context, chatId);
      case RegisterWaitingForGroupNumber(name: final name):
        await _takeGroupNumber(context, chatId, name);
      case RegisterWaitingForLeetCodeNickname(name: final name, groupNumber: final groupNumber):
        await _takeLeetCodeNickname(context, chatId, name, groupNumber);
      case RegisterCompleted():
    }
  }

  Future<void> _requestName(Context<Session> context, int chatId) async {
    await context.reply('Введите ваше реальное имя');

    repository.setState(chatId: chatId, state: const RegisterWaitingForName());
  }

  Future<void> _takeName(Context<Session> context, int chatId) async {
    final enteredName = context.message!.text?.trim();
    final validateRegex = RegExp(r'^[а-яА-ЯёЁ]{2,32}$');

    if (enteredName == null || !validateRegex.hasMatch(enteredName)) {
      await context.reply('Имя должно быть без пробелов и на русском языке, введите еще раз');
      return;
    }

    await _requestGroupNumber(context, chatId, enteredName);
  }

  Future<void> _requestGroupNumber(Context<Session> context, int chatId, String name) async {
    await context.reply('Введите номер группы');

    repository.setState(chatId: chatId, state: RegisterWaitingForGroupNumber(name: name));
  }

  Future<void> _takeGroupNumber(Context<Session> context, int chatId, String name) async {
    final enteredGroupNumber = context.message!.text?.trim();

    // TODO(cocahonka): Validate group number.
    if (enteredGroupNumber == null) {
      await context.reply('Неверный номер группы');
      return;
    }

    await _requestLeetCodeNickname(context, chatId, name, enteredGroupNumber);
  }

  Future<void> _requestLeetCodeNickname(Context<Session> context, int chatId, String name, String groupNumber) async {
    await context.reply('Введите никнейм литкода');

    repository.setState(
      chatId: chatId,
      state: RegisterWaitingForLeetCodeNickname(
        name: name,
        groupNumber: groupNumber,
      ),
    );
  }

  Future<void> _takeLeetCodeNickname(Context<Session> context, int chatId, String name, String groupNumber) async {
    final enteredLeetCodeNickname = context.message!.text?.trim();

    // TODO(cocahonka): Validate leetcode nickname.
    if (enteredLeetCodeNickname == null) {
      await context.reply('Неверный никнейм');
      return;
    }

    await _createUser(chatId, name, groupNumber, enteredLeetCodeNickname);
  }

  Future<void> _createUser(int chatId, String name, String groupNumber, String leetCodeNickname) async {
    await _database.transaction<void>(() async {
      final userId = await _database.into(_database.users).insert(
            UsersCompanion.insert(
              telegramId: chatId,
              name: Value(name),
              groupNumber: Value(groupNumber),
            ),
          );
      await _database.into(_database.leetCodeAccounts).insert(
            LeetCodeAccountsCompanion.insert(
              user: userId,
              nickname: leetCodeNickname,
            ),
          );
    });

    repository.setState(chatId: chatId, state: const RegisterCompleted());
  }
}
