sealed class RegisterState {
  const RegisterState();
}

class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

class RegisterWaitingForName extends RegisterState {
  const RegisterWaitingForName();
}

class RegisterWaitingForGroupNumber extends RegisterState {
  const RegisterWaitingForGroupNumber({required this.name});

  final String name;
}

class RegisterWaitingForLeetCodeNickname extends RegisterState {
  const RegisterWaitingForLeetCodeNickname({
    required this.name,
    required this.groupNumber,
  });

  final String name;
  final String groupNumber;
}

class RegisterCompleted extends RegisterState {
  const RegisterCompleted({
    required this.name,
    required this.groupNumber,
    required this.leetCodeNickname,
  });

  final String name;
  final String groupNumber;
  final String leetCodeNickname;
}
