// 전자결재 양식 빌더·기안 입력 — 비웹 폴백.

import 'package:flutter/material.dart';

class EapFormBuilderController {
  String _html = '';
  String _schemaJson = '[]';

  void setHtml(String html) => _html = html;

  Future<({String html, String schemaJson})> getFormData() async =>
      (html: _html, schemaJson: _schemaJson);
}

class EapFormBuilderHost extends StatelessWidget {
  const EapFormBuilderHost({super.key, required this.controller});

  final EapFormBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('양식 빌더는 웹 브라우저에서만 사용할 수 있습니다.'),
    );
  }
}

class EapFormFillController {
  String _html = '';
  Map<String, String> _context = {};

  void setHtml(String html) => _html = html;

  void setContext(Map<String, String> context) {
    _context = Map<String, String>.from(context);
  }

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
      child: const Center(
        child: Text('양식 입력은 웹 브라우저에서만 사용할 수 있습니다.'),
      ),
    );
  }
}
