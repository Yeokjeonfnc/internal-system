// 전자결재 HTML 본문 편집기 — Web contenteditable (엑셀·표 붙여넣기 유지).

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'package:app_flutter/pages/eap/eap001/eap_iframe_bridge_web.dart';
import 'package:app_flutter/pages/eap/eap001/eap_web_assets.dart';

class EapHtmlEditorController {
  String _html = '';
  void Function(String html)? _set;
  Future<String> Function()? _get;

  void attach({
    required void Function(String html) setHtml,
    required Future<String> Function() getHtml,
  }) {
    _set = setHtml;
    _get = getHtml;
    if (_html.isNotEmpty) _set!(_html);
  }

  void detach() {
    _set = null;
    _get = null;
  }

  void setHtml(String html) {
    _html = html;
    _set?.call(html);
  }

  Future<String> getHtml() async {
    if (_get != null) {
      _html = await _get!();
    }
    return _html;
  }
}

class EapHtmlEditorHost extends StatefulWidget {
  const EapHtmlEditorHost({
    super.key,
    required this.controller,
    this.initialHtml = '',
    this.height,
    this.placeholder = '본문을 입력하세요.',
    this.editorPage = kEapHtmlEditorPage,
    this.editorMode = '',
  });

  final EapHtmlEditorController controller;
  final String initialHtml;
  final double? height;
  final String placeholder;
  final String editorPage;

  /// `compose` | `form` — 표 선택·크기 조절 UI 숨김.
  final String editorMode;

  @override
  State<EapHtmlEditorHost> createState() => _EapHtmlEditorHostWebState();
}

class _EapHtmlEditorHostWebState extends State<EapHtmlEditorHost>
    with EapIframePointerGateMixin {
  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _sub;
  StreamSubscription<html.Event>? _loadSub;
  int _req = 0;
  final Map<int, Completer<String>> _pending = {};
  var _alive = true;

  @override
  html.IFrameElement? get iframeForPointerGate => _iframe;

  @override
  bool get iframeHostAlive => _alive;

  @override
  void initState() {
    super.initState();
    final iframe = createEapIframe(
      eapWebAssetUrl(widget.editorPage, mode: widget.editorMode),
    );
    _iframe = iframe;
    _viewType = registerEapIframeView('eap-html-editor', iframe);
    _sub = html.window.onMessage.listen(_onMessage);
    _loadSub = iframe.onLoad.listen((_) {
      if (!_alive || !mounted) return;
      refreshEapIframePointerGate();
      postEapIframeMessage(_iframe, {
        'type': 'eapSetPlaceholder',
        'text': widget.placeholder,
      });
      final htmlText = widget.controller._html.isNotEmpty
          ? widget.controller._html
          : widget.initialHtml;
      if (htmlText.isNotEmpty) _postSetHtml(htmlText);
    });
    widget.controller.attach(setHtml: _postSetHtml, getHtml: _postGetHtml);
    bindEapIframePointerGate();
  }

  @override
  void dispose() {
    _alive = false;
    unbindEapIframePointerGate();
    widget.controller.detach();
    _loadSub?.cancel();
    _sub?.cancel();
    retireEapIframe(_iframe);
    _iframe = null;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.complete('');
    }
    _pending.clear();
    super.dispose();
  }

  void _postSetHtml(String htmlText) {
    postEapIframeMessage(_iframe, {'type': 'eapSetHtml', 'html': htmlText});
  }

  Future<String> _postGetHtml() {
    final id = ++_req;
    final c = Completer<String>();
    _pending[id] = c;
    postEapIframeMessage(_iframe, {'type': 'eapGetHtml', 'id': id});
    return c.future.timeout(
      const Duration(seconds: 2),
      // 응답이 없으면 실패로 알린다 — 편집한 본문 대신 원본 템플릿이
      // 조용히 저장되는 것을 막는다.
      onTimeout: () => throw StateError('본문을 읽지 못했습니다. 잠시 후 다시 시도해 주세요.'),
    );
  }

  void _onMessage(html.MessageEvent e) {
    final data = parseEapIframeMessage(e.data);
    if (data == null) return;
    final type = data['type']?.toString();
    if (type == 'eapWheel') {
      forwardEapIframeWheel(
        context,
        alive: _alive,
        mounted: mounted,
        deltaY: (data['deltaY'] as num?)?.toDouble() ?? 0,
      );
      return;
    }
    if (type != 'eapHtml') return;
    final id = data['id'];
    final htmlText = data['html']?.toString() ?? '';
    if (id is num) {
      final c = _pending.remove(id.toInt());
      if (c != null && !c.isCompleted) c.complete(htmlText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildEapIframeView(_viewType, height: widget.height);
  }
}
