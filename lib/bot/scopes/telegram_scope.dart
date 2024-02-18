import 'dart:async';

import 'package:suai_leetcode_bot/bot/repositories/telegram_state_repository.dart';
import 'package:televerse/televerse.dart';

abstract base class TelegramScope<State> {
  const TelegramScope({required this.repository});

  abstract final String identificator;
  final TelegramStateRepository<State> repository;

  bool predicate(Context<Session> context);
  FutureOr<void> callbackOnMessage(Context<Session> context);

  RegExp get queryPattern => RegExp('^${identificator}_([a-zA-Z1-9_-]+)\$');
  String generateQueryData<Value extends Enum>(Value value) => '${identificator}_${value.name}';
  FutureOr<void> callbackOnQuery(Context<Session> context);
}
