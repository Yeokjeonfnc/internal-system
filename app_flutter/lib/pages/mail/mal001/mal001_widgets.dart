// 메일(mal001) 공용 위젯 — 상태 뱃지·목록 테이블·빈 상태/오류 배너.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_api.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_filter.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';

/// API 실패를 사용자에게 보여 줄 문장으로 바꾼다.
///
/// [formatApiUserMessage] 가 `StateError`(= `Mal001ApiService` 가 던지는 서버 메시지)와
/// `DioException` 을 모두 풀어 준다. **여기서 원인을 뭉개지 않는 것이 핵심이다.**
/// 전자결재에서 실패를 "문서가 없습니다" 로 바꿔 보여 줬다가, 권한 문제인지 서버가
/// 죽은 건지 몰라 한참을 헤맨 전례가 있다.
String mailErrorMessage(Object? error, {String fallback = '메일 조회에 실패했습니다.'}) {
  if (error == null) return fallback;
  // "아직 안 만들어진 API" 는 서버 장애가 아니다. 빨간 오류로 보여 주면
  // 사용자가 관리자에게 장애 신고를 하게 된다 — 문구를 구분한다.
  if (error is MailFeatureUnavailable) return error.toString();
  return formatApiUserMessage(error, fallback: fallback);
}

/// 백엔드가 아직 준비되지 않은 기능인지.
bool mailIsFeatureUnavailable(Object? error) => error is MailFeatureUnavailable;

/// 수신확인의 한계 안내 — 목록 헤더 툴팁과 상세 도움말이 **같은 문장**을 쓴다.
///
/// 이 문구를 화면에 반드시 남기는 이유: 수신확인은 본문에 심은 1픽셀 이미지가
/// 불러와졌는지로만 판정한다. 받는 쪽이 외부 이미지를 차단하면(대부분의 웹메일이
/// 기본 차단이다) 읽어도 안 잡히고, 반대로 Gmail 이미지 프록시처럼 도착하자마자
/// 미리 받아 가는 서비스에서는 열어 보지 않아도 잡힌다. 이 한계를 말해 주지 않으면
/// "확인 안 됐으니 안 읽은 것"으로 단정해 사람 사이에 오해가 생긴다.
/// (다우오피스도 같은 한계를 FAQ 로 안내한다.)
const String kMailReadReceiptHelp =
    '수신확인은 메일 본문의 확인용 이미지가 열렸는지로만 판정합니다.\n'
    '· 받는 사람이 외부 이미지를 차단해 두면 읽어도 「미확인」으로 남습니다.\n'
    '· Gmail 처럼 이미지를 대신 미리 받아 두는 서비스에서는\n'
    '  열어 보지 않아도 「확인됨」이 될 수 있습니다.\n'
    '그래서 「확인되지 않음」은 「읽지 않음」과 다릅니다.';

/// 수신확인 옆에 붙는 물음표 — 눌러도 아무 일이 없고 올려놓으면 한계를 설명한다.
class MailReadReceiptHelpIcon extends StatelessWidget {
  const MailReadReceiptHelpIcon({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: kMailReadReceiptHelp,
      // 문장이 길어 기본 폭에서는 한 줄로 늘어나 화면 밖으로 나간다.
      preferBelow: false,
      textStyle: const TextStyle(
        fontSize: 12,
        height: 1.5,
        color: Colors.white,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Icon(
        Icons.help_outline,
        size: size,
        color: AppTheme.textPlaceholder,
      ),
    );
  }
}

/// 상세 화면에 그대로 펼쳐 두는 수신확인 한계 안내.
class MailReadReceiptNote extends StatelessWidget {
  const MailReadReceiptNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        kMailReadReceiptHelp,
        style: const TextStyle(
          fontSize: 11.5,
          height: 1.5,
          color: AppTheme.textMuted,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

/// "이 기능은 준비 중" — **오류가 아닌** 상태. 화면이 깨지는 대신 여기로 물러난다.
class MailFeaturePendingBanner extends StatelessWidget {
  const MailFeaturePendingBanner({
    super.key,
    required this.feature,
    this.detail = '',
  });

  final String feature;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.listScreenHPadding,
        0,
        AppDimensions.listScreenHPadding,
        12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0E0C0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.construction_outlined,
            size: 18,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail.isEmpty
                  ? '$feature 기능은 준비 중입니다. 서버 작업이 끝나면 자동으로 동작합니다.'
                  : '$feature 기능은 준비 중입니다.\n$detail',
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xFF8A5A0B),
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 오류 상태 하나를 알아서 배너로 바꿔 준다.
///
/// "준비 중"과 "진짜 실패"를 매 화면에서 손으로 갈라 쓰다 보면 언젠가 한쪽을
/// 빠뜨린다. 분기를 여기 한 곳에 둔다.
class MailFailureBanner extends StatelessWidget {
  const MailFailureBanner({
    super.key,
    required this.error,
    required this.feature,
    this.fallback = '요청에 실패했습니다.',
    this.onRetry,
  });

  final Object? error;
  final String feature;
  final String fallback;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (mailIsFeatureUnavailable(error)) {
      return MailFeaturePendingBanner(feature: feature);
    }
    return MailErrorBanner(
      error: error,
      fallback: fallback,
      onRetry: onRetry,
    );
  }
}

/// "표시할 것이 없다" — **오류가 아닌** 상태에만 쓴다.
class MailEmptyBanner extends StatelessWidget {
  const MailEmptyBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.listScreenHPadding,
        0,
        AppDimensions.listScreenHPadding,
        12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.chipNeutralBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mail_outline,
            size: 18,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 조회·저장 실패 — 사유를 **그대로** 보여 주고 다시 시도할 길을 남긴다.
class MailErrorBanner extends StatelessWidget {
  const MailErrorBanner({
    super.key,
    required this.error,
    this.fallback = '메일 조회에 실패했습니다.',
    this.onRetry,
  });

  final Object? error;
  final String fallback;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.listScreenHPadding,
        0,
        AppDimensions.listScreenHPadding,
        12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEEEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF3D3D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: AppTheme.accentRed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              mailErrorMessage(error, fallback: fallback),
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.accentRed,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('다시 시도'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MailLoading extends StatelessWidget {
  const MailLoading({super.key, this.height = 160});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class MailSectionTitle extends StatelessWidget {
  const MailSectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.chromeBlack,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// 상세 화면의 "라벨 : 값" 한 줄.
class MailInfoRow extends StatelessWidget {
  const MailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.selectable = true,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? '-' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textPrimary,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textPrimary,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 메일설정 화면의 카드 껍데기 — 설정 영역들이 같은 모양을 쓴다.
///
/// 설정 영역이 5개(환경설정·서명·메일함·자동분류·자동전달)로 늘어나면서
/// 파일이 갈라졌다. 껍데기를 여기 한 곳에 두지 않으면 파일마다 조금씩 다른
/// 여백·테두리를 갖게 된다.
class MailSettingsCard extends StatelessWidget {
  const MailSettingsCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.description = '',
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MailSectionTitle(title: title, trailing: trailing),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppTheme.textMuted,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// 설정 화면의 "설명 + 스위치" 한 줄.
class MailSettingSwitchRow extends StatelessWidget {
  const MailSettingSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.description = '',
  });

  final String label;
  final String description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppTheme.textMuted,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

/// 설정 화면에서 쓰는 공통 실행 래퍼의 형태.
///
/// 실패를 삼키지 않고 "준비 중"과 진짜 실패를 갈라 보여 주는 처리를 화면 하나에
/// 두고, 카드들이 그것을 넘겨받아 쓴다. (카드가 파일 여러 개로 갈라져 있어
/// 형태를 공용 파일에 둔다.)
typedef MailSettingsRunAction =
    Future<void> Function(
      Future<void> Function() action, {
      required String failFallback,
    });

/// 설정 화면에서 쓰는 "없음" 안내 한 줄.
class MailSettingsEmptyLine extends StatelessWidget {
  const MailSettingsEmptyLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textMuted,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

/// 되돌리기 어려운 설정 앞에 세우는 경고 상자(자동전달 등).
class MailWarningBox extends StatelessWidget {
  const MailWarningBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF0E0C0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 17,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Color(0xFF8A5A0B),
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 메일 상태 뱃지 — 발신은 발송 상태, 수신은 읽음/본문 수집 상태.
class MailStatusBadge extends StatelessWidget {
  const MailStatusBadge({super.key, required this.item, this.center = true});

  final MailListItem item;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final label = item.statusLabel;
    final (bg, fg) = _colorsFor(item);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: center ? Center(child: badge) : Align(
        alignment: Alignment.centerLeft,
        child: badge,
      ),
    );
  }

  static (Color, Color) _colorsFor(MailListItem item) {
    if (item.spam) {
      return (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
    }
    if (item.outbound) {
      return switch (item.sendStatus.toUpperCase()) {
        'FAILED' => (const Color(0xFFFDEEEE), AppTheme.accentRed),
        'DRAFT' => (const Color(0xFFEFF6FF), const Color(0xFF2563C7)),
        'QUEUED' => (const Color(0xFFFFF7E8), const Color(0xFFB45309)),
        _ => _outboundSentColors(item.lastStatus.toLowerCase()),
      };
    }
    if (item.bodyFailed) {
      return (const Color(0xFFFDEEEE), AppTheme.accentRed);
    }
    if (item.bodyPending) {
      return (const Color(0xFFFFF7E8), const Color(0xFFB45309));
    }
    if (!item.read) {
      return (const Color(0xFFE8F5EC), const Color(0xFF1E8E4E));
    }
    return (AppTheme.chipNeutralBackground, AppTheme.textSecondary);
  }

  static (Color, Color) _outboundSentColors(String lastStatus) {
    return switch (lastStatus) {
      'bounced' ||
      'complained' ||
      'failed' ||
      'suppressed' => (const Color(0xFFFDEEEE), AppTheme.accentRed),
      'delivery_delayed' => (const Color(0xFFFFF7E8), const Color(0xFFB45309)),
      'opened' || 'clicked' => (
        const Color(0xFFE8F5EC),
        const Color(0xFF1E8E4E),
      ),
      _ => (AppTheme.chipNeutralBackground, AppTheme.textSecondary),
    };
  }
}

/// 정렬 가능한 헤더 칸 — 누르면 그 기준으로 정렬하고, 다시 누르면 방향이 뒤집힌다.
class MailSortableHeaderCell extends StatelessWidget {
  const MailSortableHeaderCell({
    super.key,
    required this.title,
    required this.field,
    required this.sort,
    required this.onSort,
    this.center = false,
  });

  final String title;
  final MailSortField field;
  final MailSortSpec sort;
  final ValueChanged<MailSortField> onSort;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    final active = sort.field == field;
    return InkWell(
      onTap: () => onSort(field),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 3 : 5,
          vertical: compact ? 6 : 8,
        ),
        child: Row(
          mainAxisAlignment: center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact
                      ? AppDimensions.tableHeaderFontSizeCompact
                      : 13,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? AppTheme.chromeBlack
                      : AppTheme.textSecondary,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              active
                  ? (sort.ascending
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down)
                  : Icons.unfold_more,
              size: active ? 18 : 13,
              color: active ? AppTheme.accentRed : AppTheme.textPlaceholder,
            ),
          ],
        ),
      ),
    );
  }
}

/// 메일 목록 테이블. 행 더블클릭(모바일은 한 번 탭)으로 상세로 간다.
///
/// 다우오피스 기준에 맞춰 체크박스 일괄선택·중요표시(★)·첨부 클립·정렬을 얹었다.
/// 안 읽은 메일은 굵게, 읽은 메일은 흐리게 — 목록에서 가장 먼저 눈에 들어와야
/// 하는 정보가 "새로 온 게 있나"이기 때문이다.
class MailMessageTable extends StatelessWidget {
  const MailMessageTable({
    super.key,
    required this.items,
    required this.onOpen,
    this.selectedIds = const <int>{},
    this.onToggleSelect,
    this.onToggleSelectAll,
    this.onToggleStar,
    this.sort = MailSortSpec.latestFirst,
    this.onSort,
    this.showReadReceipt = false,
  });

  final List<MailListItem> items;
  final void Function(MailListItem item) onOpen;

  /// 수신확인 열을 보일지 — **보낸메일함에서만** 켠다.
  /// 받은 메일에 "미확인"이 뜨면 내가 안 읽었다는 뜻으로 읽힌다.
  final bool showReadReceipt;

  /// 선택된 mail_idx 들. [onToggleSelect] 가 null 이면 체크박스 열 자체를 숨긴다.
  final Set<int> selectedIds;
  final void Function(MailListItem item, bool selected)? onToggleSelect;
  final void Function(bool selectAll)? onToggleSelectAll;
  final void Function(MailListItem item, bool starred)? onToggleStar;

  final MailSortSpec sort;
  final ValueChanged<MailSortField>? onSort;

  bool get _selectable => onToggleSelect != null;
  bool get _starrable => onToggleStar != null;

  /// 화면에 보이는 것이 전부 선택됐는지 — 전체선택 체크박스의 상태.
  bool get _allSelected =>
      items.isNotEmpty && items.every((m) => selectedIds.contains(m.mailIdx));

  bool get _someSelected =>
      items.any((m) => selectedIds.contains(m.mailIdx)) && !_allSelected;

  @override
  Widget build(BuildContext context) {
    // 열 구성이 선택 가능 여부에 따라 달라진다. 인덱스를 손으로 세면 반드시
    // 어긋나므로, 열 정의를 한 리스트로 만들고 너비·헤더·본문을 같은 순서로 뽑는다.
    final columns = <_MailColumn>[
      if (_selectable)
        _MailColumn(
          width: const FixedColumnWidth(44),
          header: _selectAllHeader(),
          cell: (item) => _checkboxCell(item),
          tappable: false,
        ),
      if (_starrable)
        _MailColumn(
          width: const FixedColumnWidth(40),
          header: const ErpTableHeaderCell('★'),
          cell: (item) => _starCell(item),
          tappable: false,
        ),
      _MailColumn(
        width: const FixedColumnWidth(56),
        header: const ErpTableHeaderCell('구분'),
        cell: (item) =>
            ErpTableBodyCell(item.inbound ? '수신' : '발신', center: true),
      ),
      _MailColumn(
        width: const FlexColumnWidth(1.4),
        header: _sortHeader('보낸사람 / 받는사람', MailSortField.sender),
        cell: (item) => _CounterpartCell(item: item),
      ),
      _MailColumn(
        width: const FlexColumnWidth(3),
        header: _sortHeader('제목', MailSortField.subject),
        cell: (item) => _MailSubjectCell(item: item, onTap: () => onOpen(item)),
      ),
      _MailColumn(
        width: const FixedColumnWidth(48),
        header: const ErpTableHeaderCell('첨부'),
        cell: (item) => _AttachmentCell(item: item),
      ),
      _MailColumn(
        width: const FixedColumnWidth(140),
        header: _sortHeader('일시', MailSortField.date, center: true),
        cell: (item) => _DateCell(item: item),
      ),
      _MailColumn(
        width: const FixedColumnWidth(96),
        header: const ErpTableHeaderCell('상태'),
        cell: (item) => MailStatusBadge(item: item),
      ),
      if (showReadReceipt)
        _MailColumn(
          width: const FixedColumnWidth(150),
          header: const _ReadReceiptHeaderCell(),
          cell: (item) => _ReadReceiptCell(item: item),
        ),
    ];

    return ErpVirtualDataTable(
      // 열이 하나 늘면 최소 폭도 함께 늘려야 한다. 그대로 두면 좁은 화면에서
      // 제목 칸이 짓눌려 글자가 다 잘린다.
      minWidth:
          (_selectable ? 1120 : 1020) + (showReadReceipt ? 150 : 0),
      columnWidths: <int, TableColumnWidth>{
        for (var i = 0; i < columns.length; i++) i: columns[i].width,
      },
      headerRow: TableRow(
        decoration: kErpTableHeaderRowDecoration,
        children: [for (final c in columns) c.header],
      ),
      rowCount: items.length,
      rowBuilder: (rowContext, index) {
        final item = items[index];
        final selected = selectedIds.contains(item.mailIdx);
        return TableRow(
          decoration: BoxDecoration(
            // 선택된 행은 배경을 바꿔 준다 — 스크롤이 길어지면 무엇을 골랐는지
            // 체크박스만으로는 안 보인다.
            color: selected
                ? AppTheme.tableRowSelectedTint
                : (index.isEven ? AppTheme.tableRowOdd : AppTheme.tableRowEven),
          ),
          children: [
            for (final c in columns)
              if (c.tappable)
                ErpTableDoubleTapCell(
                  onDoubleTap: () => onOpen(item),
                  child: c.cell(item),
                )
              else
                c.cell(item),
          ],
        );
      },
    );
  }

  Widget _sortHeader(String title, MailSortField field, {bool center = false}) {
    final handler = onSort;
    if (handler == null) return ErpTableHeaderCell(title);
    return MailSortableHeaderCell(
      title: title,
      field: field,
      sort: sort,
      onSort: handler,
      center: center,
    );
  }

  Widget _selectAllHeader() {
    return Center(
      child: Checkbox(
        // 일부만 선택된 상태를 세모(tristate)로 보여 준다. 그래야 "전체선택을
        // 눌렀는데 왜 안 켜지지" 같은 혼란이 없다.
        value: _allSelected ? true : (_someSelected ? null : false),
        tristate: true,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: onToggleSelectAll == null
            ? null
            : (_) => onToggleSelectAll!.call(!_allSelected),
      ),
    );
  }

  Widget _checkboxCell(MailListItem item) {
    final selected = selectedIds.contains(item.mailIdx);
    return Center(
      child: Checkbox(
        value: selected,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: (v) => onToggleSelect!.call(item, v ?? false),
      ),
    );
  }

  Widget _starCell(MailListItem item) {
    return Center(
      child: IconButton(
        tooltip: item.starred ? '중요표시 해제' : '중요표시',
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: () => onToggleStar!.call(item, !item.starred),
        icon: Icon(
          item.starred ? Icons.star : Icons.star_border,
          size: 18,
          color: item.starred
              ? const Color(0xFFE9A100)
              : AppTheme.textPlaceholder,
        ),
      ),
    );
  }
}

/// 열 하나의 정의 — 너비·헤더·본문을 한 묶음으로 들고 다녀 인덱스 어긋남을 막는다.
class _MailColumn {
  const _MailColumn({
    required this.width,
    required this.header,
    required this.cell,
    this.tappable = true,
  });

  final TableColumnWidth width;
  final Widget header;
  final Widget Function(MailListItem item) cell;

  /// 더블클릭으로 상세를 열 수 있는 칸인지. 체크박스·별표 칸은 false —
  /// 체크하려다 더블클릭이 되면 원치 않게 상세로 튀어 버린다.
  final bool tappable;
}

/// 안 읽음이면 진하게, 읽었으면 흐리게 (다우오피스 방식).
class _CounterpartCell extends StatelessWidget {
  const _CounterpartCell({required this.item});

  final MailListItem item;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 5,
        vertical: compact ? 4 : 6,
      ),
      child: Text(
        item.counterpartLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? AppDimensions.tableBodyFontSizeCompact : 13.5,
          fontWeight: item.unread ? FontWeight.w700 : FontWeight.w400,
          color: item.unread ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({required this.item});

  final MailListItem item;

  @override
  Widget build(BuildContext context) {
    // 예약 메일은 "언제 나갈지"가 "언제 만들었는지"보다 중요하다.
    final scheduled = item.scheduledAt;
    final text = scheduled != null && !item.opened
        ? item.scheduledAtLabel
        : item.mailAtLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: item.unread ? FontWeight.w600 : FontWeight.w400,
              color: item.unread
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          if (scheduled != null)
            const Text(
              '예약',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFB45309),
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
        ],
      ),
    );
  }
}

/// 수신확인 열 머리 — 제목 옆에 한계 안내 툴팁을 붙인다.
///
/// 툴팁을 머리에 다는 이유: 칸마다 붙이면 마우스를 어디에 올려도 말풍선이 떠서
/// 목록을 훑기 어렵다. 열이 무슨 뜻인지 궁금할 때 보는 곳은 머리다.
class _ReadReceiptHeaderCell extends StatelessWidget {
  const _ReadReceiptHeaderCell();

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 5,
        vertical: compact ? 6 : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '수신확인',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: compact
                    ? AppDimensions.tableHeaderFontSizeCompact
                    : 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          const SizedBox(width: 3),
          const MailReadReceiptHelpIcon(size: 13),
        ],
      ),
    );
  }
}

/// 수신확인 한 칸 — 확인됐으면 **일시**, 아니면 "미확인".
///
/// "읽음/읽지 않음"이라고 쓰지 않는다([kMailReadReceiptHelp] 참고).
class _ReadReceiptCell extends StatelessWidget {
  const _ReadReceiptCell({required this.item});

  final MailListItem item;

  @override
  Widget build(BuildContext context) {
    // 아직 안 나간 메일(임시저장·예약·발송대기)에는 확인할 것이 없다.
    // 여기에 "미확인"을 찍으면 상대가 안 읽은 것처럼 보인다.
    final send = item.sendStatus.toUpperCase();
    final notSentYet =
        send == 'DRAFT' || send == 'QUEUED' || send == 'SCHEDULED';
    if (item.inbound || notSentYet) {
      return const Center(
        child: Text(
          '-',
          style: TextStyle(fontSize: 12.5, color: AppTheme.textPlaceholder),
        ),
      );
    }

    final opened = item.opened;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.readReceiptShortLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: opened ? FontWeight.w600 : FontWeight.w400,
              color: opened
                  ? const Color(0xFF1E8E4E)
                  : AppTheme.textPlaceholder,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          // 여러 번 열어 본 경우에만 횟수를 덧붙인다. 1회는 굳이 적을 필요가 없고,
          // 0회는 위에서 이미 "미확인"으로 말했다.
          if (opened && item.openCnt > 1)
            Text(
              '${item.openCnt}회',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
        ],
      ),
    );
  }
}

/// 첨부가 있으면 클립 아이콘 — 숫자만 있으면 눈에 안 들어온다.
class _AttachmentCell extends StatelessWidget {
  const _AttachmentCell({required this.item});

  final MailListItem item;

  @override
  Widget build(BuildContext context) {
    if (!item.hasAttachment) {
      return const Center(
        child: Text(
          '-',
          style: TextStyle(fontSize: 12.5, color: AppTheme.textPlaceholder),
        ),
      );
    }
    return Tooltip(
      message: '첨부 ${item.attCnt}개',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.attach_file,
            size: 15,
            color: AppTheme.textSecondary,
          ),
          if (item.attCnt > 1)
            Text(
              '${item.attCnt}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
        ],
      ),
    );
  }
}

class _MailSubjectCell extends StatelessWidget {
  const _MailSubjectCell({required this.item, this.onTap});

  final MailListItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    // 안 읽은 수신 메일은 굵게 — 메일함에서 가장 먼저 눈에 들어와야 하는 정보다.
    final weight = item.unread ? FontWeight.w700 : FontWeight.w400;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 8,
        vertical: compact ? 4 : 6,
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            if (item.unread) ...[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.accentRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (item.highImportance) ...[
              const Icon(
                Icons.priority_high,
                size: 15,
                color: AppTheme.accentRed,
              ),
              const SizedBox(width: 2),
            ],
            Expanded(
              child: Text(
                item.subjectLabel,
                style: TextStyle(
                  fontSize: 14,
                  // 읽은 메일은 링크색을 흐리게 — 읽음/안읽음이 한눈에 갈린다.
                  color: item.unread
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF6B85B5),
                  fontWeight: weight,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 선택한 메일에 대한 일괄 동작 줄. 선택이 0건이면 아예 안 그린다.
class MailBulkActionBar extends StatelessWidget {
  const MailBulkActionBar({
    super.key,
    required this.selectedCount,
    required this.folder,
    required this.onAction,
    required this.onClear,
    this.onMove,
    this.busy = false,
    this.canUpdate = true,
    this.canDelete = true,
  });

  final int selectedCount;
  final String folder;
  final void Function(String action) onAction;
  final VoidCallback onClear;

  /// 사용자 정의 메일함으로 이동. null 이면 버튼을 숨긴다.
  final VoidCallback? onMove;

  final bool busy;
  final bool canUpdate;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    if (selectedCount <= 0) return const SizedBox.shrink();
    final isTrash = MailFolders.isTrash(folder);
    final isSpam = folder == MailFolders.spam;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.listScreenHPadding,
        0,
        AppDimensions.listScreenHPadding,
        8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD3E2F7)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              '$selectedCount건 선택',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563C7),
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          if (canUpdate) ...[
            _action(Icons.drafts_outlined, '읽음', MailBulkActions.read),
            _action(
              Icons.mark_email_unread_outlined,
              '안읽음',
              MailBulkActions.unread,
            ),
            _action(Icons.star_outline, '중요표시', MailBulkActions.star),
          ],
          // 휴지통에서는 "복구"와 "완전삭제"만 뜬다. 여기서 그냥 "삭제"를 보여 주면
          // 이미 삭제된 메일을 또 삭제하는 셈이라 사용자가 헷갈린다.
          if (canUpdate && MailFolders.canRestore(folder))
            _action(
              Icons.restore_from_trash_outlined,
              '복구',
              MailBulkActions.restore,
            ),
          if (canUpdate && !isSpam && !isTrash)
            _action(
              Icons.report_gmailerrorred_outlined,
              '스팸신고',
              MailBulkActions.spam,
            ),
          if (canUpdate && isSpam)
            _action(Icons.verified_outlined, '스팸해제', MailBulkActions.unspam),
          if (canUpdate && onMove != null && !isTrash)
            TextButton.icon(
              onPressed: busy ? null : onMove,
              icon: const Icon(Icons.drive_file_move_outline, size: 17),
              label: const Text('이동'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          if (canDelete && !isTrash)
            _action(
              Icons.delete_outline,
              '삭제',
              MailBulkActions.delete,
              danger: true,
            ),
          if (canDelete && isTrash)
            _action(
              Icons.delete_forever_outlined,
              '완전삭제',
              MailBulkActions.purge,
              danger: true,
            ),
          TextButton(
            onPressed: busy ? null : onClear,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: const Text('선택해제'),
          ),
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    String action, {
    bool danger = false,
  }) {
    return TextButton.icon(
      onPressed: busy ? null : () => onAction(action),
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: danger ? AppTheme.accentRed : null,
      ),
    );
  }
}

/// 목록 아래 페이지 이동 줄 — 건수·페이지당 개수·이전/다음.
class MailPagerBar extends StatelessWidget {
  const MailPagerBar({
    super.key,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  int get pageCount =>
      totalCount <= 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;

  @override
  Widget build(BuildContext context) {
    final last = pageCount;
    final current = page.clamp(1, last);
    final from = totalCount == 0 ? 0 : (current - 1) * pageSize + 1;
    final to = (current * pageSize).clamp(0, totalCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.listScreenHPadding,
        6,
        AppDimensions.listScreenHPadding,
        4,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Text(
            '$totalCount건 중 $from–$to',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '이전 페이지',
            visualDensity: VisualDensity.compact,
            onPressed: current > 1 ? () => onPageChanged(current - 1) : null,
            icon: const Icon(Icons.chevron_left, size: 20),
          ),
          Text(
            '$current / $last',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          IconButton(
            tooltip: '다음 페이지',
            visualDensity: VisualDensity.compact,
            onPressed: current < last ? () => onPageChanged(current + 1) : null,
            icon: const Icon(Icons.chevron_right, size: 20),
          ),
          const SizedBox(width: 8),
          const Text(
            '페이지당',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          DropdownButton<int>(
            value: kMailPageSizes.contains(pageSize) ? pageSize : 50,
            isDense: true,
            underline: const SizedBox.shrink(),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
            items: [
              for (final n in kMailPageSizes)
                DropdownMenuItem<int>(value: n, child: Text('$n건')),
            ],
            onChanged: (v) => onPageSizeChanged(v ?? 50),
          ),
        ],
      ),
    );
  }
}

/// 메일함 건수 요약 칩 (홈 화면 상단).
class MailCountChip extends StatelessWidget {
  const MailCountChip({
    super.key,
    required this.label,
    required this.count,
    this.highlight = false,
    this.onTap,
  });

  final String label;
  final int count;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? const Color(0xFFFDEEEE) : AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlight ? const Color(0xFFF3D3D3) : AppTheme.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? AppTheme.accentRed
                      : AppTheme.chromeBlack,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
