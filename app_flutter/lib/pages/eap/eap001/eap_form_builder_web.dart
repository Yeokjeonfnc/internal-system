// 전자결재 양식 빌더·기안 입력 — Web iframe.

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/web/iframe_pointer_gate.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_quill.dart';
import 'package:app_flutter/pages/eap/eap001/eap_iframe_bridge_web.dart';
import 'package:app_flutter/pages/eap/eap001/eap_web_assets.dart';

class EapFormBuilderController {
  String _html = '';
  String _schemaJson = '[]';
  void Function(String html)? _set;
  Future<({String html, String schemaJson})> Function()? _get;

  void attach({
    required void Function(String html) setHtml,
    required Future<({String html, String schemaJson})> Function() getFormData,
  }) {
    _set = setHtml;
    _get = getFormData;
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

  Future<({String html, String schemaJson})> getFormData() async {
    if (_get != null) {
      final r = await _get!();
      _html = r.html;
      _schemaJson = r.schemaJson;
    }
    return (html: _html, schemaJson: _schemaJson);
  }
}

class EapFormBuilderHost extends ConsumerStatefulWidget {
  const EapFormBuilderHost({super.key, required this.controller});

  final EapFormBuilderController controller;

  @override
  ConsumerState<EapFormBuilderHost> createState() => _EapFormBuilderHostState();
}

class _EapFormBuilderHostState extends ConsumerState<EapFormBuilderHost>
    with EapIframePointerGateMixin {
  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _sub;
  StreamSubscription<html.Event>? _loadSub;
  int _req = 0;
  final Map<int, Completer<({String html, String schemaJson})>> _pending = {};
  var _alive = true;

  @override
  html.IFrameElement? get iframeForPointerGate => _iframe;

  @override
  bool get iframeHostAlive => _alive;

  @override
  void initState() {
    super.initState();
    final iframe = createEapIframe(
      eapWebAssetUrl(kEapHtmlEditorPage, mode: 'form'),
    );
    _iframe = iframe;
    _viewType = registerEapIframeView('eap-form-builder', iframe);
    _sub = html.window.onMessage.listen(_onMessage);
    _loadSub = iframe.onLoad.listen((_) {
      if (!_alive || !mounted) return;
      refreshEapIframePointerGate();
      if (widget.controller._html.isNotEmpty) {
        _postSetHtml(widget.controller._html);
      }
    });
    widget.controller.attach(
      setHtml: _postSetHtml,
      getFormData: _postGetFormData,
    );
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
      if (!c.isCompleted) c.complete((html: '', schemaJson: '[]'));
    }
    _pending.clear();
    super.dispose();
  }

  void _postSetHtml(String htmlText) {
    postEapIframeMessage(_iframe, {'type': 'eapSetHtml', 'html': htmlText});
  }

  Future<({String html, String schemaJson})> _postGetFormData() {
    final id = ++_req;
    final c = Completer<({String html, String schemaJson})>();
    _pending[id] = c;
    postEapIframeMessage(_iframe, {'type': 'eapGetHtml', 'id': id});
    return c.future.timeout(
      const Duration(seconds: 3),
      // 시간 안에 응답이 없으면 **실패로 알린다.**
      // 예전에는 마지막으로 보냈던 원본 html 과 빈 스키마('[]')를 돌려줬다.
      // 그러면 사용자가 편집기에서 한 작업이 통째로 사라진 채 「확인」이 성공한 것처럼
      // 보이고, 저장하면 **필드 정의까지 함께 지워졌다.**
      onTimeout: () => throw StateError(
        '양식 편집기가 응답하지 않습니다. 편집기를 닫았다가 다시 열어 주세요.',
      ),
    );
  }

  Future<void> _replyFormsList() async {
    final api = ref.read(eapApiProvider);
    final forms = await api.listForms();
    if (!_alive || !mounted) return;
    postEapIframeMessage(_iframe, {
      'type': 'eapFormsList',
      'forms': forms
          .map((f) => {'formCode': f.formCode, 'formName': f.formName})
          .toList(),
    });
  }

  Future<void> _loadForm(String formCode) async {
    final api = ref.read(eapApiProvider);
    final form = await api.getForm(formCode);
    if (!_alive || !mounted || form == null) return;
    final htmlText = eapStoredBodyToHtml(form.contentHtml, form.contentDelta);
    _postSetHtml(htmlText);
  }

  void _onMessage(html.MessageEvent e) {
    final data = parseEapIframeMessage(e.data);
    if (data == null) return;
    final type = data['type']?.toString();
    if (type == 'eapWheel') return;
    if (type == 'eapRequestForms') {
      _replyFormsList();
      return;
    }
    if (type == 'eapLoadForm') {
      final code = data['formCode']?.toString() ?? '';
      if (code.isNotEmpty) _loadForm(code);
      return;
    }
    if (type != 'eapFormData' && type != 'eapHtml') return;
    final id = data['id'];
    if (id is! num) return;
    final c = _pending.remove(id.toInt());
    if (c == null || c.isCompleted) return;
    final htmlText = data['html']?.toString() ?? '';
    final schema = data['schema'];
    c.complete((
      html: htmlText,
      schemaJson: schema == null ? '[]' : jsonEncode(schema),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return buildEapIframeView(_viewType);
  }
}

class EapFormFillController {
  String _html = '';
  Map<String, String> _context = {};
  void Function(String html)? _set;
  void Function(Map<String, String> context)? _setContext;
  Future<String> Function()? _get;
  Future<({bool ok, List<String> errors})> Function()? _validate;

  void attach({
    required void Function(String html) setHtml,
    required void Function(Map<String, String> context) setContext,
    required Future<String> Function() getHtml,
    required Future<({bool ok, List<String> errors})> Function() validate,
  }) {
    _set = setHtml;
    _setContext = setContext;
    _get = getHtml;
    _validate = validate;
    if (_html.isNotEmpty) _set!(_html);
    if (_context.isNotEmpty) _setContext!(_context);
  }

  void detach() {
    _set = null;
    _setContext = null;
    _get = null;
    _validate = null;
  }

  void setHtml(String html) {
    _html = html;
    _set?.call(html);
  }

  void setContext(Map<String, String> context) {
    _context = Map<String, String>.from(context);
    _setContext?.call(_context);
  }

  /// 사용자가 입력한 본문을 iframe 에서 읽어 온다.
  ///
  /// 붙어 있지 않으면 **예외를 던진다.** 예전에는 마지막으로 밀어 넣었던 값(=빈 서식
  /// 템플릿)을 그대로 돌려줬는데, 그러면 사용자가 채운 내용이 사라진 채
  /// "저장했습니다" 가 뜨고 **빈 문서가 상신된다.** 조용히 잘못 저장되는 것보다
  /// 실패를 알리는 편이 낫다.
  Future<String> getHtml() async {
    final get = _get;
    if (get == null) {
      throw StateError('본문 편집기가 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.');
    }
    _html = await get();
    return _html;
  }

  /// 필수 항목 검증. **붙어 있지 않으면 통과시키지 않는다(fail-closed).**
  ///
  /// 예전에는 `_validate == null` 일 때 `ok: true` 를 돌려줬다. 즉 편집기가 아직
  /// 안 붙었거나 응답이 없으면 **필수 항목을 비워 둔 채로 상신이 통과**됐다.
  Future<({bool ok, List<String> errors})> validate() async {
    final validate = _validate;
    if (validate == null) {
      return (ok: false, errors: <String>['본문 편집기가 준비되지 않았습니다']);
    }
    return validate();
  }

  /// 사용자가 고른 값(사원·부서 등)을 해당 필드에 채워 넣는다.
  ///
  /// 예전 구현은 두 인자를 모두 버리고 기존 context 를 다시 보내기만 해서
  /// **고른 값이 절대 반영되지 않았다.**
  void applyPickResult(String fieldId, String value) {
    if (fieldId.trim().isEmpty) return;
    _context = {..._context, fieldId: value};
    _setContext?.call(_context);
  }
}

typedef EapFormPickHandler = Future<String?> Function(String pickType);

class EapFormFillHost extends StatefulWidget {
  const EapFormFillHost({
    super.key,
    required this.controller,
    this.height,
    this.onPickField,
  });

  final EapFormFillController controller;
  final double? height;
  final EapFormPickHandler? onPickField;

  @override
  State<EapFormFillHost> createState() => _EapFormFillHostState();
}

class _EapFormFillHostState extends State<EapFormFillHost>
    with EapIframePointerGateMixin {
  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _sub;
  StreamSubscription<html.Event>? _loadSub;
  int _req = 0;
  final Map<int, Completer<String>> _pendingHtml = {};
  final Map<int, Completer<({bool ok, List<String> errors})>> _pendingVal = {};
  var _alive = true;
  var _loaded = false;

  @override
  html.IFrameElement? get iframeForPointerGate => _iframe;

  @override
  bool get iframeHostAlive => _alive;

  @override
  void initState() {
    super.initState();
    final iframe = createEapIframe(eapWebAssetUrl(kEapFormFillPage));
    _iframe = iframe;
    _viewType = registerEapIframeView('eap-form-fill', iframe);
    _sub = html.window.onMessage.listen(_onMessage);
    _loadSub = iframe.onLoad.listen((_) {
      if (!_alive || !mounted) return;
      _loaded = true;
      refreshEapIframePointerGate();
      _syncContent();
    });
    widget.controller.attach(
      setHtml: _postSetHtml,
      setContext: _postSetContext,
      getHtml: _postGetHtml,
      validate: _postValidate,
    );
    bindEapIframePointerGate();
  }

  void _syncContent() {
    if (!_loaded) return;
    if (widget.controller._html.isNotEmpty) {
      _postSetHtml(widget.controller._html);
    }
    if (widget.controller._context.isNotEmpty) {
      _postSetContext(widget.controller._context);
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
    for (final c in _pendingHtml.values) {
      if (!c.isCompleted) c.complete('');
    }
    for (final c in _pendingVal.values) {
      if (!c.isCompleted) c.complete((ok: true, errors: <String>[]));
    }
    _pendingHtml.clear();
    _pendingVal.clear();
    super.dispose();
  }

  void _postSetHtml(String htmlText) {
    postEapIframeMessage(_iframe, {'type': 'eapSetHtml', 'html': htmlText});
  }

  void _postSetContext(Map<String, String> context) {
    postEapIframeMessage(_iframe, {
      'type': 'eapSetContext',
      'context': context,
    });
  }

  Future<String> _postGetHtml() {
    final id = ++_req;
    final c = Completer<String>();
    _pendingHtml[id] = c;
    postEapIframeMessage(_iframe, {'type': 'eapGetHtml', 'id': id});
    return c.future.timeout(
      const Duration(seconds: 3),
      // 응답이 없으면 실패로 알린다 — 조용히 빈 템플릿을 저장하지 않는다.
      onTimeout: () => throw StateError(
        '본문을 읽지 못했습니다. 잠시 후 다시 시도해 주세요.',
      ),
    );
  }

  Future<({bool ok, List<String> errors})> _postValidate() {
    final id = ++_req;
    final c = Completer<({bool ok, List<String> errors})>();
    _pendingVal[id] = c;
    postEapIframeMessage(_iframe, {'type': 'eapValidate', 'id': id});
    return c.future.timeout(
      const Duration(seconds: 3),
      // 검증 응답이 없으면 **통과시키지 않는다.**
      // 예전에는 ok:true 라, 편집기가 느리기만 해도 필수 항목을 비운 채 상신됐다.
      onTimeout: () => (ok: false, errors: <String>['본문 검증이 응답하지 않습니다']),
    );
  }

  Future<void> _handlePickField(Map<dynamic, dynamic> data) async {
    final pick = data['pick']?.toString() ?? '';
    final fieldId = data['fieldId']?.toString() ?? '';
    if (fieldId.isEmpty || widget.onPickField == null) return;
    IframePointerGate.push();
    try {
      final value = await widget.onPickField!(pick);
      if (!_alive || !mounted || value == null) return;
      postEapIframeMessage(_iframe, {
        'type': 'eapPickResult',
        'fieldId': fieldId,
        'value': value,
      });
    } finally {
      IframePointerGate.pop();
    }
  }

  void _onMessage(html.MessageEvent e) {
    final data = parseEapIframeMessage(e.data);
    if (data == null) return;
    final type = data['type']?.toString();
    if (type == 'eapWheel') return;
    if (type == 'eapPickField') {
      _handlePickField(data);
      return;
    }
    if (type == 'eapValidateResult') {
      final id = data['id'];
      if (id is num) {
        final c = _pendingVal.remove(id.toInt());
        if (c != null && !c.isCompleted) {
          final errors =
              (data['errors'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[];
          c.complete((ok: data['ok'] == true, errors: errors));
        }
      }
      return;
    }
    if (type != 'eapHtml') return;
    final id = data['id'];
    final htmlText = data['html']?.toString() ?? '';
    if (id is num) {
      final c = _pendingHtml.remove(id.toInt());
      if (c != null && !c.isCompleted) c.complete(htmlText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildEapIframeView(_viewType, height: widget.height);
  }
}
