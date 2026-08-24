// 메일(mal001) Riverpod — 메일함 목록·상세·건수·스레드 (API만 사용).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/pages/mail/mal001/mal001_api.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';

/// 메일함 캐시 키.
///
/// `userId` 를 키에 넣는 이유는 로그아웃 후 다른 사람이 로그인했을 때 이전 사람의
/// 목록을 그대로 보여 주면 안 되기 때문이다(전자결재 `EapDocListKey` 와 같은 이유).
/// `mine` 도 키에 넣는다 — "내 담당만" 을 켜고 끌 때 서버 결과가 완전히 다르다.
typedef MailListKey = ({String userId, String folder, bool mine});

MailListKey mailListKey(String userId, String folder, {bool mine = false}) =>
    (userId: userId.trim(), folder: folder, mine: mine);

final mailApiProvider = Provider<Mal001ApiService>((ref) => Mal001ApiService());

/// 메일함 목록. 페이저 없이 서버 상한까지 전량 로드한다(키워드 필터는 클라이언트).
final mailListProvider =
    FutureProvider.family<List<MailListItem>, MailListKey>((ref, key) async {
      final api = ref.watch(mailApiProvider);
      return api.listMessages(
        folder: key.folder,
        mine: key.mine,
        limit: Mal001ApiService.maxPageSize,
      );
    });

final mailDetailProvider = FutureProvider.family<MailDetail?, int>((
  ref,
  mailIdx,
) async {
  final api = ref.watch(mailApiProvider);
  return api.getMessage(mailIdx);
});

/// 메일함별 건수. 사이드 요약·탭 라벨에 쓴다.
///
/// `mine: false` 로 읽는다 — 목록 화면 기본값과 다르면 "받은메일함 (3)" 인데
/// 목록에는 10건이 뜨는 식으로 숫자가 어긋난다.
final mailCountsProvider = FutureProvider<MailCounts>((ref) async {
  final api = ref.watch(mailApiProvider);
  return api.counts(mine: false);
});

final mailThreadProvider = FutureProvider.family<MailThread?, int>((
  ref,
  threadIdx,
) async {
  if (threadIdx <= 0) return null;
  final api = ref.watch(mailApiProvider);
  return api.getThread(threadIdx);
});

/// 받는사람 자동완성 후보.
///
/// `autoDispose` 를 쓰는 이유: 검색어마다 provider 인스턴스가 하나씩 생기는데,
/// 그대로 두면 작성 화면을 한 번 쓸 때마다 "김", "김철", "김철수" … 가 전부
/// 메모리에 남는다. 화면을 닫으면 같이 버린다.
final mailRecipientSearchProvider = FutureProvider.autoDispose
    .family<List<MailRecipient>, String>((ref, query) async {
      final q = query.trim();
      if (q.length < 2) return const <MailRecipient>[];
      final api = ref.watch(mailApiProvider);
      return api.searchRecipients(q);
    });

/// 서명 목록 — 작성 화면과 설정 화면이 함께 본다.
final mailSignaturesProvider = FutureProvider<List<MailSignature>>((ref) async {
  final api = ref.watch(mailApiProvider);
  return api.listSignatures();
});

/// 사용자 정의 메일함 — 목록의 "이동" 대상과 설정 화면이 함께 본다.
final mailUserFoldersProvider = FutureProvider<List<MailUserFolder>>((
  ref,
) async {
  final api = ref.watch(mailApiProvider);
  return api.listUserFolders();
});

/// 개인 환경설정. 실패하면 예외를 그대로 올린다 —
/// 여기서 기본값으로 뭉개면 "설정을 저장했는데 안 먹는다"가 된다.
final mailPreferencesProvider = FutureProvider<MailPreferences>((ref) async {
  final api = ref.watch(mailApiProvider);
  return api.getPreferences();
});

/// 자동분류 규칙 목록. **서버가 준 순서를 그대로 쓴다** —
/// 순서가 곧 우선순위라 화면에서 다시 정렬하면 실제 적용 순서와 어긋난다.
final mailRulesProvider = FutureProvider<List<MailRule>>((ref) async {
  final api = ref.watch(mailApiProvider);
  return api.listRules();
});

/// 전체 자동전달 설정.
final mailForwardProvider = FutureProvider<MailForwardSetting>((ref) async {
  final api = ref.watch(mailApiProvider);
  return api.getForward();
});

/// 자동전달 예외 규칙(최대 [kMailForwardRuleMax] 건).
final mailForwardRulesProvider = FutureProvider<List<MailForwardRule>>((
  ref,
) async {
  final api = ref.watch(mailApiProvider);
  return api.listForwardRules();
});
