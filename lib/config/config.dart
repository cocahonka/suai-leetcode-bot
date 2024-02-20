import 'package:meta/meta.dart';

@immutable
class Config {
  const Config({
    required this.telegramToken,
    required this.leetCodeUpdateIntervalInSeconds,
    required this.registerMessages,
    required this.userMessages,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'telegramToken': final String telegramToken,
        'leetCodeUpdateIntervalInSeconds': final int leetCodeUpdateIntervalInSeconds,
        'messages': {
          'register': {
            'onStart': final String onStart,
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
          'user': {
            'chooseMenuItem': final String chooseMenuItem,
            'aboutClubCaption': final String aboutClubCaption,
            'aboutClubLink': final String aboutClubLink,
            'olympiadsCaption': final String olympiadsCaption,
            'olympiadsLink': final String olympiadsLink,
            'joinClubCaption': final String joinClubCaption,
            'joinClubLink': final String joinClubLink,
            'categoryListCaption': final String categoryListCaption,
            'backToMenu': final String backToMenu,
            'backToCategories': final String backToCategories,
            'chooseCategory': final String chooseCategory,
            'taskLinkCaption': final String taskLinkCaption,
            'howItWorks': final String howItWorks,
          }
        },
      } =>
        Config(
          telegramToken: telegramToken,
          leetCodeUpdateIntervalInSeconds: leetCodeUpdateIntervalInSeconds,
          registerMessages: RegisterMessages(
            onStart: onStart,
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
          userMessages: UserMessages(
            chooseMenuItem: chooseMenuItem,
            aboutClubCaption: aboutClubCaption,
            aboutClubLink: aboutClubLink,
            olympiadsCaption: olympiadsCaption,
            olympiadsLink: olympiadsLink,
            joinClubCaption: joinClubCaption,
            joinClubLink: joinClubLink,
            categoryListCaption: categoryListCaption,
            backToMenu: backToMenu,
            backToCategories: backToCategories,
            chooseCategory: chooseCategory,
            taskLinkCaption: taskLinkCaption,
            howItWorks: howItWorks,
          ),
        ),
      _ => throw const FormatException('The configuration file does not match the template')
    };
  }

  final String telegramToken;
  final int leetCodeUpdateIntervalInSeconds;
  final RegisterMessages registerMessages;
  final UserMessages userMessages;
}

sealed class Messages {
  const Messages();
}

class RegisterMessages extends Messages {
  const RegisterMessages({
    required this.onStart,
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

  final String onStart;
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

class UserMessages extends Messages {
  const UserMessages({
    required this.chooseMenuItem,
    required this.aboutClubCaption,
    required this.aboutClubLink,
    required this.olympiadsCaption,
    required this.olympiadsLink,
    required this.joinClubCaption,
    required this.joinClubLink,
    required this.categoryListCaption,
    required this.backToMenu,
    required this.backToCategories,
    required this.chooseCategory,
    required this.taskLinkCaption,
    required this.howItWorks,
  });

  final String chooseMenuItem;
  final String aboutClubCaption;
  final String aboutClubLink;
  final String olympiadsCaption;
  final String olympiadsLink;
  final String joinClubCaption;
  final String joinClubLink;
  final String categoryListCaption;
  final String backToMenu;
  final String backToCategories;
  final String chooseCategory;
  final String taskLinkCaption;
  final String howItWorks;
}
