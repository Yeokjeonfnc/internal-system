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
    // onLoad 에서만 본문 전송 — attach 직후 postMessage 크래시 방지.
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

class _EapFormBuilderHostState extends ConsumerState<EapFormBuilderHost> {
  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _sub;
  StreamSubscription<html.Event>? _loadSub;
  Completer<void>? _ready;
  int _req = 0;
  final Map<int, Completer<({String html, String schemaJson})>> _pending = {};
  var _alive = true;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    final iframe = createEapIframe(
      eapWebAssetUrl(kEapHtmlEditorPage, mode: 'form'),
    );
    _iframe = iframe;
    _viewType = registerEapIframeView('eap-form-builder', iframe);
    _ready = Completer<void>();
    _sub = html.window.onMessage.listen(_onMessage);
    _loadSub = iframe.onLoad.listen((_) {
      if (!_alive || !mounted) return;
      _loaded = true;
      final ready = _ready;
      if (ready != null && !ready.isCompleted) ready.complete();
      if (widget.controller._html.isNotEmpty) {
        _postSetHtml(widget.controller._html);
      }
    });
    widget.controller.attach(
      setHtml: _postSetHtml,
      getFormData: _postGetFormData,
    );
    // 이 iframe 은 **일부러 `IframePointerGate` 를 안 듣는다.**
    //
    // 이 위젯은 항상 `showEapFormEditorDialog` 안에서만 만들어진다(=이 다이얼로그
    // 자체가 편집기 화면이다). 그런데 그 다이얼로그를 여는 쪽(`_openBuilder`)은
    // 열기 *전에* `IframePointerGate.push()` 를 불러서, 다이얼로그 **뒤에 깔린**
    // 서식 미리보기 iframe 이 클릭을 가로채지 못하게 막는다.
    //
    // 문제는 그 게이트가 전역 카운터라 이 iframe 도 같은 신호를 듣고 있었다는
    // 것이다 — 다이얼로그가 뜨자마자(=게이트가 켜져 있는 채로) 이 iframe 이
    // `bindEapIframePointerGate()` 로 구독을 걸면, 처음 한 번은 물론이고 다이얼로그가
    // 닫힐 때까지 계속 `pointer-events:none` 상태로 남는다. 팔레트·캔버스·속성
    // 패널이 전부 이 iframe 안에 있으므로 **다이얼로그의 확인/취소만 빼고 전부
    // 클릭이 안 먹는 것**처럼 보였다 — 실제 신고된 증상과 정확히 일치한다.
    //
    // 이 위젯은 항상 모달의 "맨 앞" 콘텐츠이지 뒤에 깔리는 배경이 아니므로,
    // 게이트를 아예 구독하지 않는 것이 옳다(뒤에 깔린 미리보기를 막는 목적은
    // 그 미리보기 쪽 호스트가 이미 담당한다).
  }

  @override
  void dispose() {
    _alive = false;
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

  Future<void> _ensureIframeReady() async {
    if (_loaded) return;
    final ready = _ready;
    if (ready == null) return;
    await ready.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw StateError(
        '양식 편집기가 아직 로드되지 않았습니다. 잠시 후 다시 시도해 주세요.',
      ),
    );
  }

  Future<({String html, String schemaJson})> _postGetFormData() async {
    await _ensureIframeReady();
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      final id = ++_req;
      final c = Completer<({String html, String schemaJson})>();
      _pending[id] = c;
      var sent = postEapIframeMessage(_iframe, {'type': 'eapGetHtml', 'id': id});
      if (!sent) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        sent = postEapIframeMessage(_iframe, {'type': 'eapGetHtml', 'id': id});
      }
      if (!sent) {
        _pending.remove(id);
        throw StateError(
          '양식 편집기와 통신할 수 없습니다. 편집기를 닫았다가 다시 열어 주세요.',
        );
      }
      try {
        return await c.future.timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw StateError(
            '양식 편집기가 응답하지 않습니다. 편집기를 닫았다가 다시 열어 주세요.',
          ),
        );
      } on StateError catch (e) {
        lastError = e;
        _pending.remove(id);
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 120));
        }
      }
    }
    throw lastError ??
        StateError('양식 편집기가 응답하지 않습니다. 편집기를 닫았다가 다시 열어 주세요.');
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

    // HTML·스키마 응답 — 대기 중인 요청 id 가 있으면 출처 검사 실패여도 수신한다.
    // (dart2js Window 래퍼 불일치로 isFromEapIframe 이 false 가 되는 경우 대비)
    if (type == 'eapFormData' || type == 'eapHtml') {
      final id = data['id'];
      if (id is num) {
        final reqId = id.toInt();
        final c = _pending[reqId];
        if (c != null && !c.isCompleted) {
          _pending.remove(reqId);
          final err = data['error']?.toString().trim() ?? '';
          if (err.isNotEmpty) {
            c.completeError(StateError(err));
            return;
          }
          final htmlText = data['html']?.toString() ?? '';
          final schema = data['schema'];
          c.complete((
            html: htmlText,
            schemaJson: schema == null ? '[]' : jsonEncode(schema),
          ));
          return;
        }
      }
    }

    // 전역 메시지 스트림이라 다른 iframe 의 응답도 들어온다 — 내 것만 처리한다.
    if (!isFromEapIframe(e, _iframe)) return;
    if (type == 'eapWheel') return;
    if (type == 'eapRequestForms') {
      _replyFormsList();
      return;
    }
    if (type == 'eapLoadForm') {
      final code = data['formCode']?.toString() ?? '';
      if (code.isNotEmpty) _loadForm(code);
    }
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
    // onLoad(_syncContent) 에서만 본문·context 전송 — attach 직후 크래시 방지.
  }

  void detach() {
    _set = null;
    _setContext = null;
    _get = null;
    _validate = null;
  }

  /// iframe attach 전에 본문만 저장한다.
  void primeHtml(String html) {
    _html = html;
  }

  /// iframe attach 전에 context 만 저장한다.
  void primeContext(Map<String, String> context) {
    _context = Map<String, String>.from(context);
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
  String? _initError;

  @override
  html.IFrameElement? get iframeForPointerGate => _iframe;

  @override
  bool get iframeHostAlive => _alive;

  @override
  void initState() {
    super.initState();
    try {
      final iframe = createEapIframe(eapWebAssetUrl(kEapFormFillPage));
      _iframe = iframe;
      _viewType = registerEapIframeView('eap-form-fill', iframe);
      _sub = html.window.onMessage.listen(_onMessage);
      _loadSub = iframe.onLoad.listen((_) => _onIframeLoad());
      widget.controller.attach(
        setHtml: _postSetHtml,
        setContext: _postSetContext,
        getHtml: _postGetHtml,
        validate: _postValidate,
      );
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
    final htmlText = widget.controller._html;
    final context = widget.controller._context;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (!_alive || !mounted) return;
      var ok = true;
      if (htmlText.isNotEmpty) ok = _postSetHtml(htmlText);
      if (context.isNotEmpty) {
        ok = _postSetContext(context) && ok;
      }
      if (ok || htmlText.isEmpty) return;
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
    for (final c in _pendingHtml.values) {
      if (!c.isCompleted) {
        c.completeError(StateError('본문 편집기가 닫혔습니다.'));
      }
    }
    for (final c in _pendingVal.values) {
      if (!c.isCompleted) {
        c.complete((ok: false, errors: <String>['본문 편집기가 닫혔습니다']));
      }
    }
    _pendingHtml.clear();
    _pendingVal.clear();
    super.dispose();
  }

  bool _postSetHtml(String htmlText) {
    return postEapIframeMessage(_iframe, {
      'type': 'eapSetHtml',
      'html': htmlText,
    });
  }

  bool _postSetContext(Map<String, String> context) {
    return postEapIframeMessage(_iframe, {
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
      onTimeout: () => throw StateError('본문을 읽지 못했습니다. 잠시 후 다시 시도해 주세요.'),
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
    await IframePointerGate.whileBlocked(context, () async {
      final value = await widget.onPickField!(pick);
      if (!_alive || !mounted || value == null) return;
      postEapIframeMessage(_iframe, {
        'type': 'eapPickResult',
        'fieldId': fieldId,
        'value': value,
      });
    });
  }

  void _onMessage(html.MessageEvent e) {
    // 전역 메시지 스트림이라 다른 iframe 의 응답도 들어온다 — 내 것만 처리한다.
    if (!isFromEapIframe(e, _iframe)) return;
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
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '양식 입력 화면을 불러오지 못했습니다.\n$_initError',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
      );
    }
    return buildEapIframeView(_viewType, height: widget.height);
  }
}
