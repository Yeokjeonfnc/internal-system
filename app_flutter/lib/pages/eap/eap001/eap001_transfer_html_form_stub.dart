// 양수도 HTML 양식 호스트 — stub (비웹).

import 'package:flutter/material.dart';

typedef EapTransferHtmlExport = ({
  String title,
  String html,
  Map<String, String> fields,
});

/// Web DOM overlay iframe 제거. 비웹은 no-op.
void removeEapTransferHtmlOverlays() {}

class EapTransferHtmlFormHost extends StatefulWidget {
  const EapTransferHtmlFormHost({
    super.key,
    required this.draftUser,
    required this.draftDept,
    required this.draftDate,
    required this.controller,
  });

  final String draftUser;
  final String draftDept;
  final String draftDate;
  final EapTransferHtmlFormController controller;

  @override
  State<EapTransferHtmlFormHost> createState() =>
      _EapTransferHtmlFormHostStubState();
}

class EapTransferHtmlFormController {
  Future<EapTransferHtmlExport?> Function()? _export;

  void attach(Future<EapTransferHtmlExport?> Function() export) {
    _export = export;
  }

  void detach() {
    _export = null;
  }

  Future<EapTransferHtmlExport?> export() async {
    final fn = _export;
    if (fn == null) return null;
    return fn();
  }
}

class _EapTransferHtmlFormHostStubState extends State<EapTransferHtmlFormHost> {
  @override
  void initState() {
    super.initState();
    widget.controller.attach(() async => null);
  }

  @override
  void dispose() {
    widget.controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '양수도 품의 HTML 작성 화면은 웹(Chrome)에서 사용하세요.\n'
          'flutter run -d chrome',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
