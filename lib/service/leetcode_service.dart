import 'dart:async';

import 'package:suai_leetcode_bot/data/database/database.dart';
import 'package:suai_leetcode_bot/data/repositories/leetcode_repository.dart';

final class LeetCodeService {
  const LeetCodeService({
    required int leetCodeUpdateIntervalInSeconds,
    required int leetCodeBatchRequestSize,
    required int leetCodeUpdateCoolingTimeInSeconds,
    required AppDatabase database,
    required HttpLeetCodeRepository leetCodeRepository,
  })  : _leetCodeUpdateIntervalInSeconds = leetCodeUpdateIntervalInSeconds,
        _leetCodeBatchRequestSize = leetCodeBatchRequestSize,
        _leetCodeUpdateCoolingTimeInSeconds = leetCodeUpdateCoolingTimeInSeconds,
        _leetCodeRepository = leetCodeRepository,
        _database = database;

  static final StreamController<DateTime> _nextTimerRunStreamController = StreamController.broadcast();
  static Stream<DateTime> get nextTimerRun => _nextTimerRunStreamController.stream;

  final int _leetCodeBatchRequestSize;
  final int _leetCodeUpdateIntervalInSeconds;
  final int _leetCodeUpdateCoolingTimeInSeconds;
  final AppDatabase _database;
  final HttpLeetCodeRepository _leetCodeRepository;

  void start() {
    final updateDuration = Duration(seconds: _leetCodeUpdateIntervalInSeconds + _leetCodeUpdateCoolingTimeInSeconds);

    Timer.periodic(updateDuration, (timer) {
      _nextTimerRunStreamController.add(DateTime.now().add(updateDuration));
      _updateAccountsPeriodically();
    });
  }

  Future<void> _updateAccountsPeriodically() async {
    final accounts = await _database.activeLeetCodeAccounts;
    final totalBatches = (accounts.length / _leetCodeBatchRequestSize).ceil();
    final delayBetweenBatches = _leetCodeUpdateIntervalInSeconds ~/ totalBatches;

    for (var i = 0; i < accounts.length; i += _leetCodeBatchRequestSize) {
      final batch = accounts.skip(i).take(_leetCodeBatchRequestSize);
      await _updateBatch(batch.toList());
      if (i + _leetCodeBatchRequestSize < accounts.length) {
        await Future<void>.delayed(Duration(seconds: delayBetweenBatches));
      }
    }
  }

  Future<void> _updateBatch(List<LeetCodeAccount> accounts) async {
    for (final account in accounts) {
      final submissions = await _leetCodeRepository.getRecentUserSubmission(account.nickname);
      if (submissions != null) {
        await _database.updateUserSubmissions(userId: account.user, submissions: submissions);
      }
    }
  }
}
