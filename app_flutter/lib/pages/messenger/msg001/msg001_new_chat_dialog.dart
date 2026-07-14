// 새 대화 시작 다이얼로그 — 동료 선택(1:1/그룹) 후 방 생성.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/chat/chat_model.dart';
import 'package:app_flutter/core/chat/chat_providers.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/messenger/msg001/msg001_widgets.dart';

/// 다이얼로그를 띄우고 생성된 방을 반환한다 (취소 시 null).
Future<ChatRoom?> showNewChatDialog(BuildContext context) {
  return showDialog<ChatRoom>(
    context: context,
    builder: (_) => const _NewChatDialog(),
  );
}

class _NewChatDialog extends ConsumerStatefulWidget {
  const _NewChatDialog();

  @override
  ConsumerState<_NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends ConsumerState<_NewChatDialog> {
  final _selected = <String>{};
  final _groupTitle = TextEditingController();
  final _search = TextEditingController();
  String _query = '';
  bool _creating = false;

  @override
  void dispose() {
    _groupTitle.dispose();
    _search.dispose();
    super.dispose();
  }

  /// 이름·부서로 동료를 거른다(공백 무시, 대소문자 무시).
  List<ChatMember> _filtered(List<ChatMember> directory) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return directory;
    return directory
        .where((m) =>
            m.userName.toLowerCase().contains(q) ||
            m.deptNm.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _create(List<ChatMember> directory) async {
    final members =
        directory.where((m) => _selected.contains(m.userId)).toList();
    if (members.isEmpty) return;
    setState(() => _creating = true);
    final title = members.length > 1 ? _groupTitle.text.trim() : null;
    final room = await ref
        .read(chatServiceProvider)
        .createRoom(members: members, title: title);
    if (mounted) Navigator.of(context).pop(room);
  }

  @override
  Widget build(BuildContext context) {
    final dirAsync = ref.watch(chatDirectoryProvider);
    final isGroup = _selected.length > 1;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                '새 대화',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF212529),
                ),
              ),
            ),
            if (isGroup)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _groupTitle,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: '그룹 이름 (선택)',
                    hintText: '예: 가맹점 오픈 TF',
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '사원 이름·부서 검색',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: '지우기',
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: dirAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('불러오기 실패: $e')),
                data: (directory) {
                  if (directory.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('대화 가능한 동료가 없습니다'),
                      ),
                    );
                  }
                  final filtered = _filtered(directory);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('검색 결과가 없습니다'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final m = filtered[i];
                      final checked = _selected.contains(m.userId);
                      return CheckboxListTile(
                        value: checked,
                        activeColor: AppTheme.accentRed,
                        controlAffinity: ListTileControlAffinity.trailing,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(m.userId);
                          } else {
                            _selected.remove(m.userId);
                          }
                        }),
                        secondary: ChatAvatar(name: m.userName, size: 40),
                        title: Text(
                          m.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: m.deptNm.isEmpty ? null : Text(m.deptNm),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _creating
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (_selected.isEmpty || _creating)
                        ? null
                        : () => _create(dirAsync.valueOrNull ?? const []),
                    icon: _creating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(
                      isGroup ? '그룹 대화 시작' : '대화 시작',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
