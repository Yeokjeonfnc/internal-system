// 받은결재·올린결재·수신참조·전체문서 화면.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_filter.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_list_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';

class Eap001InboxView extends StatefulWidget {
  const Eap001InboxView({super.key});

  @override
  State<Eap001InboxView> createState() => _Eap001InboxViewState();
}

class _Eap001InboxViewState extends State<Eap001InboxView> {
  final _keywordCtrl = TextEditingController();

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _keywordCtrl.text;
    return DetailScreenWithTabs(
      title: DetailScreenHeadline.plain(text: '받은결재'),
      toolbar: EapDocumentSearchBar(
        controller: _keywordCtrl,
        onChanged: (_) => setState(() {}),
      ),
      tabTitles: const ['결재대기문서', '진행문서', '결재완료문서', '반려문서'],
      tabPages: [
        Eap001ListView(
          folder: 'inbox-pending',
          emptyMessage: '결재할 문서가 없습니다',
          keyword: keyword,
        ),
        Eap001ListView(
          folder: 'inbox-progress',
          emptyMessage: '진행 중인 문서가 없습니다',
          keyword: keyword,
        ),
        Eap001ListView(
          folder: 'inbox-complete',
          emptyMessage: '결재 완료 문서가 없습니다',
          keyword: keyword,
        ),
        Eap001ListView(
          folder: 'inbox-rejected',
          emptyMessage: '반려된 문서가 없습니다',
          keyword: keyword,
        ),
      ],
    );
  }
}

class Eap001SentView extends StatefulWidget {
  const Eap001SentView({super.key});

  @override
  State<Eap001SentView> createState() => _Eap001SentViewState();
}

class _Eap001SentViewState extends State<Eap001SentView> {
  final _keywordCtrl = TextEditingController();

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _keywordCtrl.text;
    return DetailScreenWithTabs(
      title: DetailScreenHeadline.plain(text: '올린결재'),
      toolbar: EapDocumentSearchBar(
        controller: _keywordCtrl,
        onChanged: (_) => setState(() {}),
      ),
      tabTitles: const ['상신 문서', '결재완료', '반려', '임시보관'],
      tabPages: [
        Eap001ListView(
          folder: 'sent-open',
          emptyMessage: '진행 중인 상신 문서가 없습니다',
          keyword: keyword,
        ),
        Eap001ListView(
          folder: 'sent-complete',
          emptyMessage: '결재 완료 문서가 없습니다',
          keyword: keyword,
        ),
        Eap001ListView(
          folder: 'sent-rejected',
          emptyMessage: '반려된 문서가 없습니다',
          keyword: keyword,
        ),
        Eap001ListView(
          folder: 'sent-temp',
          emptyMessage: '임시저장 문서가 없습니다',
          keyword: keyword,
        ),
      ],
    );
  }
}

class Eap001SimpleFolderView extends StatefulWidget {
  const Eap001SimpleFolderView({
    super.key,
    required this.title,
    required this.folder,
    this.emptyMessage,
  });

  final String title;
  final String folder;
  final String? emptyMessage;

  @override
  State<Eap001SimpleFolderView> createState() => _Eap001SimpleFolderViewState();
}

class _Eap001SimpleFolderViewState extends State<Eap001SimpleFolderView> {
  final _keywordCtrl = TextEditingController();

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EapPageHeader(title: widget.title, showSearch: false),
          EapDocumentSearchBar(
            controller: _keywordCtrl,
            onChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: Eap001ListView(
              folder: widget.folder,
              emptyMessage: widget.emptyMessage,
              keyword: _keywordCtrl.text,
            ),
          ),
        ],
      ),
    );
  }
}
