/// 播放器引擎类型枚举
/// 对应当前项目支持的播放器：
/// - mediaKit: media_kit (MPV)
/// - gsyExo: gsy_video_player (ExoPlayer)
/// - gsyIjk: gsy_video_player (IJKPlayer)
/// - fvp: fvp (基于 video_player 的硬件解码播放器)
/// - systemVideo: video_player + chewie (系统播放器)
enum PlayerEngine {
  mediaKit,
  gsyExo,
  gsyIjk,
  fvp,
  systemVideo,
}
