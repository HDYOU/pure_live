import 'dart:io';
import 'package:flutter/material.dart';

/// PIP 画中画窗口 Widget
/// 用于在桌面端 PIP 模式下包装视频内容
class PureLivePipWidget extends StatelessWidget {
  final Widget child;

  const PureLivePipWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 非桌面端直接返回子组件
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return child;
    }
    return Stack(
      children: [
        DragToResizeArea(
          child: Container(color: Colors.black, child: child),
        ),
      ],
    );
  }
}

/// 拖拽调整大小区域（桌面端 PIP 用）
class DragToResizeArea extends StatefulWidget {
  final Widget child;
  final double handleSize;

  const DragToResizeArea({
    super.key,
    required this.child,
    this.handleSize = 10,
  });

  @override
  State<DragToResizeArea> createState() => _DragToResizeAreaState();
}

class _DragToResizeAreaState extends State<DragToResizeArea> {
  @override
  Widget build(BuildContext context) {
    // 简单实现：直接返回 child，实际 PIP 大小由 window_manager 控制
    return widget.child;
  }
}
