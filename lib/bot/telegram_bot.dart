import 'dart:async';
import 'package:suai_leetcode_bot/bot/scopes/telegram_scope.dart';
import 'package:suai_leetcode_bot/config/config.dart';
import 'package:suai_leetcode_bot/database/database.dart';
import 'package:televerse/televerse.dart';

class TelegramBot {
  TelegramBot({
    required this.config,
    required AppDatabase database,
    required List<TelegramScope<dynamic>> scopes,
  })  : _bot = Bot(config.telegramToken),
        _database = database,
        _scopes = scopes;

  final Config config;
  final AppDatabase _database;
  final List<TelegramScope<dynamic>> _scopes;
  final Bot _bot;

  void start() {
    _bot.start(_onStart);

    for (final TelegramScope(:predicate, :callback, :debugName) in _scopes) {
      _bot.filter(predicate, callback, name: debugName);
    }
  }

  FutureOr<void> _onStart(Context ctx) async {
    await ctx.reply('Hello!');
  }
}
