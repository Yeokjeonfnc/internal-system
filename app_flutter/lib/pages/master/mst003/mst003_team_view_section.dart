import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/active/act004/act004_api.dart';
import 'package:app_flutter/pages/active/act004/act004_model.dart';

/// 메뉴권한(mst003) — 활동 계획 행 아래 펼치는 팀 캘린더 열람 권한 패널.
class Mst003TeamViewPanel extends StatefulWidget {
  const Mst003TeamViewPanel({
    super.key,
    required this.userIdx,
    required this.userName,
  });

  final int userIdx;
  final String userName;

  @override
  State<Mst003TeamViewPanel> createState() => _Mst003TeamViewPanelState();
}

class _Mst003TeamViewPanelState extends State<Mst003TeamViewPanel> {
  final _api = Act004Api();
  List<TeamViewPermissionRow> _rows = [];
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant Mst003TeamViewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userIdx != widget.userIdx) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _api.fetchTeamViewPermissions(widget.userIdx);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final grantedBy = provider.Provider.of<AuthProvider>(
      context,
      listen: false,
    ).userId;
    setState(() => _saving = true);
    final ok = await _api.saveTeamViewPermissions(
      userIdx: widget.userIdx,
      grantedBy: grantedBy,
      rows: _rows,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '팀 캘린더 열람 권한이 저장되었습니다.' : '저장에 실패했습니다.')),
    );
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '팀 캘린더 열람 권한',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.userName} 님이 선택한 팀(부서) 소속 사원의 활동 계획을 조회할 수 있습니다.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              ..._rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    row.targetDeptNm,
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: row.canView,
                  activeColor: AppTheme.accentRed,
                  onChanged: (v) {
                    setState(() {
                      _rows[index] = row.copyWith(canView: v ?? false);
                    });
                  },
                );
              }),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton(
                  onPressed: _saving || _loading ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('팀 권한 저장'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
