import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class StreamRxBuilder<T extends Rx> extends StatelessWidget {
  const StreamRxBuilder({super.key, required this.rxValue, required this.builder});

  final T rxValue;
  final AsyncWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: rxValue.stream,
      initialData: rxValue.value,
      builder: builder,
    );
  }
}

