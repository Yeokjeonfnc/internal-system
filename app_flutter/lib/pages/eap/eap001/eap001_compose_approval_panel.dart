// 전자결재 기안 — 접기/펼치기 결재정보 패널.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/active/act002/act002_approval_table.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_compose_lines.dart';

class EapComposeApprovalPanel extends StatelessWidget {
  const EapComposeApprovalPanel({
    super.key,
    required this.lines,
    required this.auth,
    required this.dateLabel,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onPickApprovers,
    required this.onPickAgreers,
    required this.onPickCcs,
    required this.onPickViewers,
  });

  final EapComposeLineSet lines;
  final AuthProvider auth;
  final String dateLabel;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onPickApprovers;
  final VoidCallback onPickAgreers;
  final VoidCallback onPickCcs;
  final VoidCallback onPickViewers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggleExpanded,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                const Text(
                  '결재 정보',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lines.approvalSummary,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _LinePickButton(label: '결재', onPressed: onPickApprovers),
              _LinePickButton(label: '합의', onPressed: onPickAgreers),
              _LinePickButton(label: '참조', onPressed: onPickCcs),
              _LinePickButton(label: '열람', onPressed: onPickViewers),
            ],
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: ApprovalInfoTable(
              approvalStampSlots: lines.approvers.names,
              rankStampSlots: lines.approvers.titles,
              approvalUserIds: lines.approvers.userIds,
              apprAckUserIds: const {},
              apprAckDateByUserId: const {},
              documentWrittenAt: dateLabel,
              writerSealDate: '',
              loadedApprStatus: null,
              deptNm: () {
                final dept = auth.profile?.deptNm.trim() ?? '';
                return dept.isEmpty ? '-' : dept;
              }(),
              drafterNm: auth.userName.isEmpty ? auth.userId : auth.userName,
              onPickApproval: onPickApprovers,
              rankUnderName: true,
              approvalSlot0IsDrafter: false,
              extraNameRows: [
                ApprovalInfoNameRow(
                  label: '합의자',
                  names: lines.agreers.names,
                  titles: lines.agreers.titles,
                  userIds: lines.agreers.userIds,
                  useSeals: true,
                  onPick: onPickAgreers,
                ),
                ApprovalInfoNameRow(
                  label: '참조자',
                  names: lines.ccs.names,
                  titles: lines.ccs.titles,
                  onPick: onPickCcs,
                ),
                ApprovalInfoNameRow(
                  label: '열람자',
                  names: lines.viewers.names,
                  titles: lines.viewers.titles,
                  onPick: onPickViewers,
                ),
              ],
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

class _LinePickButton extends StatelessWidget {
  const _LinePickButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.accentRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // 글자가 아직 안 그려진 순간에도 버튼이 찌그러지지 않게 최소 크기를 준다.
        minimumSize: const Size(56, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        // textStyle 은 주지 않는다.
        //
        // FilledButton 은 style.textStyle 을 테마의 labelLarge 와 **합치지 않고
        // 통째로 교체**한다. 그래서 `TextStyle(fontSize: 12)` 하나만 주면
        // fontFamily 가 사라지고, 번들 폰트(Pretendard)로 한글을 그릴 수 없게 된다.
        // CanvasKit 은 시스템 폰트에 접근하지 못하므로 fallback 목록도 소용이 없어,
        // 결재/합의/참조/열람 칩이 빈 글자로 렌더되면서 폭까지 무너져
        // **작고 찌그러진 빨간 상자**로 보였다.
        // 크기는 아래 child 에 주면 되고, 그러면 상속된 글꼴이 그대로 유지된다.
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
