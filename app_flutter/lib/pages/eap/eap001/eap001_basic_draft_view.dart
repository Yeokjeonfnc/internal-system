// 업무기안(yeokjeon_eap01) — 다우 양식과 동일 HTML로 작성 후 기안.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as pkg_provider;
import 'package:url_launcher/url_launcher.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_transfer_html_form.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

const String kEapBasicFormCode = 'yeokjeon_eap01';

Future<void> openEapBasicDraft(
  BuildContext context, {
  String? formCode,
  EapDocument? editDoc,
}) {
  return Navigator.of(context)
      .push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EapBasicDraftView(
            initialFormCode: formCode,
            editDoc: editDoc,
          ),
        ),
      )
      .whenComplete(removeEapTransferHtmlOverlays);
}

class EapBasicDraftView extends ConsumerStatefulWidget {
  const EapBasicDraftView({
    super.key,
    this.initialFormCode,
    this.editDoc,
  });

  final String? initialFormCode;
  final EapDocument? editDoc;

  @override
  ConsumerState<EapBasicDraftView> createState() => _EapBasicDraftViewState();
}

class _EapBasicDraftViewState extends ConsumerState<EapBasicDraftView> {
  late final String _formCode;
  final _htmlCtrl = EapTransferHtmlFormController();
  bool _submitting = false;
  bool _hostReady = false;

  bool get _isEdit =>
      widget.editDoc != null && (widget.editDoc!.mappingId ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    final edit = widget.editDoc;
    _formCode = widget.initialFormCode?.trim().isNotEmpty == true
        ? widget.initialFormCode!.trim()
        : (edit?.formCode.trim().isNotEmpty == true
            ? edit!.formCode.trim()
            : kEapBasicFormCode);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _hostReady = true);
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final exported = await _htmlCtrl.export();
      if (!mounted) return;
      if (exported == null) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '작성 값을 가져오지 못했습니다. 웹(Chrome)에서 양식을 연 뒤 다시 시도해 주세요.',
            ),
          ),
        );
        return;
      }

      final title = exported.title.trim();
      final contentHtml = exported.html.trim();
      if (title.isEmpty) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('제목을 입력해 주세요.')),
        );
        return;
      }
      if (contentHtml.isEmpty) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('본문을 입력해 주세요.')),
        );
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '[EAP basic] title="$title" contentLen=${contentHtml.length} '
          'mappingId=${widget.editDoc?.mappingId}',
        );
      }

      final draftUserId = pkg_provider.Provider.of<AuthProvider>(
        context,
        listen: false,
      ).userId;
      final api = ref.read(eapApiProvider);
      final result = await api.draft(
        EapDraftRequest(
          formCode: _formCode,
          title: title,
          erpMenuId: 'eap001',
          draftUserId: draftUserId.isEmpty ? null : draftUserId,
          contentHtml: contentHtml,
          mappingId: _isEdit ? widget.editDoc!.mappingId : null,
        ),
      );
      if (!mounted) return;
      setState(() => _submitting = false);

      ref.invalidate(eapDocumentsProvider);
      ref.invalidate(eapHomeSummaryProvider);
      ref.invalidate(eapDocumentDetailProvider);

      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);
      final nav = Navigator.of(context);
      final redirect = result?.redirectUrl?.trim();

      if (result?.daouSubmitted == true &&
          redirect != null &&
          redirect.isNotEmpty) {
        final uri = Uri.tryParse(redirect);
        if (uri != null) {
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                opened
                    ? (_isEdit
                        ? '수정 반영 후 다우오피스 기안 화면을 열었습니다.'
                        : '다우오피스 기안 화면을 열었습니다.')
                    : '리다이렉트 URL을 열지 못했습니다.\n$redirect',
              ),
              duration: const Duration(seconds: 6),
            ),
          );
          nav.pop();
          router.go(EapRoutes.drafted);
          return;
        }
      }

      final msg = result == null
          ? '기안에 실패했습니다.'
          : result.daouSubmitted
              ? (result.message.isNotEmpty ? result.message : '다우 기안이 접수되었습니다.')
              : (result.message.isNotEmpty
                  ? result.message
                  : '다우 기안 실패 — 환경설정에서 연동 테스트를 확인하세요.');
      messenger.showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
      );
      nav.pop();
      router.go(EapRoutes.drafted);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatApiUserMessage(e, fallback: '기안에 실패했습니다.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = pkg_provider.Provider.of<AuthProvider>(context, listen: false);
    final now = DateTime.now();
    final week = const ['월', '화', '수', '목', '금', '토', '일'];
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}(${week[now.weekday - 1]})';
    final edit = widget.editDoc;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEdit ? '업무기안 수정 ($_formCode)' : '업무기안 ($_formCode)',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: FormStylePalette.textPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEdit ? '수정 후 다우 기안' : '다우 기안'),
            ),
          ),
        ],
      ),
      body: !_hostReady
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : EapTransferHtmlFormHost(
              draftUser: () {
                final nm = auth.userName.trim();
                final pos = auth.positionNm.trim();
                if (nm.isEmpty) return auth.userId;
                if (pos.isEmpty) return nm;
                return '$pos $nm';
              }(),
              draftDept: auth.profile?.deptNm ?? '',
              draftDate: dateStr,
              controller: _htmlCtrl,
              formHtmlFile: 'eap_basic_form.html',
              iframeClass: 'yj-eap-basic-iframe',
              initialSubject: edit?.title,
              initialBodyHtml: edit?.contentHtml,
            ),
    );
  }
}
