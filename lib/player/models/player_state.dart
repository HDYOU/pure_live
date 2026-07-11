/// 播放器状态枚举
enum PlayerState {
  idle,
  initializing,
  initialized,
  preparing,
  buffering,
  ready,
  playing,
  paused,
  completed,
  stopped,
  error,
  disposed,
}
