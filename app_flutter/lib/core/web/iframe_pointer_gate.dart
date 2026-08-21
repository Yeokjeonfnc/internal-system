// Web HtmlElementView(iframe)가 Flutter 모달 클릭을 가로채지 않도록 막는다.

import 'package:flutter/foundation.dart';

abstract final class IframePointerGate {
  static final ValueNotifier<int> blocked = ValueNotifier(0);

  static void push() => blocked.value++;

  static void pop() {
    if (blocked.value > 0) blocked.value--;
  }

  static Future<T> whileBlocked<T>(Future<T> Function() run) async {
    push();
    try {
      return await run();
    } finally {
      pop();
    }
  }
}
