import 'package:suai_leetcode_bot/bot/repositories/telegram_state_repository.dart';

final class RuntimeRepository<State> extends TelegramStateRepository<State> {
  RuntimeRepository({required super.initialState});

  final Map<int, State> _states = {};

  @override
  State getState({required int chatId}) =>
      _states.putIfAbsent(chatId, () => super.initialState);

  @override
  void setState({required int chatId, required State state}) =>
      _states[chatId] = state;
}
