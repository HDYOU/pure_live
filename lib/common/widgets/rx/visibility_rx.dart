import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/modules/util/listen_list_util.dart';

class VisibilityRx<T extends RxBool> extends StatefulWidget {
  const VisibilityRx({
    super.key,
    required this.rxValue,
    required this.child,
    this.reverse = false,
  });

  final T rxValue;
  final Widget child;

  /// 反转
  final bool reverse;

  @override
  State<StatefulWidget> createState() {
    return VisibilityRxState();
  }
}

class VisibilityRxState extends State<VisibilityRx> {
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
    return Visibility(visible: widget.reverse ? !widget.rxValue.value : widget.rxValue.value, child: widget.child);
  }
}
