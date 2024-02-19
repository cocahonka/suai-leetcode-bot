import 'dart:async';

import 'package:suai_leetcode_bot/data/database/database.dart';
import 'package:suai_leetcode_bot/data/repositories/leetcode_repository.dart';

final class LeetCodeService {
  const LeetCodeService({
    required int leetCodeUpdateIntervalInSeconds,
    required AppDatabase database,
    required HttpLeetCodeRepository leetCodeRepository,
  })  : _leetCodeUpdateIntervalInSeconds = leetCodeUpdateIntervalInSeconds,
        _leetCodeRepository = leetCodeRepository,
        _database = database;

  final int _leetCodeUpdateIntervalInSeconds;
  final AppDatabase _database;
  final HttpLeetCodeRepository _leetCodeRepository;

  void start() {
    Timer.periodic(Duration(seconds: _leetCodeUpdateIntervalInSeconds), (timer) async {
      final accounts = await _database.activeLeetCodeAccounts;
      for (final account in accounts) {
        final submissions = await _leetCodeRepository.getRecentUserSubmission(account.nickname);
        if (submissions != null) {
          await _database.updateUserSubmissions(userId: account.user, submissions: submissions);
        }
        await Future<void>.delayed(Duration.zero); // hack
      }
    });
  }
}
