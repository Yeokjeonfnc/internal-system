// 전자결재 셸 — 좌측 문서함 네비 + 본문(홈·목록·설정).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_home_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_list_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_detail_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class EapShell extends StatelessWidget {
  const EapShell({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    final normalized = path == EapRoutes.root ? EapRoutes.home : path;
    final docId = EapRoutes.docIdFromPath(path);

    Widget body;
    if (docId != null) {
      body = Eap001DetailView(docId: docId);
    } else if (normalized == EapRoutes.home) {
      body = const Eap001HomeView();
    } else if (normalized == EapRoutes.settings) {
      body = ColoredBox(
        color: AppTheme.appSurface,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EapPageHeader(
                title: EapRoutes.titleFor(normalized),
                showSearch: false,
              ),
              const EapSettingsPanel(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    } else {
      body = Eap001ListView(path: normalized);
    }

    if (compact) {
      return ColoredBox(
        color: AppTheme.appSurface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CompactEapNav(currentPath: normalized),
            Expanded(child: body),
          ],
        ),
      );
    }

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EapNavPanel(currentPath: normalized),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _CompactEapNav extends StatelessWidget {
  const _CompactEapNav({required this.currentPath});

  final String currentPath;

  static const _shortcuts = [
    (EapRoutes.home, '홈'),
    (EapRoutes.pending, '대기'),
    (EapRoutes.drafted, '기안'),
    (EapRoutes.approved, '완료'),
    (EapRoutes.settings, '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBackground,
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: _shortcuts.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            final (path, label) = _shortcuts[i];
            final selected = currentPath == path;
            return ChoiceChip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => context.go(path),
              selectedColor: AppTheme.tableRowSelectedTint,
              labelStyle: TextStyle(
                color: selected ? AppTheme.accentRed : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              side: const BorderSide(color: AppTheme.hairline),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );
          },
        ),
      ),
    );
  }
}
