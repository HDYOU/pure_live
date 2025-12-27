import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/modules/util/listen_list_util.dart';

class AnimatedOpacityRx<T extends RxBool> extends StatefulWidget {
  const AnimatedOpacityRx({
    super.key,
    required this.rxValue,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  final T rxValue;
  final Widget child;
  final Duration duration;

  @override
  State<StatefulWidget> createState() {
    return AnimatedOpacityRxState();
  }
}

class AnimatedOpacityRxState extends State<AnimatedOpacityRx> {
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
    return AnimatedOpacity(
      opacity: widget.rxValue.value ? 0.9 : 0.0,
      duration: widget.duration,
      child: widget.child,
    );
  }
}
