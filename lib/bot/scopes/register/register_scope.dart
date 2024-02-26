import 'dart:async';

import 'package:collection/collection.dart';
import 'package:suai_leetcode_bot/bot/scopes/register/register_query_event.dart';
import 'package:suai_leetcode_bot/bot/scopes/register/register_state.dart';
import 'package:suai_leetcode_bot/bot/scopes/telegram_scope.dart';
import 'package:suai_leetcode_bot/config/config.dart';
import 'package:suai_leetcode_bot/constants/group_numbers.dart';
import 'package:suai_leetcode_bot/data/database/database.dart';
import 'package:suai_leetcode_bot/data/repositories/leetcode_repository.dart';
import 'package:suai_leetcode_bot/extensions/int_extensions.dart';
import 'package:suai_leetcode_bot/extensions/string_extensions.dart';
import 'package:televerse/televerse.dart';

final class RegisterScope extends TelegramScope<RegisterState> {
  RegisterScope({
    required RegisterMessages messages,
    required AppDatabase database,
    required HttpLeetCodeRepository leetCodeRepository,
    required super.onStateComplete,
    required super.repository,
  })  : _messages = messages,
        _database = database,
        _leetCodeRepository = leetCodeRepository;

  final RegisterMessages _messages;
  final AppDatabase _database;
  final HttpLeetCodeRepository _leetCodeRepository;

  late final InlineKeyboard _restartKeyboard = InlineKeyboard()
      .add(
        _messages.restartRegistration,
        '${identificator}_${RegisterQueryEvent.restart.name}',
      )
      .row();

  @override
  String get identificator => 'register_scope';

  @override
  RegExp get commands => RegExp(r'^\/start$');

  @override
  FutureOr<void> callbackOnCommand(Context<Session> context) async {
    final chatId = context.chat!.id;
    final command = context.message!.text!;
    final state = repository.getState(chatId: chatId);

    if (RegExp('start').hasMatch(command)) {
      if (state case RegisterInitial()) {
        await context.reply(_messages.onStart);
      }
    }

    await callbackOnMessage(context);
  }

  @override
  bool predicate(Context<Session> context) {
    final chatId = context.chat?.id;
    final message = context.message;

    if (chatId == null || message == null) return false;

    final state = repository.getState(chatId: chatId);
    return state is! RegisterCompleted;
  }

  @override
  FutureOr<void> callbackOnMessage(Context<Session> context) async {
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

  @override
  FutureOr<void> callbackOnQuery(Context<Session> context) async {
    final chatId = context.chat!.id;
    final state = repository.getState(chatId: chatId);

    if (state is RegisterCompleted) return;

    final queryData = context.callbackQuery!.data!;
    final queryEventIdentificator = queryPattern.firstMatch(queryData)!.group(1)!;
    final queryEvent = RegisterQueryEvent.values.firstWhereOrNull(
      (value) => value.name == queryEventIdentificator,
    );

    switch (queryEvent) {
      case RegisterQueryEvent.restart:
        repository.setState(
          chatId: chatId,
          state: const RegisterInitial(),
        );
        await context.editMessageText(_messages.restartRegistration);
      case null:
    }

    await callbackOnMessage(context);
  }

  Future<void> _requestName(
    Context<Session> context,
    int chatId,
    RegisterInitial state,
  ) async {
    await context.reply(_messages.requestName);

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
    final name = context.message!.text?.trim().toLowerCase().eachCapitalize();
    final validateRegex = RegExp(r'^[а-яА-ЯёЁ]{2,32} [а-яА-ЯёЁ]{2,32}$');

    if (name == null || !validateRegex.hasMatch(name)) {
      await context.reply(_messages.invalidName);
      return;
    }

    await context.reply(_messages.requestGroupNumber, replyMarkup: _restartKeyboard);

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
    final groupNumber = context.message!.text?.trim().toUpperCase();

    if (groupNumber == null || !kGroupNumbers.contains(groupNumber)) {
      await context.reply(_messages.invalidGroupNumber, replyMarkup: _restartKeyboard);
      return;
    }

    await context.reply(_messages.requestLeetCodeNickname, replyMarkup: _restartKeyboard);

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

    if (leetCodeNickname == null || !leetCodeNickname.length.inRange(3, 32)) {
      await context.reply(_messages.invalidLeetCodeNickname, replyMarkup: _restartKeyboard);
      return;
    }

    final isLeetCodeNicknameAlreadyTaken = await _database.isLeetCodeNicknameAlreadyTaken(leetCodeNickname);

    if (isLeetCodeNicknameAlreadyTaken) {
      await context.reply(_messages.leetCodeNicknameIsAlreadyTaken, replyMarkup: _restartKeyboard);
      return;
    }

    final isLeetCodeNicknameExist = await _leetCodeRepository.isUserExist(leetCodeNickname);

    if (isLeetCodeNicknameExist == null) {
      await context.reply(_messages.leetCodeNicknameGetError, replyMarkup: _restartKeyboard);
      return;
    }

    if (!isLeetCodeNicknameExist) {
      await context.reply(_messages.leetCodeNicknameNotExist, replyMarkup: _restartKeyboard);
      return;
    }

    await _database.createUserWithLeetCodeAccount(
      telegramId: chatId,
      name: state.name,
      groupNumber: state.groupNumber,
      leetCodeNickname: leetCodeNickname,
    );
    await context.reply(_messages.successfulRegistration);

    repository.setState(chatId: chatId, state: const RegisterCompleted());

    onStateComplete?.call(context);
  }
}
