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
