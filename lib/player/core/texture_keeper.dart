/// Texture 保活管理器
/// 用于判断是否需要重建 Texture，避免不必要的重建
class TextureKeeper {
  /// 判断是否需要重建 Texture
  /// [engineChanged] 引擎是否发生变化
  /// [textureInvalid] Texture 是否失效
  static bool shouldRebuildTexture({required bool engineChanged, required bool textureInvalid}) {
    return engineChanged || textureInvalid;
  }
}
