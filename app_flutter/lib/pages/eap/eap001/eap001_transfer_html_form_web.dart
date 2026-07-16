// 양수도 HTML 양식 호스트 — Flutter Web.
// HtmlElementView 대신 DOM iframe 오버레이 (플랫폼 뷰 dispose race 회피).
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'package:app_flutter/pages/eap/eap001/eap001_transfer_html_form_stub.dart';

export 'package:app_flutter/pages/eap/eap001/eap001_transfer_html_form_stub.dart'
    show EapTransferHtmlExport, EapTransferHtmlFormController;

const _kIframeClassTransfer = 'yj-eap-transfer-iframe';
const _kIframeClassBasic = 'yj-eap-basic-iframe';

Uri eapFormPageUri({
  required String htmlFile,
  required String user,
  required String dept,
  required String date,
}) {
  final origin = html.window.location.origin;
  final baseHref =
      html.document.querySelector('base')?.getAttribute('href') ?? '/';
  final base = Uri.parse(origin).resolve(baseHref);
  return base.resolve(htmlFile).replace(
        queryParameters: {
          'user': user,
          'dept': dept,
          'date': date,
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
}

Uri eapTransferFormPageUri({
  required String user,
  required String dept,
  required String date,
}) =>
    eapFormPageUri(
      htmlFile: 'eap_transfer_form.html',
      user: user,
      dept: dept,
      date: date,
    );

/// 다른 화면으로 이동해도 DOM 에 남는 iframe 을 강제 제거한다.
void removeEapTransferHtmlOverlays() {
  for (final cls in [_kIframeClassTransfer, _kIframeClassBasic]) {
    html.document.querySelectorAll('iframe.$cls').forEach((n) {
      n.remove();
    });
  }
}

void _removeStaleIframes(String iframeClass) {
  html.document.querySelectorAll('iframe.$iframeClass').forEach((n) {
    n.remove();
  });
}

class EapTransferHtmlFormHost extends StatefulWidget {
  const EapTransferHtmlFormHost({
    super.key,
    required this.draftUser,
    required this.draftDept,
    required this.draftDate,
    required this.controller,
    this.formHtmlFile = 'eap_transfer_form.html',
    this.iframeClass = _kIframeClassTransfer,
    this.initialSubject,
    this.initialBodyHtml,
  });

  final String draftUser;
  final String draftDept;
  final String draftDate;
  final EapTransferHtmlFormController controller;
  /// web/ 기준 HTML 파일명 (예: eap_basic_form.html)
  final String formHtmlFile;
  final String iframeClass;
  final String? initialSubject;
  final String? initialBodyHtml;

  @override
  State<EapTransferHtmlFormHost> createState() =>
      _EapTransferHtmlFormHostWebState();
}

class _EapTransferHtmlFormHostWebState extends State<EapTransferHtmlFormHost>
    with WidgetsBindingObserver {
  final GlobalKey _slotKey = GlobalKey();
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _sub;
  StreamSubscription<html.Event>? _resizeSub;
  final Map<String, Completer<EapTransferHtmlExport?>> _pending = {};
  var _seq = 0;
  var _disposed = false;
  Size? _lastSlotSize;
  Timer? _attachTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.attach(_export);
    _sub = html.window.onMessage.listen(_onMessage);
    _resizeSub = html.window.onResize.listen((_) => _syncIframeGeometry());

    // 라우트·시트 전환이 끝난 뒤 부착 (핫리스타트 잔존 iframe 제거 포함)
    _attachTimer = Timer(const Duration(milliseconds: 400), () {
      if (_disposed || !mounted) return;
      _attachIframe();
    });
  }

  @override
  void didChangeMetrics() {
    _syncIframeGeometry();
  }

  void _attachIframe() {
    if (_disposed) return;
    final existing = _iframe;
    if (existing != null && existing.isConnected == true) return;
    _removeStaleIframes(widget.iframeClass);
    _iframe = null;

    final iframe = html.IFrameElement()
      ..classes.add(widget.iframeClass)
      ..src = eapFormPageUri(
        htmlFile: widget.formHtmlFile,
        user: widget.draftUser,
        dept: widget.draftDept,
        date: widget.draftDate,
      ).toString()
      ..style.border = 'none'
      ..style.position = 'fixed'
      ..style.zIndex = '20'
      ..style.display = 'block'
      ..style.backgroundColor = '#ffffff'
      ..style.overflow = 'auto';
    iframe.onLoad.listen((_) {
      if (_disposed) return;
      _postInit();
      _syncIframeGeometry();
    });
    html.document.body?.append(iframe);
    _iframe = iframe;
    _syncIframeGeometry();
  }

  void _syncIframeGeometry() {
    if (_disposed) return;
    final iframe = _iframe;
    final ctx = _slotKey.currentContext;
    if (iframe == null || ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    iframe.style
      ..left = '${offset.dx}px'
      ..top = '${offset.dy}px'
      ..width = '${size.width}px'
      ..height = '${size.height}px';
  }

  void _postJson(Object payload) {
    final win = _iframe?.contentWindow;
    if (win == null) return;
    win.postMessage(jsonEncode(payload), '*');
  }

  void _postInit() {
    if (_disposed) return;
    _postJson({
      'type': 'yj_eap_init',
      'user': widget.draftUser,
      'dept': widget.draftDept,
      'date': widget.draftDate,
      if (widget.initialSubject != null) 'subject': widget.initialSubject,
      if (widget.initialBodyHtml != null) 'bodyHtml': widget.initialBodyHtml,
    });
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
    }
    return null;
  }

  void _onMessage(html.MessageEvent event) {
    if (_disposed) return;
    final data = _asMap(event.data);
    if (data == null) return;
    final type = data['type']?.toString();
    if (type == 'yj_eap_ready') {
      _postInit();
      return;
    }
    if (type != 'yj_eap_content') return;
    final requestId = data['requestId']?.toString();
    final fieldsRaw = data['fields'];
    final fields = <String, String>{};
    if (fieldsRaw is Map) {
      fieldsRaw.forEach((k, v) {
        fields[k.toString()] = v?.toString() ?? '';
      });
    }
    final export = (
      title: data['title']?.toString() ?? '',
      html: data['html']?.toString() ?? '',
      fields: fields,
    );
    if (requestId != null && _pending.containsKey(requestId)) {
      _pending.remove(requestId)?.complete(export);
      return;
    }
    if (_pending.isNotEmpty) {
      final key = _pending.keys.first;
      _pending.remove(key)?.complete(export);
    }
  }

  Future<EapTransferHtmlExport?> _export() async {
    if (_disposed || _iframe?.contentWindow == null) return null;
    final id = 'r${++_seq}';
    final c = Completer<EapTransferHtmlExport?>();
    _pending[id] = c;
    _postJson({'type': 'yj_eap_get', 'requestId': id});
    return c.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _pending.remove(id);
        return null;
      },
    );
  }

  void _removeIframe() {
    _iframe?.remove();
    _iframe = null;
    _removeStaleIframes(widget.iframeClass);
  }

  void _setIframeVisible(bool visible) {
    final iframe = _iframe;
    if (iframe == null) return;
    iframe.style.display = visible ? 'block' : 'none';
  }

  @override
  void deactivate() {
    // 탭/라우트 전환 중 먼저 숨김 (dispose 전에도 화면에서 사라지게)
    _setIframeVisible(false);
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (_disposed) return;
    if (_iframe == null) {
      _attachIframe();
    } else {
      _setIframeVisible(true);
      _syncIframeGeometry();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _attachTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.detach();
    _sub?.cancel();
    _resizeSub?.cancel();
    for (final c in _pending.values) {
      if (!c.isCompleted) c.complete(null);
    }
    _pending.clear();
    _removeIframe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final isCurrent = route?.isCurrent ?? true;
    // 다른 라우트가 위에 있거나 탭 전환 중이면 overlay 숨김
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      if (!isCurrent) {
        _setIframeVisible(false);
      } else if (_iframe != null) {
        _setIframeVisible(true);
        _syncIframeGeometry();
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final next = Size(constraints.maxWidth, constraints.maxHeight);
        if (_lastSlotSize != next) {
          _lastSlotSize = next;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_disposed) _syncIframeGeometry();
          });
        }
        return ColoredBox(
          key: _slotKey,
          color: Colors.white,
          child: const SizedBox.expand(
            child: Center(
              child: Text(
                '양식 불러오는 중…',
                style: TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
            ),
          ),
        );
      },
    );
  }
}
