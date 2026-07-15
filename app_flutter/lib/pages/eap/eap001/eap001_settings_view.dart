// 전자결재 환경설정 — 연결 테스트 + 양식 코드 관리.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_form_config_panel.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001SettingsView extends StatelessWidget {
  const Eap001SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EapPageHeader(
              title: EapRoutes.titleFor(EapRoutes.settings),
              showSearch: false,
            ),
            const EapSettingsPanel(),
            const EapFormConfigPanel(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
