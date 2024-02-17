import 'package:http/http.dart' as http;
import 'package:suai_leetcode_bot/data/api/leetcode_api.dart';

final class HttpLeetCodeRepository {
  const HttpLeetCodeRepository({
    required LeetCodeApi api,
    required http.Client client,
  })  : _api = api,
        _client = client;

  final LeetCodeApi _api;
  final http.Client _client;

  Future<bool> isUserExist(String nickname) async {
    final response = await _client.get(_api.user(nickname));
    return switch (response.statusCode) {
      200 => true,
      404 => false,
      final unknownCode => throw UnknownCodeException(unknownCode, response),
    };
  }
}
