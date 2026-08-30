// Web HtmlElementView(iframe)가 Flutter 모달 클릭을 가로채지 않도록 막는다.

import 'dart:async';

import 'package:flutter/widgets.dart';

abstract final class IframePointerGate {
  static final ValueNotifier<int> blocked = ValueNotifier(0);

  static void push() => blocked.value++;

  static void pop() {
    if (blocked.value > 0) blocked.value--;
  }

  /// iframe·브라우저 포커스가 Flutter 로 넘어온 직후 같은 프레임에
  /// Dialog/BottomSheet 를 띄우면 `_RenderTheater` 가 아직 레이아웃되지 않아
  /// focus traversal 이 assert 로 터질 수 있다.
  static Future<void> deferOverlayFrame({int frames = 1}) async {
    final binding = WidgetsBinding.instance;
    for (var i = 0; i < frames; i++) {
      final completer = Completer<void>();
      binding.addPostFrameCallback((_) {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
    }
  }

  /// iframe 클릭을 끈 뒤 Overlay 를 연다.
  ///
  /// [run] 안의 `showDialog` / `showModalBottomSheet` 는 **반드시
  /// `requestFocus: false`** 로 띄운다. iframe 이 DOM 포커스를 쥔 채로
  /// 다이얼로그가 포커스를 요청하면 Flutter 웹이 뷰 포커스를 되돌리며
  /// 아직 레이아웃되지 않은 Overlay(`_RenderTheater`) 의 size 를 읽어
  /// assert 가 터진다.
  static Future<T> whileBlocked<T>(
    BuildContext context,
    Future<T> Function() run,
  ) async {
    push();
    try {
      await deferOverlayFrame(frames: 2);
      // context 는 Overlay 를 열 수 있는 트리인지 호출 쪽이 넘기는 표식이다.
      if (!context.mounted) return await run();
      return await run();
    } finally {
      pop();
    }
  }
}
