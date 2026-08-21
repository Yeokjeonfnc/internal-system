// 전자결재 Web iframe — postMessage·dispose·포인터 게이트 공통 처리.

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'package:app_flutter/core/web/iframe_pointer_gate.dart';

/// iframe ↔ Flutter postMessage 페이로드 파싱.
Map<dynamic, dynamic>? parseEapIframeMessage(dynamic raw) {
  if (raw is Map) return raw;
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded;
    } catch (_) {}
  }
  return null;
}

/// WebGL context lost 완화 — dispose 전 iframe 비우기.
void retireEapIframe(html.IFrameElement? iframe) {
  if (iframe == null) return;
  try {
    iframe.style.visibility = 'hidden';
    iframe.style.pointerEvents = 'none';
    iframe.src = 'about:blank';
  } catch (_) {}
}

html.IFrameElement createEapIframe(String src) {
  return html.IFrameElement()
    ..src = src
    ..style.border = 'none'
    ..style.width = '100%'
    ..style.height = '100%';
}

String registerEapIframeView(String prefix, html.IFrameElement iframe) {
  final viewType = '$prefix-${identityHashCode(iframe)}-${DateTime.now().microsecondsSinceEpoch}';
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => iframe,
  );
  return viewType;
}

/// iframe 으로 메시지를 보낸다. **아직 띄울 준비가 안 된 iframe 이면 조용히 건너뛴다.**
///
/// 왜 방어가 필요한가 — 전자결재 "회색 화면" 의 실제 원인이 여기였다.
///
/// 호스트 위젯의 `initState` 는 iframe 을 만들자마자 컨트롤러에 붙이는데
/// ([EapFormFillController.attach] 등), 그 시점에 이미 담아 둔 본문이 있으면
/// 곧바로 이 함수를 호출한다. 그런데 그 iframe 은 **아직 DOM 에 붙기 전**이라
/// `contentWindow` 가 없다.
///
/// `dart:html` 은 `contentWindow` 를 non-nullable 로 선언해 놓아서 `?.` 를 써도
/// 막히지 않는다. 실제로는 내부가 빈 래퍼가 돌아오고, 거기에 `postMessage` 를
/// 부르는 순간 터진다:
///   `TypeError: Cannot read properties of null (reading 'postMessage')`
///   → Flutter 는 이를 "Null check operator used on a null value" 로 보고한다.
///
/// 그 예외가 `initState` 에서 나므로 본문 영역 위젯 트리 전체가 ErrorWidget 으로
/// 바뀌고, **릴리즈 빌드의 ErrorWidget 은 아무 글자 없는 회색 사각형**이다.
/// 그래서 사용자에게는 "서식을 고르면 본문이 회색으로 변한다" 로 보였다.
/// (서식을 고르기 전에는 담아 둔 본문이 없어 이 경로를 타지 않는다 — 증상이
///  "서식 사용/수정할 때만" 나타난 이유다.)
///
/// 여기서 건너뛴 메시지는 유실되지 않는다. 각 호스트가 `iframe.onLoad` 에서
/// 본문을 다시 보내므로, 로드가 끝난 뒤 정상적으로 전달된다.
void postEapIframeMessage(html.IFrameElement? iframe, Map<String, dynamic> payload) {
  if (iframe == null) return;
  // DOM 에 붙기 전에는 보낼 대상 자체가 없다.
  if (iframe.isConnected != true) return;
  try {
    iframe.contentWindow?.postMessage(jsonEncode(payload), '*');
  } catch (_) {
    // 로드 직전·직후의 짧은 구간에서는 contentWindow 가 비어 있을 수 있다.
    // onLoad 에서 다시 보내므로 여기서 삼켜도 내용이 사라지지 않는다.
  }
}

void syncEapIframePointerEvents(html.IFrameElement? iframe, {required bool alive}) {
  if (!alive) return;
  final block = IframePointerGate.blocked.value > 0;
  iframe?.style.pointerEvents = block ? 'none' : 'auto';
}

/// iframe 내부 wheel → 부모 Scrollable 로 전달 (기안 본문 스크롤).
void forwardEapIframeWheel(
  BuildContext context, {
  required bool alive,
  required bool mounted,
  required double deltaY,
}) {
  if (!alive || !mounted || deltaY == 0) return;
  if (IframePointerGate.blocked.value > 0) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!alive || !mounted) return;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;
    final pos = scrollable.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;
    final next = (pos.pixels + deltaY).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if (next == pos.pixels) return;
    pos.jumpTo(next);
  });
}

Widget buildEapIframeView(String viewType, {double? height}) {
  final view = RepaintBoundary(child: HtmlElementView(viewType: viewType));
  if (height == null) return SizedBox.expand(child: view);
  return SizedBox(height: height, width: double.infinity, child: view);
}

/// 포인터 게이트 리스너 등록·해제 헬퍼.
mixin EapIframePointerGateMixin<T extends StatefulWidget> on State<T> {
  html.IFrameElement? get iframeForPointerGate;
  bool get iframeHostAlive;

  void bindEapIframePointerGate() {
    IframePointerGate.blocked.addListener(refreshEapIframePointerGate);
    refreshEapIframePointerGate();
  }

  void unbindEapIframePointerGate() {
    IframePointerGate.blocked.removeListener(refreshEapIframePointerGate);
  }

  void refreshEapIframePointerGate() {
    syncEapIframePointerEvents(iframeForPointerGate, alive: iframeHostAlive);
  }
}
