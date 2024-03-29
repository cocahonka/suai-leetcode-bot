import 'dart:async';

import 'package:suai_leetcode_bot/bot/repositories/telegram_state_repository.dart';
import 'package:televerse/televerse.dart';

abstract base class TelegramScope<State> {
  const TelegramScope({
    required this.repository,
    this.onStateComplete,
  });

  abstract final String identificator;
  final TelegramStateRepository<State> repository;

  final FutureOr<void> Function(Context<Session> context)? onStateComplete;
  FutureOr<void> executeInitialStatePoint(Context<Session> context) {}

  RegExp get commands;
  FutureOr<void> callbackOnCommand(Context<Session> context);

  bool predicate(Context<Session> context);
  FutureOr<void> callbackOnMessage(Context<Session> context);

  RegExp get queryPattern => RegExp('^${identificator}_' r'(\w+)');

  FutureOr<void> callbackOnQuery(Context<Session> context);
}
