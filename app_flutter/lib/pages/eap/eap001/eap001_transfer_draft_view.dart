// 양수도·명의변경 품의 — Daou 양식 HTML 그대로 작성 후 기안.

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
import 'package:app_flutter/pages/eap/eap001/eap001_transfer_form_data.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_transfer_html_form.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

Future<void> openEapTransferDraft(BuildContext context, {String? formCode}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => EapTransferDraftView(initialFormCode: formCode),
    ),
  ).whenComplete(removeEapTransferHtmlOverlays);
}

class EapTransferDraftView extends ConsumerStatefulWidget {
  const EapTransferDraftView({super.key, this.initialFormCode});

  final String? initialFormCode;

  @override
  ConsumerState<EapTransferDraftView> createState() =>
      _EapTransferDraftViewState();
}

class _EapTransferDraftViewState extends ConsumerState<EapTransferDraftView> {
  late final String _formCode;
  final _htmlCtrl = EapTransferHtmlFormController();
  bool _submitting = false;

  /// 라우트 전환 후 HTML 호스트 마운트 (웹 EngineFlutterView/hot-restart race 완화)
  bool _hostReady = false;

  @override
  void initState() {
    super.initState();
    _formCode = widget.initialFormCode?.trim().isNotEmpty == true
        ? widget.initialFormCode!.trim()
        : kEapTransferFormCode;
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
      if (exported == null || exported.fields.isEmpty) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '작성 값을 가져오지 못했습니다. 웹(Chrome)에서 HTML 양식을 연 뒤 다시 시도해 주세요.',
            ),
          ),
        );
        return;
      }

      // 화면: HTML 양식으로 작성
      // 전송: API content → 다우 「본문 내용」 슬롯에 표시
      // (다우 양식의 일반「편집기/input」칸을 필드별로 채우는 방식이 아님)
      final formData = EapTransferFormData.fromHtmlFields(exported.fields);

      // 다우가 받아내는 본문은 안정적인 표 HTML을 우선한다.
      // (iframe 전체 HTML 은 style/input 이 많아 본문 슬롯에 안 그려지는 사례가 있음)
      final iframeHtml = exported.html.trim();
      var contentHtml = formData.buildContentHtml();
      if (contentHtml.trim().isEmpty && iframeHtml.isNotEmpty) {
        contentHtml = iframeHtml;
      }
      if (contentHtml.trim().isEmpty) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기안할 본문이 비어 있습니다. 필수 항목을 입력해 주세요.')),
        );
        return;
      }

      final title = () {
        final t = exported.title.trim();
        if (t.isNotEmpty) return t;
        return formData.buildTitle();
      }();

      if (kDebugMode) {
        final filled = exported.fields.entries
            .where((e) => e.value.trim().isNotEmpty)
            .length;
        debugPrint(
          '[EAP draft] title="$title" fields=${exported.fields.length} '
          'filled=$filled contentLen=${contentHtml.length} '
          'iframeLen=${iframeHtml.length} store=${formData.storeName} '
          'head=${contentHtml.substring(0, contentHtml.length > 80 ? 80 : contentHtml.length)}',
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
                    ? '다우오피스 기안 화면을 열었습니다.'
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '양수도 / 명의변경 품의서 ($_formCode)',
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
                  : const Text('다우 기안'),
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
            ),
    );
  }
}
