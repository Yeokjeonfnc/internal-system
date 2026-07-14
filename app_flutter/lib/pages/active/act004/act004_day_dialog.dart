import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/active/act004/act004_api.dart';
import 'package:app_flutter/pages/active/act004/act004_model.dart';
import 'package:app_flutter/pages/franchise/str001/str001_api.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';

Future<bool?> showAct004DayDialog(
  BuildContext context, {
  required int viewerUserIdx,
  required String createdBy,
  required DateTime planDate,
  required List<Act004Member> members,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _Act004DayDialog(
      viewerUserIdx: viewerUserIdx,
      createdBy: createdBy,
      planDate: planDate,
      members: members,
    ),
  );
}

class _MemberDaySection {
  const _MemberDaySection({required this.member, this.detail});

  final Act004Member member;
  final Act004DayDetail? detail;
}

class _Act004DayDialog extends StatefulWidget {
  const _Act004DayDialog({
    required this.viewerUserIdx,
    required this.createdBy,
    required this.planDate,
    required this.members,
  });

  final int viewerUserIdx;
  final String createdBy;
  final DateTime planDate;
  final List<Act004Member> members;

  @override
  State<_Act004DayDialog> createState() => _Act004DayDialogState();
}

class _Act004DayDialogState extends State<_Act004DayDialog> {
  final _api = Act004Api();
  final _storeApi = StoreApiService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _canEdit = false;
  List<_MemberDaySection> _sections = const [];
  final Set<int> _selectedStoreIdxs = {};
  final Map<int, String> _plannedLabels = {};
  List<Act004StoreItem> _completedStores = const [];
  List<Store> _allStores = [];
  List<Store> _searchResults = [];
  bool _searching = false;

  bool get _multiMember => widget.members.length > 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final members = widget.members.isNotEmpty
        ? widget.members
        : [
            Act004Member(
              userIdx: widget.viewerUserIdx,
              name: '',
              color: act004ColorForUserIdx(widget.viewerUserIdx),
              isSelf: true,
            ),
          ];

    final details = await Future.wait(
      members.map(
        (m) => _api.fetchDayDetail(
          viewerUserIdx: widget.viewerUserIdx,
          assigneeUserIdx: m.userIdx,
          planDate: widget.planDate,
        ),
      ),
    );

    Act004DayDetail? selfDetail;
    for (var i = 0; i < members.length; i++) {
      if (members[i].userIdx == widget.viewerUserIdx) {
        selfDetail = details[i];
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _sections = List.generate(
        members.length,
        (i) => _MemberDaySection(member: members[i], detail: details[i]),
      );
      _canEdit = selfDetail?.canEdit ?? false;
      _completedStores = selfDetail?.completedStores ?? const [];
      _plannedLabels
        ..clear()
        ..addAll({
          for (final e in selfDetail?.plannedStores ?? const <Act004StoreItem>[])
            e.storeIdx: e.storeLabel,
        });
      _selectedStoreIdxs
        ..clear()
        ..addAll((selfDetail?.plannedStores ?? const []).map((e) => e.storeIdx));
    });
    if (selfDetail?.canEdit ?? false) {
      await _searchStores(_searchCtrl.text);
    }
  }

  Future<void> _searchStores(String keyword) async {
    final trimmed = keyword.trim();
    if (_allStores.isNotEmpty) {
      setState(() => _searchResults = _filterStores(_allStores, trimmed));
      return;
    }
    setState(() => _searching = true);
    final results = trimmed.isEmpty
        ? await _storeApi.getAllStores()
        : await _storeApi.searchStores(name: trimmed);
    _sortStores(results);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _allStores = results;
      _searchResults = _filterStores(results, trimmed);
    });
  }

  void _sortStores(List<Store> stores) {
    stores.sort(
      (a, b) => act004StoreLabel(a.brandNm, a.storeNm)
          .compareTo(act004StoreLabel(b.brandNm, b.storeNm)),
    );
  }

  List<Store> _filterStores(List<Store> stores, String keyword) {
    if (keyword.isEmpty) return stores;
    return stores
        .where(
          (s) => act004StoreMatchesKeyword(
            keyword: keyword,
            brandNm: s.brandNm,
            storeNm: s.storeNm,
            svId: s.svId,
            svNm: s.svNm,
          ),
        )
        .toList();
  }

  String? _storeListSubtitle(Store store, bool visited) {
    final sv = act004SvLabel(svId: store.svId, svNm: store.svNm);
    final parts = <String>[];
    if (sv.isNotEmpty) parts.add('SV: $sv');
    if (visited) parts.add('이미 방문 완료');
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  void _toggleStore(int storeIdx, bool checked) {
    setState(() {
      if (checked) {
        _selectedStoreIdxs.add(storeIdx);
      } else {
        _selectedStoreIdxs.remove(storeIdx);
      }
    });
  }

  Future<void> _save() async {
    if (!_canEdit) return;
    setState(() => _saving = true);
    final ok = await _api.saveDayStores(
      viewerUserIdx: widget.viewerUserIdx,
      createdBy: widget.createdBy,
      body: ActivityPlanDaySaveBody(
        planDate: widget.planDate,
        storeIdxs: _selectedStoreIdxs.toList(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _snack('저장에 실패했습니다.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<_PlannedDisplayItem> get _plannedDisplayItems {
    final completedIds = _completedStores.map((e) => e.storeIdx).toSet();
    final items = <_PlannedDisplayItem>[];
    for (final storeIdx in _selectedStoreIdxs) {
      String? fromSearch;
      for (final s in _allStores) {
        if (s.storeIdx == storeIdx) {
          fromSearch = act004StoreLabel(s.brandNm, s.storeNm);
          break;
        }
      }
      final label = _plannedLabels[storeIdx] ?? fromSearch ?? '가맹점 #$storeIdx';
      items.add(
        _PlannedDisplayItem(
          storeIdx: storeIdx,
          label: label,
          visited: completedIds.contains(storeIdx),
        ),
      );
    }
    items.sort((a, b) => a.label.compareTo(b.label));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final title = act004DayTitle(widget.planDate);
    return AlertDialog(
      title: Text('활동 계획 — $title'),
      content: SizedBox(
        width: 560,
        height: _canEdit ? 580 : 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _multiMember ? '팀 방문 계획' : '방문 계획',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    flex: _canEdit ? 3 : 1,
                    child: _teamOverviewPanel(),
                  ),
                  if (_canEdit) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                    const Text(
                      '내 계획 편집',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(flex: 2, child: _plannedPanel()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: '가맹점명·SV ID 검색',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      onSubmitted: _searchStores,
                      onChanged: _searchStores,
                    ),
                    const SizedBox(height: 8),
                    Expanded(flex: 3, child: _searchList()),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('닫기'),
        ),
        if (_canEdit)
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
      ],
    );
  }

  Widget _teamOverviewPanel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: _sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _memberSectionTile(_sections[index]),
      ),
    );
  }

  Widget _memberSectionTile(_MemberDaySection section) {
    final member = section.member;
    final detail = section.detail;
    final planned = detail?.plannedStores ?? const [];
    final completed = detail?.completedStores ?? const [];
    final isSelf = member.userIdx == widget.viewerUserIdx;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: member.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                member.name.isEmpty ? '담당자' : member.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isSelf)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '나',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentRed,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (planned.isEmpty && completed.isEmpty)
          const Text(
            '계획·방문 없음',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          )
        else ...[
          if (planned.isNotEmpty) ...[
            const Text(
              '계획',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: planned
                  .map(
                    (e) => _storeTag(
                      e.storeLabel,
                      memberColor: member.color,
                      planned: true,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              '방문 완료',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: completed
                  .map(
                    (e) => _storeTag(
                      e.storeLabel,
                      memberColor: member.color,
                      planned: false,
                      completed: true,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ],
    );
  }

  Widget _storeTag(
    String label, {
    required Color memberColor,
    required bool planned,
    bool completed = false,
  }) {
    final bg = completed
        ? act004CompletedChipBg(memberColor)
        : memberColor.withValues(alpha: 0.18);
    final fg =
        completed ? kAct004CompletedTextColor : const Color(0xFF1E3A5F);
    final border = completed
        ? act004CompletedChipBorder(memberColor)
        : memberColor.withValues(alpha: 0.35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: completed ? 1.2 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed) ...[
            Icon(Icons.check_circle, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plannedPanel() {
    final items = _plannedDisplayItems;
    if (items.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            '선택된 가맹점이 없습니다.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: item.visited
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: item.visited
                          ? const Color(0xFF166534)
                          : const Color(0xFF1E3A5F),
                    ),
                  ),
                ),
                if (item.visited)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check, size: 16, color: Color(0xFF16A34A)),
                  ),
                IconButton(
                  tooltip: '계획에서 제거',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => _toggleStore(item.storeIdx, false),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: item.visited
                        ? const Color(0xFF166534)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _searchList() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_searchResults.isEmpty) {
      final emptyMsg = _searchCtrl.text.trim().isEmpty
          ? '등록된 가맹점이 없습니다.'
          : '검색 결과가 없습니다.';
      return Center(
        child: Text(
          emptyMsg,
          style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final store = _searchResults[index];
          final label = act004StoreLabel(store.brandNm, store.storeNm);
          final checked = _selectedStoreIdxs.contains(store.storeIdx);
          final visited =
              _completedStores.any((e) => e.storeIdx == store.storeIdx);
          final subtitle = _storeListSubtitle(store, visited);
          return CheckboxListTile(
            value: checked,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(label, style: const TextStyle(fontSize: 13)),
            subtitle: subtitle == null
                ? null
                : Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: visited
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF64748B),
                    ),
                  ),
            onChanged: (v) => _toggleStore(store.storeIdx, v ?? false),
          );
        },
      ),
    );
  }
}

class _PlannedDisplayItem {
  const _PlannedDisplayItem({
    required this.storeIdx,
    required this.label,
    required this.visited,
  });

  final int storeIdx;
  final String label;
  final bool visited;
}
