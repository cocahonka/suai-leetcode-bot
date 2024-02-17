import 'package:http/http.dart' as http;

final class LeetCodeApi {
  const LeetCodeApi();

  static const String _apiBaseUrl = 'leetcode.com';
  static const String _grapqlPath = '/graphql';

  Uri user(String nickname) {
    return Uri(
      scheme: 'https',
      host: _apiBaseUrl,
      path: '/$nickname/',
    );
  }
}

sealed class LeetCodeApiException implements Exception {
  const LeetCodeApiException(this.message);
  final String message;
}

class UnknownCodeException extends LeetCodeApiException {
  const UnknownCodeException(this.statusCode, this.response) : super('Unknow code $statusCode');

  final int statusCode;
  final http.Response response;
}
