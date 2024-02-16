import 'package:meta/meta.dart';

@immutable
class Config {
  const Config({
    required this.telegramToken,
    required this.leetCodeUpdateIntervalMs,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'telegramToken': final String telegramToken,
        'leetCodeUpdateIntervalMs': final int leetCodeUpdateIntervalMs,
      } =>
        Config(
          telegramToken: telegramToken,
          leetCodeUpdateIntervalMs: leetCodeUpdateIntervalMs,
        ),
      _ => throw const FormatException('The configuration file does not match the template')
    };
  }

  final String telegramToken;
  final int leetCodeUpdateIntervalMs;
}
