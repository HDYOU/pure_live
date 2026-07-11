/// 线路降级管理器
/// 当某条播放线路失败时，自动切换到下一条可用线路
class LineFallbackManager {
  int _currentIndex = 0;
  final Set<String> _failedLines = {};

  /// 获取下一条线路
  /// [lines] 所有可用线路列表
  String next(List<String> lines) {
    if (lines.isEmpty) {
      throw Exception('No playable line');
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[_currentIndex];

      _currentIndex = (_currentIndex + 1) % lines.length;

      if (!_failedLines.contains(line)) {
        return line;
      }
    }
    throw Exception('All lines failed');
  }

  /// 标记某条线路失败
  void markFailed(String line) {
    _failedLines.add(line);
  }

  /// 标记某条线路成功（从失败列表中移除）
  void markSuccess(String line) {
    _failedLines.remove(line);
  }

  /// 重置线路状态
  void reset() {
    _currentIndex = 0;
    _failedLines.clear();
  }

  /// 检查是否还有可用线路
  bool hasAvailable(List<String> lines) {
    return lines.any((l) => !_failedLines.contains(l));
  }
}
