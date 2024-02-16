import 'dart:async';

import 'package:suai_leetcode_bot/bot/repositories/telegram_state_repository.dart';
import 'package:televerse/televerse.dart';

abstract base class TelegramScope<State> {
  const TelegramScope({required this.repository});

  abstract final String name;
  final TelegramStateRepository<State> repository;

  bool predicate(Context<Session> context);

  FutureOr<void> callback(Context<Session> context);
}
