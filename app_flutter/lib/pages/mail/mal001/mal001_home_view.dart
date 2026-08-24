// 메일함 현황 요약 줄 — 받은메일함 위쪽에 붙는다.
//
// 예전에는 이 파일이 "메일 홈"이었다. 받은/보낸/임시보관을 **화면 안쪽 탭**으로
// 갈아 끼우는 구조였는데, 메일함을 옮길 때마다 메일 화면에 들어가 탭을 다시 골라야
// 해서 불편하다는 지적이 있었다. 지금은 메일함마다 좌측 메뉴가 따로 있고
// (grp_mail 아래 mal001~mal008) 각 메일함은 [Mal001FolderView] 하나가 그린다.
//
// 그래서 남은 것은 "현황 숫자" 뿐이다. 탭이 사라진 대신 여기서 어느 메일함에
// 몇 건이 있는지 한눈에 보여 주고, 누르면 그 메일함으로 이동한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_provider.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_widgets.dart';
import 'package:app_flutter/pages/mail/shared/mail_routes.dart';

/// 메일함별 건수 칩 줄. 조회 실패는 **숨기지 않고** 배너로 알린다.
class MailCountsStrip extends ConsumerWidget {
  const MailCountsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(mailCountsProvider);

    if (countsAsync.hasError) {
      return MailFailureBanner(
        error: countsAsync.error,
        feature: '메일함 현황',
        fallback: '메일함 현황을 불러오지 못했습니다.',
        onRetry: () => ref.invalidate(mailCountsProvider),
      );
    }

    final counts = countsAsync.valueOrNull ?? MailCounts.empty;
    // 값이 아직 없을 때 0 을 찍으면 "메일이 없다"로 읽힌다. 값이 도착한 뒤에만 그린다.
    if (!countsAsync.hasValue) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.listScreenHPadding,
          0,
          AppDimensions.listScreenHPadding,
          10,
        ),
        child: SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    void go(String folder) => context.go(MailRoutes.pathForFolder(folder));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.listScreenHPadding,
        0,
        AppDimensions.listScreenHPadding,
        10,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          MailCountChip(
            label: '안 읽은 메일',
            count: counts.inboxUnread,
            highlight: counts.inboxUnread > 0,
            onTap: () => go(MailFolders.inbox),
          ),
          MailCountChip(
            label: '받은메일함',
            count: counts.inbox,
            onTap: () => go(MailFolders.inbox),
          ),
          MailCountChip(
            label: '보낸메일함',
            count: counts.sent,
            onTap: () => go(MailFolders.sent),
          ),
          MailCountChip(
            label: '임시보관함',
            count: counts.draft,
            onTap: () => go(MailFolders.draft),
          ),
          if (counts.scheduled > 0)
            MailCountChip(
              label: '예약메일함',
              count: counts.scheduled,
              onTap: () => go(MailFolders.scheduled),
            ),
          MailCountChip(
            label: '발송실패',
            count: counts.failed,
            highlight: counts.failed > 0,
          ),
          MailCountChip(
            label: '스팸',
            count: counts.spam,
            onTap: () => go(MailFolders.spam),
          ),
          if (counts.trash > 0)
            MailCountChip(
              label: '휴지통',
              count: counts.trash,
              onTap: () => go(MailFolders.trash),
            ),
        ],
      ),
    );
  }
}
