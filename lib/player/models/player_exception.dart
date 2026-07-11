import 'player_error_type.dart';

/// 播放器异常
class PlayerException implements Exception {
  final String message;

  final Object? error;

  final StackTrace? stackTrace;

  final PlayerErrorType type;

  PlayerException({
    required this.message,
    required this.type,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    return '[${type.name}] $message';
  }
}
