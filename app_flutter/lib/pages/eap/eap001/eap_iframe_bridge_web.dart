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

void postEapIframeMessage(html.IFrameElement? iframe, Map<String, dynamic> payload) {
  iframe?.contentWindow?.postMessage(jsonEncode(payload), '*');
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
