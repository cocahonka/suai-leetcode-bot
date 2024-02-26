import 'package:meta/meta.dart';

@immutable
class Config {
  const Config({
    required this.telegramToken,
    required this.leetCodeUpdateIntervalInSeconds,
    required this.registerMessages,
    required this.userMessages,
    required this.adminMessages,
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
            'leetCodeNicknameGetError': final String leetCodeNicknameGetError,
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
          },
          'admin': {
            'exportRating': final String exportRating,
            'exportRatingFilename': final String exportRatingFilename,
            'exportRatingSaveFail': final String exportRatingSaveFail,
            'exportRatingUnknownUsername': final String exportRatingUnknownUsername,
            'exportCategories': final String exportCategories,
            'exportCategoriesFilename': final String exportCategoriesFilename,
            'crudCategories': final String crudCategories,
            'crudCancel': final String crudCancel,
            'crudInvalidMimeType': final String crudInvalidMimeType,
            'crudFileDownloadError': final String crudFileDownloadError,
            'crudFileFormatError': final String crudFileFormatError,
            'crudDatabaseUnknownError': final String crudDatabaseUnknownError,
            'crudSuccessful': final String crudSuccessful,
            'crudHelpMessage': final String crudHelpMessage,
            'exit': final String exit,
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
            leetCodeNicknameGetError: leetCodeNicknameGetError,
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
          adminMessages: AdminMessages(
            exportRating: exportRating,
            exportRatingFilename: exportRatingFilename,
            exportRatingSaveFail: exportRatingSaveFail,
            exportRatingUnknownUsername: exportRatingUnknownUsername,
            exportCategories: exportCategories,
            exportCategoriesFilename: exportCategoriesFilename,
            crudCategories: crudCategories,
            crudCancel: crudCancel,
            crudInvalidMimeType: crudInvalidMimeType,
            crudFileDownloadError: crudFileDownloadError,
            crudFileFormatError: crudFileFormatError,
            crudDatabaseUnknownError: crudDatabaseUnknownError,
            crudSuccessful: crudSuccessful,
            crudHelpMessage: crudHelpMessage,
            exit: exit,
          ),
        ),
      _ => throw const FormatException('The configuration file does not match the template')
    };
  }

  final String telegramToken;
  final int leetCodeUpdateIntervalInSeconds;
  final RegisterMessages registerMessages;
  final UserMessages userMessages;
  final AdminMessages adminMessages;
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
    required this.leetCodeNicknameGetError,
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
  final String leetCodeNicknameGetError;
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

class AdminMessages extends Messages {
  AdminMessages({
    required this.exportRating,
    required this.exportRatingFilename,
    required this.exportRatingSaveFail,
    required this.exportRatingUnknownUsername,
    required this.exportCategories,
    required this.exportCategoriesFilename,
    required this.crudCategories,
    required this.crudCancel,
    required this.crudInvalidMimeType,
    required this.crudFileDownloadError,
    required this.crudFileFormatError,
    required this.crudDatabaseUnknownError,
    required this.crudSuccessful,
    required this.crudHelpMessage,
    required this.exit,
  });

  final String exportRating;
  final String exportRatingFilename;
  final String exportRatingSaveFail;
  final String exportRatingUnknownUsername;
  final String exportCategories;
  final String exportCategoriesFilename;
  final String crudCategories;
  final String crudCancel;
  final String crudInvalidMimeType;
  final String crudFileDownloadError;
  final String crudFileFormatError;
  final String crudDatabaseUnknownError;
  final String crudSuccessful;
  final String crudHelpMessage;
  final String exit;
}
