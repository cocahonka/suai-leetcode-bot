import 'package:meta/meta.dart';

@immutable
class Config {
  const Config({
    required this.telegramToken,
    required this.leetCodeUpdateIntervalMs,
    required this.registerMessages,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'telegramToken': final String telegramToken,
        'leetCodeUpdateIntervalMs': final int leetCodeUpdateIntervalMs,
        'messages': {
          'register': {
            'requestName': final String requestName,
            'invalidName': final String invalidName,
            'requestGroupNumber': final String requestGroupNumber,
            'invalidGroupNumber': final String invalidGroupNumber,
            'requestLeetCodeNickname': final String requestLeetCodeNickname,
            'invalidLeetCodeNickname': final String invalidLeetCodeNickname,
            'leetCodeNicknameIsAlreadyTaken': final String leetCodeNicknameIsAlreadyTaken,
            'leetCodeNicknameNotExist': final String leetCodeNicknameNotExist,
            'successfulRegistration': final String successfulRegistration,
            'restartRegistration': final String restartRegistration,
          },
        },
      } =>
        Config(
          telegramToken: telegramToken,
          leetCodeUpdateIntervalMs: leetCodeUpdateIntervalMs,
          registerMessages: RegisterMessages(
            requestName: requestName,
            invalidName: invalidName,
            requestGroupNumber: requestGroupNumber,
            invalidGroupNumber: invalidGroupNumber,
            requestLeetCodeNickname: requestLeetCodeNickname,
            invalidLeetCodeNickname: invalidLeetCodeNickname,
            leetCodeNicknameIsAlreadyTaken: leetCodeNicknameIsAlreadyTaken,
            leetCodeNicknameNotExist: leetCodeNicknameNotExist,
            successfulRegistration: successfulRegistration,
            restartRegistration: restartRegistration,
          ),
        ),
      _ => throw const FormatException('The configuration file does not match the template')
    };
  }

  final String telegramToken;
  final int leetCodeUpdateIntervalMs;
  final RegisterMessages registerMessages;
}

sealed class Messages {
  const Messages();
}

class RegisterMessages extends Messages {
  const RegisterMessages({
    required this.requestName,
    required this.invalidName,
    required this.requestGroupNumber,
    required this.invalidGroupNumber,
    required this.requestLeetCodeNickname,
    required this.invalidLeetCodeNickname,
    required this.leetCodeNicknameIsAlreadyTaken,
    required this.leetCodeNicknameNotExist,
    required this.successfulRegistration,
    required this.restartRegistration,
  });

  final String requestName;
  final String invalidName;
  final String requestGroupNumber;
  final String invalidGroupNumber;
  final String requestLeetCodeNickname;
  final String invalidLeetCodeNickname;
  final String leetCodeNicknameIsAlreadyTaken;
  final String leetCodeNicknameNotExist;
  final String successfulRegistration;
  final String restartRegistration;
}
