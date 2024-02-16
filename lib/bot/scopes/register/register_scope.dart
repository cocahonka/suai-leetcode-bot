import 'dart:async';

import 'package:drift/drift.dart';
import 'package:suai_leetcode_bot/bot/scopes/register/register_state.dart';
import 'package:suai_leetcode_bot/bot/scopes/telegram_scope.dart';
import 'package:suai_leetcode_bot/database/database.dart';
import 'package:televerse/televerse.dart';

final class RegisterScope extends TelegramScope<RegisterState> {
  RegisterScope({
    required AppDatabase database,
    required super.repository,
  }) : _database = database;

  final AppDatabase _database;

  @override
  String get debugName => 'Register scope';

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

    await switch (state) {
      RegisterInitial() => _requestName(context, chatId, state),
      RegisterWaitingForName() => _takeName(context, chatId, state),
      RegisterWaitingForGroupNumber() => _takeGroupNumber(context, chatId, state),
      RegisterWaitingForLeetCodeNickname() => _takeLeetCodeNickname(context, chatId, state),
      RegisterCompleted() => Future<void>.value(),
    };
  }

  Future<void> _requestName(
    Context<Session> context,
    int chatId,
    RegisterInitial state,
  ) async {
    await context.reply('Введите ваше реальное имя');

    repository.setState(
      chatId: chatId,
      state: const RegisterWaitingForName(),
    );
  }

  Future<void> _takeName(
    Context<Session> context,
    int chatId,
    RegisterWaitingForName state,
  ) async {
    final name = context.message!.text?.trim();
    final validateRegex = RegExp(r'^[а-яА-ЯёЁ]{2,32}$');

    if (name == null || !validateRegex.hasMatch(name)) {
      await context.reply('Имя должно быть без пробелов и на русском языке, введите еще раз');
      return;
    }

    await context.reply('Введите номер группы');

    repository.setState(
      chatId: chatId,
      state: RegisterWaitingForGroupNumber(name: name),
    );
  }

  Future<void> _takeGroupNumber(
    Context<Session> context,
    int chatId,
    RegisterWaitingForGroupNumber state,
  ) async {
    final groupNumber = context.message!.text?.trim();

    // TODO(cocahonka): Validate group number.
    if (groupNumber == null) {
      await context.reply('Неверный номер группы');
      return;
    }

    await context.reply('Введите никнейм литкода');

    repository.setState(
      chatId: chatId,
      state: RegisterWaitingForLeetCodeNickname(name: state.name, groupNumber: groupNumber),
    );
  }

  Future<void> _takeLeetCodeNickname(
    Context<Session> context,
    int chatId,
    RegisterWaitingForLeetCodeNickname state,
  ) async {
    final leetCodeNickname = context.message!.text?.trim();

    // TODO(cocahonka): Validate leetcode nickname.
    if (leetCodeNickname == null) {
      await context.reply('Неверный никнейм');
      return;
    }

    await _createUser(chatId, state, leetCodeNickname);
  }

  Future<void> _createUser(
    int chatId,
    RegisterWaitingForLeetCodeNickname state,
    String leetCodeNickname,
  ) async {
    await _database.transaction<void>(() async {
      final userId = await _database.into(_database.users).insert(
            UsersCompanion.insert(
              telegramId: chatId,
              name: Value(state.name),
              groupNumber: Value(state.groupNumber),
            ),
          );
      await _database.into(_database.leetCodeAccounts).insert(
            LeetCodeAccountsCompanion.insert(
              user: userId,
              nickname: leetCodeNickname,
            ),
          );
    });

    repository.setState(
      chatId: chatId,
      state: const RegisterCompleted(),
    );
  }
}
