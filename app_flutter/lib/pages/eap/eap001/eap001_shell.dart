// 전자결재 셸 — 본문(기안·받은결재·올린결재·수신참조·전체문서·서식).

import 'package:flutter/material.dart';

import 'package:app_flutter/pages/eap/eap001/eap001_compose_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_detail_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_folder_views.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_home_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_form_editor_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_form_list_view.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class EapShell extends StatelessWidget {
  const EapShell({
    super.key,
    required this.path,
    this.query = const {},
  });

  final String path;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final normalized = path == EapRoutes.root ? EapRoutes.home : path;
    final docId = EapRoutes.docIdFromPath(path);
    final editCode = EapRoutes.formCodeFromEditPath(path);

    if (docId != null) {
      return Eap001DetailView(docId: docId);
    }
    if (normalized == EapRoutes.formNew) {
      return const Eap001FormEditorView();
    }
    if (editCode != null) {
      return Eap001FormEditorView(formCode: editCode);
    }
    if (normalized == EapRoutes.forms) {
      return const Eap001FormListView();
    }
    if (normalized == EapRoutes.home) {
      return const Eap001HomeView();
    }
    if (normalized == EapRoutes.compose) {
      return Eap001ComposeView(
        key: ValueKey(query['form'] ?? ''),
        formCode: query['form'],
      );
    }
    if (normalized == EapRoutes.inbox) {
      return const Eap001InboxView();
    }
    if (normalized == EapRoutes.sent) {
      return const Eap001SentView();
    }
    if (normalized == EapRoutes.cc) {
      return const Eap001SimpleFolderView(
        title: '수신참조결재',
        folder: 'cc',
        emptyMessage: '수신·참조·열람 문서가 없습니다',
      );
    }
    if (normalized == EapRoutes.all) {
      return const Eap001SimpleFolderView(
        title: '전체문서',
        folder: 'all',
        emptyMessage: '조회할 문서가 없습니다',
      );
    }
    return const Eap001HomeView();
  }
}
