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

  final FutureOr<void> Function(Context context)? onStateComplete;
  FutureOr<void> executeInitialStatePoint(Context context) {}

  RegExp get commands;
  FutureOr<void> callbackOnCommand(Context context);

  bool predicate(Context context);
  FutureOr<void> callbackOnMessage(Context context);

  RegExp get queryPattern => RegExp('^${identificator}_' r'(\w+)');

  FutureOr<void> callbackOnQuery(Context context);
}
