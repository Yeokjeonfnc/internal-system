// 메일 셸 — 경로 하나로 목록·상세·작성·설정을 갈아 끼운다(전자결재 `EapShell` 과 동일).
//
// 라우터에는 얇은 `GoRoute` 만 등록하고 화면 선택은 여기서 한다. 그래야 상단
// 히스토리 탭이 메일 하나로 유지되고, 목록 → 상세 → 답장으로 오갈 때 탭이
// 늘어나지 않는다.
//
// 메일함은 경로 하나가 사이드바 메뉴 하나에 대응한다(grp_mail 아래 mal001~mal008).
// 폴더 판정은 [MailRoutes.folderFromPath] 한 곳에서만 한다 — 여기서 if 를 늘려 가면
// 라우트를 추가할 때 한쪽만 고쳐 놓고 "메뉴는 뜨는데 화면이 안 바뀐다"가 된다.

import 'package:flutter/material.dart';

import 'package:app_flutter/pages/mail/mal001/mal001_compose_view.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_detail_view.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_list_view.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_settings_view.dart';
import 'package:app_flutter/pages/mail/shared/mail_routes.dart';

class MailShell extends StatelessWidget {
  const MailShell({super.key, required this.path, this.query = const {}});

  final String path;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final mailIdx = MailRoutes.mailIdxFromPath(path);
    if (mailIdx != null) {
      // 어느 메일함에서 들어왔는지를 쿼리로 받는다 — 상세의 이전/다음 이동이
      // 그 메일함 목록을 그대로 따라가야 하기 때문이다.
      final folder = query['folder'];
      return Mal001DetailView(
        mailIdx: mailIdx,
        folder: folder != null && folder.trim().isNotEmpty ? folder : null,
      );
    }

    final normalized = path == MailRoutes.root ? MailRoutes.inbox : path;

    if (normalized == MailRoutes.compose) {
      final reply = query['reply'] ?? '';
      final mode = query['mode'] ?? MailRoutes.composeModeReply;
      final to = query['to'] ?? '';
      return Mal001ComposeView(
        // 같은 작성 화면을 재사용하므로 원본·모드·초기수신자가 바뀌면 state 를
        // 통째로 새로 만든다. (키가 없으면 답장 → 전달로 옮겨도 이전 본문이
        // 남거나, 상세에서 다른 사람을 연달아 더블클릭해도 첫 주소만 남는다.)
        key: ValueKey('mail-compose-$reply-$mode-$to'),
        replyToMailIdx: int.tryParse(reply),
        mode: mode,
        initialTo: to.trim().isEmpty ? null : to.trim(),
      );
    }

    if (normalized == MailRoutes.settings) {
      return const Mal001SettingsView();
    }

    final folder = MailRoutes.folderFromPath(normalized);
    if (folder != null) {
      // 폴더가 바뀌면 목록 화면의 선택·페이지 상태를 초기화해야 한다.
      // `didUpdateWidget` 에서 처리하지만, 키를 줘 두면 상태가 확실히 갈린다.
      return Mal001FolderView(key: ValueKey('mail-folder-$folder'), folder: folder);
    }

    // 알 수 없는 `/mail/...` 경로 — 빈 화면 대신 받은메일함으로 물러난다.
    return const Mal001FolderView(folder: MailFolders.inbox);
  }
}
