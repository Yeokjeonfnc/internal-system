// 받는사람 입력 — 자동완성 + 주소 색상 구분.
//
// 두 가지를 노린다.
//  1) **부서를 고르면 부서원 전체가 들어간다.** 72명 조직에서 가장 자주 쓰는
//     동작이라, 부서 후보 하나를 누르면 소속 주소가 한꺼번에 칩으로 펼쳐진다.
//  2) **주소를 색으로 구분한다**(다우오피스 방식). 사내=파랑, 외부=주황,
//     형식오류=빨강. 외부로 잘못 나가는 메일을 보내기 전에 눈으로 잡는 것이
//     목적이다 — 확인 팝업만으로는 주소를 한 줄씩 읽지 않는다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_provider.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_widgets.dart';

/// 아주 느슨한 형식 검사. 진짜 검증은 서버(`@Email`)가 하고, 여기서는 오타로
/// 400 을 맞고 나서야 알게 되는 일을 줄이는 것이 목적이다.
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidMailAddress(String v) => _emailPattern.hasMatch(v.trim());

/// 사내 도메인 — 이 도메인이면 "내부"로 본다.
///
/// 하드코딩이 마음에 걸리지만, 대안(서버에서 내려받기)은 아직 API 가 없다.
/// 목록을 여기 한 곳에 모아 두고, 나중에 `/mail/preferences` 가 도메인을
/// 내려주면 이 상수만 갈아 끼우면 되게 해 둔다.
const List<String> kInternalMailDomains = <String>['yeokjeon.com'];

/// 주소 한 개의 판정 결과.
enum MailAddressKind { internal, external, invalid }

MailAddressKind classifyMailAddress(String raw) {
  final v = raw.trim();
  if (!isValidMailAddress(v)) return MailAddressKind.invalid;
  final at = v.lastIndexOf('@');
  final domain = v.substring(at + 1).toLowerCase();
  for (final d in kInternalMailDomains) {
    if (domain == d.toLowerCase() || domain.endsWith('.${d.toLowerCase()}')) {
      return MailAddressKind.internal;
    }
  }
  return MailAddressKind.external;
}

extension MailAddressKindX on MailAddressKind {
  Color get foreground => switch (this) {
    MailAddressKind.internal => const Color(0xFF1D4ED8),
    MailAddressKind.external => const Color(0xFFB45309),
    MailAddressKind.invalid => AppTheme.accentRed,
  };

  Color get background => switch (this) {
    MailAddressKind.internal => const Color(0xFFEFF6FF),
    MailAddressKind.external => const Color(0xFFFFF7E8),
    MailAddressKind.invalid => const Color(0xFFFDEEEE),
  };

  Color get border => switch (this) {
    MailAddressKind.internal => const Color(0xFFD3E2F7),
    MailAddressKind.external => const Color(0xFFF0E0C0),
    MailAddressKind.invalid => const Color(0xFFF3D3D3),
  };

  String get label => switch (this) {
    MailAddressKind.internal => '사내',
    MailAddressKind.external => '외부',
    MailAddressKind.invalid => '형식오류',
  };

  IconData get icon => switch (this) {
    MailAddressKind.internal => Icons.badge_outlined,
    MailAddressKind.external => Icons.public,
    MailAddressKind.invalid => Icons.error_outline,
  };
}

/// `a@b.com, c@d.com; e@f.com` 처럼 섞여 들어와도 주소 목록으로 만든다.
List<String> parseMailAddressInput(String raw) {
  return raw
      .split(RegExp(r'[,;\s]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// 칩 목록 + 자동완성 입력을 합친 수신자 필드.
class MailRecipientField extends ConsumerStatefulWidget {
  const MailRecipientField({
    super.key,
    required this.label,
    required this.addresses,
    required this.onChanged,
    this.enabled = true,
    this.hint = '이름·부서·메일 주소로 검색 (쉼표로 여러 명)',
  });

  final String label;
  final List<String> addresses;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;
  final String hint;

  @override
  ConsumerState<MailRecipientField> createState() => _MailRecipientFieldState();
}

class _MailRecipientFieldState extends ConsumerState<MailRecipientField> {
  final _inputCtrl = TextEditingController();
  final _focus = FocusNode();

  /// 실제로 서버에 물어볼 검색어. 타이핑마다 바로 바꾸지 않고 디바운스한다.
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _inputCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onInputChanged(String v) {
    // 쉼표·세미콜론을 치면 그 자리에서 주소를 확정한다(메일 클라이언트 관례).
    if (v.endsWith(',') || v.endsWith(';')) {
      _commitTyped();
      return;
    }
    _debounce?.cancel();
    // 250ms — 한글은 조합 중에도 onChanged 가 계속 불려서, 디바운스가 없으면
    // "김철수" 한 번 치는 동안 서버를 예닐곱 번 때린다.
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = v.trim());
    });
  }

  /// 지금 입력창에 있는 글자를 주소로 확정한다.
  void _commitTyped() {
    final raw = _inputCtrl.text;
    final parsed = parseMailAddressInput(raw);
    if (parsed.isEmpty) {
      _inputCtrl.clear();
      setState(() => _query = '');
      return;
    }
    _addAll(parsed);
  }

  void _addAll(Iterable<String> emails) {
    final next = List<String>.of(widget.addresses);
    for (final e in emails) {
      final v = e.trim();
      // 중복은 조용히 건너뛴다. 같은 사람에게 두 번 보내는 일을 막는다.
      if (v.isEmpty) continue;
      if (next.any((x) => x.toLowerCase() == v.toLowerCase())) continue;
      next.add(v);
    }
    _inputCtrl.clear();
    setState(() => _query = '');
    widget.onChanged(next);
  }

  void _remove(String email) {
    final next = List<String>.of(widget.addresses)
      ..removeWhere((e) => e.toLowerCase() == email.toLowerCase());
    widget.onChanged(next);
  }

  void _pick(MailRecipient r) {
    final emails = r.emails;
    if (emails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.isDept
                ? '「${r.name}」 부서에 메일 주소가 등록된 사원이 없습니다.'
                : '「${r.name}」 의 메일 주소가 없습니다.',
          ),
        ),
      );
      return;
    }
    _addAll(emails);
    // 부서를 넣었을 때는 몇 명이 들어갔는지 알려 준다 — 조용히 20명이
    // 추가되면 사용자가 눈치채지 못한 채 발송할 수 있다.
    if (r.isDept) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${r.name}」 부서원 ${emails.length}명을 추가했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 78,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _chipBox(),
                    if (_query.length >= 2 && widget.enabled) _suggestions(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 빈 입력칸에서 백스페이스를 누르면 마지막 주소를 지운다.
  ///
  /// 메일 클라이언트의 보편적인 동작이라 사용자가 반사적으로 누른다. 이게 없으면
  /// 칩의 작은 x 를 정확히 겨냥해야 해서, 주소 하나 고치는 데도 마우스를 써야 했다.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    // 입력 중인 글자가 있으면 평소대로 그 글자를 지운다.
    if (_inputCtrl.text.isNotEmpty) return KeyEventResult.ignored;
    if (widget.addresses.isEmpty) return KeyEventResult.ignored;
    _remove(widget.addresses.last);
    return KeyEventResult.handled;
  }

  Widget _chipBox() {
    return GestureDetector(
      // 상자 아무 데나 눌러도 입력칸에 포커스가 간다.
      //
      // 예전에는 입력칸이 최대 460px 로 잘려 있어서, 넓은 화면에서 상자 오른쪽을
      // 누르면 아무 일도 일어나지 않았다. 보이는 영역과 눌리는 영역이 달랐던 것이다.
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? () => _focus.requestFocus() : null,
      child: Container(
        decoration: BoxDecoration(
          color: widget.enabled
              ? AppTheme.cardBackground
              : AppTheme.chipNeutralBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.inputBorder),
        ),
        // 세로 여백을 줄였다. 칩 자체에 높이가 있어 위아래 6px 은 과했고,
        // 한 줄 입력에 비해 상자가 지나치게 두꺼워 보였다.
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final email in widget.addresses)
              MailAddressChip(
                email: email,
                onRemove: widget.enabled ? () => _remove(email) : null,
              ),
            // 입력창은 남은 폭을 쓰되 너무 좁아지지 않게 최소 폭을 준다.
            // 상한을 두지 않는다 — 상한이 있으면 그 바깥이 죽은 영역이 된다.
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200),
              child: Focus(
                onKeyEvent: _onKey,
                child: TextField(
                  controller: _inputCtrl,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  style: const TextStyle(fontSize: 14),
                  onChanged: _onInputChanged,
                  onSubmitted: (_) => _commitTyped(),
                  // 포커스가 떠날 때 입력 중이던 글자를 버리지 않는다 —
                  // 주소를 다 쳐 놓고 제목으로 넘어갔더니 사라지는 일이 없어야 한다.
                  onTapOutside: (_) {
                    if (_inputCtrl.text.trim().isNotEmpty) _commitTyped();
                  },
                  decoration: InputDecoration(
                    hintText: widget.addresses.isEmpty ? widget.hint : '',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPlaceholder,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestions() {
    final async = ref.watch(mailRecipientSearchProvider(_query));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 6, left: 4),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      // 자동완성이 안 되더라도 **주소를 직접 칠 수 있어야 한다.** 그래서 실패는
      // 화면을 막지 않고 한 줄 안내로만 알린다(원인은 그대로 보여 준다).
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          mailIsFeatureUnavailable(e)
              ? '주소 자동완성은 준비 중입니다. 메일 주소를 직접 입력해 주세요.'
              : '주소 검색 실패: '
                    '${formatApiUserMessage(e, fallback: '잠시 후 다시 시도해 주세요.')}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFB45309),
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 6, left: 2),
            child: Text(
              '검색 결과가 없습니다. 메일 주소를 직접 입력할 수 있습니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.only(top: 6),
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.hairline),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final r = rows[i];
              return InkWell(
                onTap: () => _pick(r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        r.isDept ? Icons.groups_outlined : Icons.person_outline,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                      ),
                      if (r.kindLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.chipNeutralBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            r.kindLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// 주소 칩 하나 — 사내/외부/형식오류를 색으로 구분한다.
class MailAddressChip extends StatelessWidget {
  const MailAddressChip({super.key, required this.email, this.onRemove});

  final String email;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final kind = classifyMailAddress(email);
    return Tooltip(
      message: '${kind.label} 주소',
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        decoration: BoxDecoration(
          color: kind.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: kind.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(kind.icon, size: 13, color: kind.foreground),
            const SizedBox(width: 5),
            Text(
              email,
              style: TextStyle(
                fontSize: 12.5,
                color: kind.foreground,
                fontWeight: FontWeight.w500,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
            if (onRemove != null)
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(Icons.close, size: 13, color: kind.foreground),
                ),
              )
            else
              const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// 주소 색상 범례 — 처음 보는 사람이 색의 뜻을 알 수 있게.
class MailAddressLegend extends StatelessWidget {
  const MailAddressLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 78, top: 4),
      child: Wrap(
        spacing: 12,
        children: [
          for (final k in MailAddressKind.values)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: k.foreground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  k.label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textMuted,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
