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
    // 본문은 iframe onLoad 에서만 보낸다 — attach 직후 postMessage 는 DOM 미부착·
    // contentWindow null 로 크래시(릴리즈 ErrorWidget 회색 화면)를 일으킨다.
  }

  void detach() {
    _set = null;
    _get = null;
  }

  /// iframe attach 전에 본문만 저장한다 — postMessage 를 부르지 않는다.
  void primeHtml(String html) {
    _html = html;
  }

  void setHtml(String html) {
    _html = html;
    _set?.call(html);
  }

  Future<String> getHtml() async {
    final get = _get;
    if (get == null) {
      throw StateError('본문 편집기가 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.');
    }
    _html = await get();
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
  var _loaded = false;
  String? _initError;

  @override
  html.IFrameElement? get iframeForPointerGate => _iframe;

  @override
  bool get iframeHostAlive => _alive;

  @override
  void initState() {
    super.initState();
    try {
      final iframe = createEapIframe(
        eapWebAssetUrl(widget.editorPage, mode: widget.editorMode),
      );
      _iframe = iframe;
      _viewType = registerEapIframeView('eap-html-editor', iframe);
      _sub = html.window.onMessage.listen(_onMessage);
      _loadSub = iframe.onLoad.listen((_) => _onIframeLoad());
      widget.controller.attach(setHtml: _postSetHtml, getHtml: _postGetHtml);
      bindEapIframePointerGate();
    } catch (e) {
      _initError = '$e';
    }
  }

  void _onIframeLoad() {
    if (!_alive || !mounted) return;
    _loaded = true;
    refreshEapIframePointerGate();
    unawaited(_syncContent());
  }

  Future<void> _syncContent() async {
    if (!_alive || !mounted || !_loaded) return;
    postEapIframeMessage(_iframe, {
      'type': 'eapSetPlaceholder',
      'text': widget.placeholder,
    });
    final htmlText = widget.controller._html.isNotEmpty
        ? widget.controller._html
        : widget.initialHtml;
    if (htmlText.isEmpty) return;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (!_alive || !mounted) return;
      if (_postSetHtml(htmlText)) return;
      await Future<void>.delayed(Duration(milliseconds: 60 * (attempt + 1)));
    }
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

  bool _postSetHtml(String htmlText) {
    return postEapIframeMessage(_iframe, {
      'type': 'eapSetHtml',
      'html': htmlText,
    });
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
    // 전역 메시지 스트림이라 다른 iframe 의 응답도 들어온다 — 내 것만 처리한다.
    if (!isFromEapIframe(e, _iframe)) return;
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
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '본문 편집기를 불러오지 못했습니다.\n$_initError',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
      );
    }
    return buildEapIframeView(_viewType, height: widget.height);
  }
}
