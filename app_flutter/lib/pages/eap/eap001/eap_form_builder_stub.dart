// 전자결재 양식 빌더·기안 입력 — 비웹 폴백.

import 'package:flutter/material.dart';

class EapFormBuilderController {
  String _html = '';
  final String _schemaJson = '[]';

  void setHtml(String html) => _html = html;

  Future<({String html, String schemaJson})> getFormData() async =>
      (html: _html, schemaJson: _schemaJson);
}

class EapFormBuilderHost extends StatelessWidget {
  const EapFormBuilderHost({super.key, required this.controller});

  final EapFormBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('양식 빌더는 웹 브라우저에서만 사용할 수 있습니다.'));
  }
}

class EapFormFillController {
  String _html = '';

  void primeHtml(String html) => _html = html;

  void setHtml(String html) => _html = html;

  void primeContext(Map<String, String> context) {}

  // 웹 버전(eap_form_builder_web.dart)과 같은 인터페이스를 맞추기 위한 자리.
  // 이 스텁은 애초에 아무것도 그리지 않으므로(build 가 "웹에서만" 안내만 띄움)
  // 받은 값을 저장해 봐야 읽는 곳이 없다 — 그래서 저장하지 않고 버린다.
  void setContext(Map<String, String> context) {}

  Future<String> getHtml() async => _html;

  Future<({bool ok, List<String> errors})> validate() async =>
      (ok: true, errors: <String>[]);
}

typedef EapFormPickHandler = Future<String?> Function(String pickType);

class EapFormFillHost extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 400,
      child: const Center(child: Text('양식 입력은 웹 브라우저에서만 사용할 수 있습니다.')),
    );
  }
}
