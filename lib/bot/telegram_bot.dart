import 'dart:async';
import 'package:suai_leetcode_bot/config/config.dart';
import 'package:suai_leetcode_bot/database/database.dart';
import 'package:televerse/televerse.dart';

class TelegramBot {
  TelegramBot({
    required this.config,
    required AppDatabase database,
  })  : _bot = Bot(config.telegramToken),
        _database = database;

  final Config config;
  final AppDatabase _database;
  final Bot _bot;

  void start() {
    _bot.start(_onStart);
  }

  FutureOr<void> _onStart(Context<Session> ctx) async {
    await ctx.reply('Hello!');
  }
}
