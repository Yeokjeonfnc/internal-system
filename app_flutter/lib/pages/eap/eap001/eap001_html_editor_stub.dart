// 전자결재 HTML 본문 편집기 — non-web 폴백.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

class EapHtmlEditorController {
  String _html = '';
  void Function(String html)? _set;

  void attach({
    required void Function(String html) setHtml,
    required Future<String> Function() getHtml,
  }) {
    _set = setHtml;
    if (_html.isNotEmpty) _set!(_html);
  }

  void detach() {
    _set = null;
  }

  void setHtml(String html) {
    _html = html;
    _set?.call(html);
  }

  Future<String> getHtml() async => _html;
}

class EapHtmlEditorHost extends StatefulWidget {
  const EapHtmlEditorHost({
    super.key,
    required this.controller,
    this.initialHtml = '',
    this.height,
    this.placeholder = '본문을 입력하세요.',
    this.editorPage = 'eap_html_editor.html',
    this.editorMode = '',
  });

  final EapHtmlEditorController controller;
  final String initialHtml;
  final double? height;
  final String placeholder;
  final String editorPage;
  final String editorMode;

  @override
  State<EapHtmlEditorHost> createState() => _EapHtmlEditorHostStubState();
}

class _EapHtmlEditorHostStubState extends State<EapHtmlEditorHost> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialHtml);
    widget.controller.attach(
      setHtml: (html) => _ctrl.text = html,
      getHtml: () async => _ctrl.text,
    );
    widget.controller.setHtml(widget.initialHtml);
  }

  @override
  void dispose() {
    widget.controller.detach();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? 420,
      child: TextField(
        controller: _ctrl,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: widget.placeholder,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          hintStyle: const TextStyle(color: AppTheme.textPlaceholder),
        ),
        onChanged: widget.controller.setHtml,
      ),
    );
  }
}
