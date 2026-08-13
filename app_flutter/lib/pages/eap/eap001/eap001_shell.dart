// 전자결재 셸 — 본문(홈·목록·설정). 화면 이동은 메인 사이드바(전자결재 카테고리)로 한다.

import 'package:flutter/material.dart';

import 'package:app_flutter/pages/eap/eap001/eap001_home_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_list_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_detail_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_settings_view.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class EapShell extends StatelessWidget {
  const EapShell({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final normalized = path == EapRoutes.root ? EapRoutes.home : path;
    final docId = EapRoutes.docIdFromPath(path);

    if (docId != null) {
      return Eap001DetailView(docId: docId);
    }
    if (normalized == EapRoutes.home) {
      return const Eap001HomeView();
    }
    if (normalized == EapRoutes.settings) {
      return const Eap001SettingsView();
    }
    return Eap001ListView(path: normalized);
  }
}
