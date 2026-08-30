// 자체 전자결재 기안하기 — 서식 선택, 결재라인(결재/합의/참조/열람), 저장·임시저장.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_approval_line.dart';
import 'package:app_flutter/pages/eap/eap001/eap_form_builder.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_compose_approval_panel.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_compose_lines.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_html_editor.dart';
import 'package:app_flutter/core/web/iframe_pointer_gate.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_new_draft_sheet.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_quill.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001ComposeView extends ConsumerStatefulWidget {
  const Eap001ComposeView({super.key, this.formCode, this.resumeDocId});

  final String? formCode;
  final String? resumeDocId;

  @override
  ConsumerState<Eap001ComposeView> createState() => _Eap001ComposeViewState();
}

class _Eap001ComposeViewState extends ConsumerState<Eap001ComposeView> {
  final _titleCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final _htmlCtrl = EapHtmlEditorController();
  final _fillCtrl = EapFormFillController();

  final _lines = EapComposeLineSet();

  String? _loadedFormCode;
  bool _useFormFill = false;
  bool _bodyHostsReady = false;
  bool _saving = false;
  bool _approvalExpanded = false;
  int? _mappingId;
  String? _resumeHtml;
  String? _resumeFormCode;
  String get _effectiveFormCode {
    final q = (widget.formCode ?? '').trim();
    if (q.isNotEmpty) return q;
    return (_resumeFormCode ?? '').trim();
  }
  bool _resumeLoading = false;
  String? _resumeError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((widget.resumeDocId ?? '').trim().isNotEmpty) {
        _loadResume();
      } else {
        _syncFormFromProvider();
      }
    });
  }

  @override
  void didUpdateWidget(covariant Eap001ComposeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCode = oldWidget.formCode?.trim() ?? '';
    final newCode = widget.formCode?.trim() ?? '';
    final oldDoc = oldWidget.resumeDocId?.trim() ?? '';
    final newDoc = widget.resumeDocId?.trim() ?? '';
    if (oldCode != newCode || oldDoc != newDoc) {
      setState(() {
        _loadedFormCode = null;
        _bodyHostsReady = false;
        _resumeHtml = null;
        _resumeFormCode = null;
        _resumeError = null;
        _mappingId = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (newDoc.isNotEmpty) {
          _loadResume();
        } else {
          _syncFormFromProvider();
        }
      });
    }
  }

  void _syncFormFromProvider() {
    if (!mounted) return;
    if ((widget.resumeDocId ?? '').trim().isNotEmpty &&
        _resumeHtml == null &&
        _resumeError == null) {
      return;
    }
    final formCode = _effectiveFormCode;
    if (formCode.isEmpty) return;
    final form = ref.read(eapFormDetailProvider(formCode)).valueOrNull;
    if (form != null && form.formCode != _loadedFormCode) {
      _applyForm(form);
    }
  }

  Future<void> _loadResume() async {
    final docId = widget.resumeDocId?.trim() ?? '';
    if (docId.isEmpty) return;
    setState(() {
      _resumeLoading = true;
      _resumeError = null;
    });
    try {
      final doc = await ref.read(eapApiProvider).getDocument(docId);
      if (!mounted) return;
      if (doc == null) {
        setState(() {
          _resumeLoading = false;
          _resumeError = '문서를 찾을 수 없습니다.';
        });
        return;
      }
      if (!doc.isResumable) {
        context.go(EapRoutes.documentDetail(doc.docId));
        return;
      }
      _mappingId = doc.mappingId;
      _titleCtrl.text = doc.title;
      _resumeHtml = doc.contentHtml;
      _resumeFormCode = doc.formCode.trim();
      _lines.loadFromMembers(doc.lines);
      setState(() => _resumeLoading = false);
      final formCode = (widget.formCode ?? '').trim().isNotEmpty
          ? widget.formCode!.trim()
          : doc.formCode.trim();
      if (formCode.isEmpty) {
        _applyResumeBodyOnly();
        return;
      }
      final form = ref.read(eapFormDetailProvider(formCode)).valueOrNull;
      if (form != null) {
        _applyForm(form);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resumeLoading = false;
        _resumeError = formatApiUserMessage(e, fallback: '문서를 불러오지 못했습니다.');
      });
    }
  }

  void _applyResumeBodyOnly() {
    final html = _resumeHtml ?? '';
    final useFill = eapHtmlHasFormFields(html);
    if (useFill) {
      _fillCtrl.primeHtml(html);
    } else {
      _htmlCtrl.primeHtml(html);
    }
    setState(() {
      _useFormFill = useFill;
      _bodyHostsReady = true;
    });
  }

  Widget _bodyMessage(String message, [Object? error]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBodyHost() {
    if (_resumeLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_resumeError != null) {
      return _bodyMessage(_resumeError!);
    }
    final formCode = (widget.formCode ?? '').trim().isNotEmpty
        ? widget.formCode!.trim()
        : (_resumeFormCode ?? '');

    if (formCode.isEmpty && !_bodyHostsReady) {
      return Center(
        child: Text(
          '서식을 선택하면 본문이 여기에 로드됩니다.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      );
    }

    if (formCode.isNotEmpty && !_bodyHostsReady) {
      // 서식 도착 여부를 **직접 구독**해서 판단한다.
      //
      // 예전에는 `_bodyHostsReady` 플래그 하나에만 의존했는데, 그 플래그를 켜는
      // 경로가 ① build 의 `ref.listen`(값이 **바뀔 때만** 울린다) 과
      // ② initState 의 1회성 `ref.read`(그 시점엔 아직 로딩이라 항상 null) 뿐이었다.
      // 그래서 값이 "이미 도착해 있는" 재진입 상황에서는 ①도 ②도 적용하지 못해
      // **스피너가 영영 멈추지 않았다.** (실측: /eap/forms/{code} 는 200 으로
      // 잘 내려오는데 화면은 계속 로딩이었다.)
      //
      // 여기서 watch 하면 값이 언제 도착하든 그 프레임에 반영되고, 실패·없음도
      // 화면에 드러난다. 실패를 표시하지 않으면 사용자에겐 그냥 멈춘 화면으로 보인다.
      final async = ref.watch(eapFormDetailProvider(formCode));

      // 값이 이미 캐시에 있어 `ref.listen` 이 울리지 않는 재진입 경로를 여기서 메운다.
      // (적용은 setState 를 부르므로 build 가 끝난 뒤에 한다.)
      final cached = async.valueOrNull;
      if (cached != null && cached.formCode != _loadedFormCode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _applyForm(cached);
        });
      }

      if (async.hasError) {
        return _bodyMessage('서식을 불러오지 못했습니다.', async.error);
      }
      if (async.hasValue && async.valueOrNull == null) {
        return _bodyMessage('서식 「$formCode」 을(를) 찾을 수 없습니다.');
      }
      return const Center(child: CircularProgressIndicator());
    }

    // 서식 유형마다 iframe 하나만 띄운다. IndexedStack 으로 두 개를 동시에 만들면
    // 숨겨진 쪽도 initState·postMessage 를 타서 불필요한 크래시·로드를 유발한다.
    if (_useFormFill) {
      return EapFormFillHost(
        key: ValueKey('eap-compose-fill-$_loadedFormCode'),
        controller: _fillCtrl,
        onPickField: _pickFormField,
      );
    }
    return EapHtmlEditorHost(
      key: ValueKey('eap-compose-html-$_loadedFormCode'),
      controller: _htmlCtrl,
      placeholder: '서식을 선택하면 본문이 여기에 로드됩니다.',
      editorMode: 'compose',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _applyForm(EapFormConfig form) {
    if (_loadedFormCode == form.formCode) return;
    final html = (_resumeHtml != null && _resumeHtml!.trim().isNotEmpty)
        ? _resumeHtml!
        : eapStoredBodyToHtml(form.contentHtml, form.contentDelta);
    final useFill = eapHtmlHasFormFields(html);
    // iframe 이 attach 되기 전에 본문·context 를 채워 둔다 — onLoad 동기화가 빈 HTML 을
    // 보내는 레이스를 막는다.
    if (useFill) {
      _fillCtrl.primeHtml(html);
    } else {
      _htmlCtrl.primeHtml(html);
    }
    setState(() {
      _loadedFormCode = form.formCode;
      _useFormFill = useFill;
      _bodyHostsReady = true;
      if (_titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = form.formName;
      }
    });
    if (useFill) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final auth = provider.Provider.of<AuthProvider>(context, listen: false);
        final ctx = _fillContext(auth);
        _fillCtrl.primeContext(ctx);
        _fillCtrl.setContext(ctx);
      });
    }
  }

  Map<String, String> _fillContext(AuthProvider auth) {
    final today = DateTime.now();
    final dateLabel =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final p = auth.profile;
    final dept = p?.deptNm.trim() ?? '';
    return {
      'drafter': auth.userName.isEmpty ? auth.userId : auth.userName,
      'dept': dept.isEmpty ? '-' : dept,
      'email': p?.email.trim().isNotEmpty == true ? p!.email.trim() : '-',
      'position': p?.positionNm.trim().isNotEmpty == true
          ? p!.positionNm.trim()
          : '-',
      'empno': auth.userId,
      'contact': p?.userPhone.trim().isNotEmpty == true
          ? p!.userPhone.trim()
          : '-',
      'date': dateLabel,
      'completeDate': '',
      'docNo': '(결재 후 채번)',
    };
  }

  InputDecoration get _dec => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: FormStylePalette.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: FormStylePalette.accent, width: 1.4),
    ),
  );

  Future<String> _documentBodyHtml() async {
    final body =
        (_useFormFill ? await _fillCtrl.getHtml() : await _htmlCtrl.getHtml())
            .trim();
    final remark = _remarkCtrl.text.trim();
    if (remark.isEmpty) return body;
    return '$body<p style="margin-top:16px;"><b>결재 특이사항</b><br/>${_esc(remark)}</p>';
  }

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  List<EapLineMember> _allLines() {
    final auth = provider.Provider.of<AuthProvider>(context, listen: false);
    return _lines.allLines(auth);
  }

  Future<String?> _pickFormField(String pickType) async {
    // iframe → Flutter 포커스 전환 직후 게이트·다이얼로그는 [EapFormFillHost] 가 처리한다.
    final r = await showActivityApprovalLineDialog(
      context,
      requestFocus: false,
    );
    if (!mounted || r == null) return null;
    // 고른 사람을 모두 반영한다.
    //
    // 예전에는 반복문 첫 회차에서 곧바로 return 해서, 사용자가 여러 명을
    // 선택해도 **첫 사람만 들어가고 나머지는 소리 없이 버려졌다.**
    final picked = <String>[];
    for (var i = 0; i < r.names.length; i++) {
      final nm = r.names[i].trim();
      if (nm.isEmpty) continue;
      final title = i < r.titles.length ? r.titles[i].trim() : '';
      picked.add(title.isEmpty ? nm : '$title $nm');
    }
    if (picked.isEmpty) return null;
    return picked.join(', ');
  }

  Future<void> _pickLine(EapComposeLinePick pick) async {
    await IframePointerGate.whileBlocked(context, () async {
      final auth = provider.Provider.of<AuthProvider>(context, listen: false);
      final r = await showActivityApprovalLineDialog(
        context,
        requestFocus: false,
        initialNames: pick.names,
        initialTitles: pick.titles,
        initialUserIds: pick.userIds,
        blockedKeys: _lines.blockedKeysFor(pick, auth),
        blockedMessage: identical(pick, _lines.approvers)
            ? '기안자는 결재·합의·참조·열람에 지정할 수 없습니다.'
            : '기안자 또는 결재·합의에 지정된 사람은 이 목록에 넣을 수 없습니다.',
      );
      if (!mounted || r == null) return;
      var dropped = 0;
      setState(() {
        pick.assignFrom(r);
        dropped = _lines.applyExclusiveRoles(pick);
        dropped += _lines.purgeDrafter(auth);
      });
      if (dropped > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '기안자는 결재·합의·참조·열람에 넣을 수 없으며, '
              '한 사람은 한 역할만 지정할 수 있습니다.',
            ),
          ),
        );
      }
    });
  }

  Future<void> _submit(String status) async {
    final formCode = _effectiveFormCode;
    final title = _titleCtrl.text.trim();
    if (formCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('작성할 서식을 먼저 선택해 주세요.')));
      return;
    }
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목을 입력해 주세요.')));
      return;
    }
    if (_lines.hasMemberWithoutUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결재선에 사원 번호가 없는 사람이 있습니다. 다시 지정해 주세요.')),
      );
      return;
    }
    if (status != 'TEMPSAVE' &&
        _lines.approvers.toMembers('APPROVER').isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('결재자를 한 명 이상 지정해 주세요.')));
      return;
    }
    if (_useFormFill && status != 'TEMPSAVE') {
      final v = await _fillCtrl.validate();
      // 검증은 iframe 왕복이라 시간이 걸린다. 그 사이 사용자가 화면을 떠났으면
      // 아래의 context 사용과 setState 가 모두 죽은 위젯을 건드리게 된다.
      // (예전에는 `!v.ok` 인 경우에만 mounted 를 봐서, 통과했을 때가 무방비였다.)
      if (!mounted) return;
      if (!v.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('필수 항목을 입력해 주세요: ${v.errors.join(', ')}')),
        );
        return;
      }
    }
    final auth = provider.Provider.of<AuthProvider>(context, listen: false);
    _lines.purgeDrafter(auth);
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(eapApiProvider)
          .draft(
            EapDraftRequest(
              formCode: formCode,
              title: title,
              draftUserId: auth.userId,
              contentHtml: await _documentBodyHtml(),
              status: status,
              mappingId: _mappingId,
              lines: _allLines(),
            ),
          );
      if (!mounted) return;
      if (result.mappingId > 0) {
        _mappingId = result.mappingId;
      }
      ref.invalidate(eapDocumentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.trim().isEmpty
                ? (status == 'TEMPSAVE' ? '임시 저장했습니다.' : '상신했습니다.')
                : result.message,
          ),
        ),
      );
      if (status == 'TEMPSAVE') {
        final docId = result.documentId.trim();
        final currentDoc = (widget.resumeDocId ?? '').trim();
        if (docId.isNotEmpty && docId != currentDoc) {
          context.go(
            EapRoutes.composeResume(formCode: formCode, docId: docId),
          );
        }
        return;
      }
      context.go(EapRoutes.sent);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            formatApiUserMessage(e, fallback: '저장에 실패했습니다.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildFormSelectRow(String formCode) {
    if (formCode.isEmpty) {
      return OutlinedButton.icon(
        onPressed: () => showEapNewDraftSheet(context),
        icon: const Icon(Icons.description_outlined),
        label: const Text('서식 선택'),
      );
    }
    return Consumer(
      builder: (context, ref, _) {
        final async = ref.watch(eapFormDetailProvider(formCode));
        final name = async.valueOrNull?.formName ?? formCode;
        return Row(
          children: [
            Expanded(
              child: Text(
                '서식 — $name',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => showEapNewDraftSheet(context),
              child: const Text('서식 변경'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = provider.Provider.of<AuthProvider>(context);
    final today = DateTime.now();
    final dateLabel =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final formCode = _effectiveFormCode;

    if (formCode.isNotEmpty) {
      ref.listen(eapFormDetailProvider(formCode), (prev, next) {
        final form = next.valueOrNull;
        if (form != null && form.formCode != _loadedFormCode && mounted) {
          _applyForm(form);
        }
      });
    }

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Row(
              children: [
                const Text(
                  '기안하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                const Spacer(),
                if (provider.Provider.of<AuthProvider>(
                  context,
                ).canViewMenu(kMenuMst007))
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => context.go(EapRoutes.forms),
                    child: const Text('서식 관리'),
                  ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _saving ? null : () => _submit('TEMPSAVE'),
                  child: const Text('임시저장'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : () => _submit('INPROGRESS'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_saving ? '상신 중...' : '상신'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                  border: Border.all(color: AppTheme.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFormSelectRow(formCode),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _titleCtrl,
                            decoration: _dec.copyWith(
                              labelText: '제목 *',
                              hintText: '기안 제목을 입력하세요',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 결재 정보 패널의 높이에 상한을 둔다.
                    //
                    // 펼친 결재정보표는 높이가 ~366px 로 고정인데, 본문(Expanded)과
                    // 같은 Column 의 형제라 그 높이를 **본문에서 그대로 빼앗는다.**
                    // 그래서 화면이 낮은 노트북에서는 '결재 정보' 를 한 번 누르는
                    // 것만으로 본문 높이가 0 이 되어 문서가 통째로 사라져 보였다
                    // (그 자리에 남는 회색 띠가 "본문이 회색이 됐다" 로 보인다).
                    //
                    // 패널이 가져갈 수 있는 높이를 창 높이의 38% 로 묶고, 넘치는
                    // 만큼은 패널 안에서 스크롤한다. 본문은 항상 나머지를 갖는다.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.38,
                      ),
                      child: SingleChildScrollView(
                        child: EapComposeApprovalPanel(
                          lines: _lines,
                          auth: auth,
                          dateLabel: dateLabel,
                          expanded: _approvalExpanded,
                          onToggleExpanded: () => setState(
                            () => _approvalExpanded = !_approvalExpanded,
                          ),
                          onPickApprovers: () => _pickLine(_lines.approvers),
                          onPickAgreers: () => _pickLine(_lines.agreers),
                          onPickCcs: () => _pickLine(_lines.ccs),
                          onPickViewers: () => _pickLine(_lines.viewers),
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxHeight < 72) {
                            return Center(
                              child: Text(
                                '본문 영역 높이가 부족합니다.\n결재 정보를 접거나 창 크기를 키워 주세요.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }
                          return ColoredBox(
                            color: const Color(0xFFE8E8E4),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: _buildBodyHost(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: TextField(
                        controller: _remarkCtrl,
                        maxLength: 256,
                        maxLines: 2,
                        decoration: _dec.copyWith(
                          labelText: '결재 특이사항',
                          hintText: '최대 256자',
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
