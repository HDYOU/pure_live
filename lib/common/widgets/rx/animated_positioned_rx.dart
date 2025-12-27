import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/modules/util/listen_list_util.dart';

typedef GetNumberFunc = double? Function();

double? defaultGetNumberFunc() => null;

class AnimatedPositionedRx<T extends RxBool> extends StatefulWidget {
  const AnimatedPositionedRx({
    super.key,
    required this.rxValue,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.left = defaultGetNumberFunc,
    this.top = defaultGetNumberFunc,
    this.right = defaultGetNumberFunc,
    this.bottom = defaultGetNumberFunc,
    this.height = defaultGetNumberFunc,
  });

  final T rxValue;
  final Widget child;
  final Duration duration;

  final GetNumberFunc left;
  final GetNumberFunc top;
  final GetNumberFunc right;
  final GetNumberFunc bottom;
  final GetNumberFunc height;

  @override
  State<StatefulWidget> createState() {
    return AnimatedPositionedRxState();
  }
}

class AnimatedPositionedRxState extends State<AnimatedPositionedRx> {
  final list = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    list.add(widget.rxValue.listen((e) {
      setState(() {});
    }));
  }

  @override
  void dispose() {
    super.dispose();
    ListenListUtil.clearStreamSubscriptionList(list);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      top: widget.top(),
      bottom: widget.bottom(),
      left: widget.left(),
      right: widget.right(),
      height: widget.height(),
      duration: widget.duration,
      child: widget.child,
    );
  }
}
