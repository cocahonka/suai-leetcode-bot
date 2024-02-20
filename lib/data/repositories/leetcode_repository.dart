import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:suai_leetcode_bot/data/api/leetcode_api.dart';
import 'package:suai_leetcode_bot/service/logger_service.dart';

final class HttpLeetCodeRepository {
  const HttpLeetCodeRepository({
    required LeetCodeApi api,
    required http.Client client,
  })  : _api = api,
        _client = client;

  final LeetCodeApi _api;
  final http.Client _client;

  Future<bool?> isUserExist(String nickname) async {
    try {
      final response = await _client.get(_api.user(nickname));
      return switch (response.statusCode) {
        200 => true,
        404 => false,
        final unknownCode => throw UnknownCodeException(unknownCode, response),
      };
    } on UnknownCodeException catch (e, s) {
      LoggerService().writeError(e, s);
      return null;
    }
  }

  Future<List<({String slug, int timestamp})>?> getRecentUserSubmission(String nickname, [int limit = 10]) async {
    final data = {
      'query': r'''
    query recentAcSubmissions($username: String!, $limit: Int!) {
        recentAcSubmissionList(username: $username, limit: $limit) {
            id
            title
            titleSlug
            timestamp
        }
    }
    ''',
      'variables': {'username': nickname, 'limit': limit},
    };

    try {
      final response = await _client.post(
        _api.userSubmissions(),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        throw StateError('Error ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json case {'data': {'recentAcSubmissionList': final List<dynamic> recentAcSubmissionList}}) {
        final result = recentAcSubmissionList.map((entry) {
          final map = entry as Map<String, dynamic>;
          return (
            slug: map['titleSlug'] as String,
            timestamp: int.parse(map['timestamp'] as String),
          );
        });

        return result.toList();
      } else {
        throw FormatException('Leetcode graphql dont match the format ($json)');
      }
    } on Exception catch (e, s) {
      LoggerService().writeError(e, s);
      return null;
    }
  }
}
