abstract base class TelegramStateRepository<State> {
  const TelegramStateRepository({required this.initialState});

  final State initialState;

  State getState({required int chatId});
  void setState({required int chatId, required State state});
}
