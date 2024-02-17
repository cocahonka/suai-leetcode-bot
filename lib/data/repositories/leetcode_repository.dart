import 'package:http/http.dart' as http;
import 'package:suai_leetcode_bot/data/api/leetcode_api.dart';

final class HttpLeetCodeRepository {
  const HttpLeetCodeRepository({
    required this.api,
    required this.client,
  });

  final LeetCodeApi api;
  final http.Client client;

  Future<bool> isUserExist(String nickname) async {
    final response = await client.get(api.user(nickname));
    return switch (response.statusCode) {
      200 => true,
      404 => false,
      final unknownCode => throw UnknownCodeException(unknownCode, response),
    };
  }
}
