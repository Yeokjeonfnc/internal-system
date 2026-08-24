// 수신 메일 본문 HTML 정화(sanitize) + 외부 이미지 차단.
//
// **이 앱에서 가장 신뢰할 수 없는 HTML 이 메일 본문이다.** 외부인이 마음대로
// 써서 보낸 문서를 우리 화면에 그리는 것이라, 그대로 렌더하면
//  - `<script>` 로 세션 토큰을 긁어 가거나,
//  - `<img src="https://공격자/..." >` 추적픽셀로 "언제 누가 열었는지"가 새거나,
//  - `onerror=` 같은 이벤트 속성으로 스크립트가 도는 일이 생긴다.
//
// 방어는 두 겹이다.
//  1) 화면 쪽: 본문은 `sandbox="allow-scripts"` iframe(=별도 오리진) 안에서만 그린다.
//  2) 여기: iframe 에 넣기 **전에** 위험한 태그·속성·URL 을 제거한다.
//
// 한 겹만으로 끝내지 않는 이유는, 1) 은 iframe 구현을 나중에 누가 바꾸면
// 조용히 무너지고, 2) 는 정규식 기반이라 완벽하지 않기 때문이다. 둘 다 있어야 한다.
//
// ── 이 구현의 한계를 분명히 적어 둔다 ──
// 정규식은 HTML 파서가 아니다. 극단적으로 깨진 마크업(`<scr<script>ipt>` 같은
// 중첩 회피)은 100% 막지 못한다. 그래서 **iframe 샌드박스가 1차 방어이고 이 파일은
// 보조**라는 순서를 절대 뒤집지 말 것. 본문을 iframe 밖(예: `Html` 위젯)에서
// 직접 그리는 코드를 새로 만들면 이 가정이 깨진다.

/// 정화 결과 — 화면이 "이미지를 차단했다"고 알려 주려면 건수가 필요하다.
class MailSanitizedHtml {
  const MailSanitizedHtml({
    required this.html,
    required this.blockedImageCount,
    required this.blockedExternalImages,
  });

  final String html;

  /// 차단한 외부 이미지 수. 0 이면 "이미지 표시" 버튼을 띄울 이유가 없다.
  final int blockedImageCount;

  /// 실제로 외부 이미지를 막았는지. [blockedImageCount] > 0 과 같은 뜻이지만
  /// 호출부 가독성을 위해 따로 둔다.
  final bool blockedExternalImages;
}

/// 통째로 들어내는 태그 — 여는 태그부터 닫는 태그까지 **내용까지 함께** 지운다.
/// (`<script>` 안의 코드가 텍스트로 남아 화면에 노출되는 것도 막는다.)
const List<String> _dropWithContent = <String>[
  'script',
  'style',
  'iframe',
  'object',
  'embed',
  'applet',
  'noscript',
  'template',
  'svg',
  'math',
];

/// 내용은 남기고 태그만 없애는 것들. `<form>` 안의 글자는 본문일 수 있다.
const List<String> _unwrapTags = <String>[
  'form',
  'input',
  'button',
  'select',
  'option',
  'textarea',
  'base',
  'link',
  'meta',
  'title',
  'html',
  'head',
  'body',
  'frame',
  'frameset',
];

/// 이미지를 차단했을 때 자리에 남길 1x1 투명 GIF. 외부로 요청이 나가지 않는다.
const String _blankPixel =
    'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';

/// 메일 본문 HTML 을 화면에 그려도 되는 형태로 만든다.
///
/// [blockExternalImages] 가 true 면 원격 이미지를 투명 픽셀로 바꾸고 원본 주소를
/// `data-blocked-src` 에 남긴다("이미지 표시"를 누르면 false 로 다시 부른다).
/// `cid:`(본문 인라인 첨부)와 `data:image/...` 는 외부 요청이 아니라 그대로 둔다.
MailSanitizedHtml sanitizeMailHtml(
  String rawHtml, {
  bool blockExternalImages = true,
}) {
  if (rawHtml.trim().isEmpty) {
    return const MailSanitizedHtml(
      html: '',
      blockedImageCount: 0,
      blockedExternalImages: false,
    );
  }

  var html = rawHtml;

  // 1) 주석 제거 — 조건부 주석(`<!--[if IE]>`)에 마크업이 숨어 들어온다.
  html = html.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

  // 2) 위험 태그를 내용째 제거. 닫는 태그가 없는 깨진 문서까지 훑기 위해
  //    "여는 태그부터 닫는 태그까지" 와 "남은 여는/닫는 태그" 를 모두 지운다.
  for (final tag in _dropWithContent) {
    html = html.replaceAll(
      RegExp('<$tag\\b[^>]*>.*?</$tag\\s*>', caseSensitive: false, dotAll: true),
      '',
    );
    html = html.replaceAll(
      RegExp('</?$tag\\b[^>]*>', caseSensitive: false),
      '',
    );
  }

  // 3) 태그만 벗기고 내용은 남긴다.
  for (final tag in _unwrapTags) {
    html = html.replaceAll(
      RegExp('</?$tag\\b[^>]*>', caseSensitive: false),
      '',
    );
  }

  // 4) 이벤트 핸들러 속성(`onclick=`, `onerror=` …)을 전부 제거.
  //    따옴표가 있는 형태와 없는 형태를 모두 지운다.
  html = html.replaceAll(
    RegExp(r'''\son[a-z]+\s*=\s*"[^"]*"''', caseSensitive: false),
    ' ',
  );
  html = html.replaceAll(
    RegExp(r"""\son[a-z]+\s*=\s*'[^']*'""", caseSensitive: false),
    ' ',
  );
  html = html.replaceAll(
    RegExp(r'\son[a-z]+\s*=\s*[^\s>]+', caseSensitive: false),
    ' ',
  );

  // 5) `javascript:` / `vbscript:` URL 제거. href·src·action 어디에 있든 막는다.
  html = html.replaceAll(
    RegExp(
      r'''(href|src|action|formaction)\s*=\s*"\s*(javascript|vbscript|data\s*:\s*text/html)[^"]*"''',
      caseSensitive: false,
    ),
    'href="#"',
  );
  html = html.replaceAll(
    RegExp(
      r"""(href|src|action|formaction)\s*=\s*'\s*(javascript|vbscript|data\s*:\s*text/html)[^']*'""",
      caseSensitive: false,
    ),
    'href="#"',
  );

  // 6) `style` 속성 안의 `expression()` / `url(javascript:)` 제거.
  //    스타일 전체를 지우면 메일이 심하게 깨져서, 위험한 부분만 도려낸다.
  html = html.replaceAll(
    RegExp(r'expression\s*\(', caseSensitive: false),
    'void(',
  );
  html = html.replaceAll(
    RegExp(r'url\s*\(\s*["\x27]?\s*javascript:', caseSensitive: false),
    'url(',
  );

  // 7) 외부 이미지 차단(추적픽셀 방어).
  var blocked = 0;
  if (blockExternalImages) {
    html = html.replaceAllMapped(
      RegExp(
        r'''<img\b([^>]*?)\ssrc\s*=\s*(["\x27])(.*?)\2([^>]*)>''',
        caseSensitive: false,
        dotAll: true,
      ),
      (m) {
        final before = m.group(1) ?? '';
        final url = (m.group(3) ?? '').trim();
        final after = m.group(4) ?? '';
        if (_isLocalImageSrc(url)) {
          // 인라인 첨부(cid:)·데이터 URI 는 외부로 나가지 않으므로 그대로 둔다.
          return m.group(0)!;
        }
        blocked++;
        // 원본 주소는 지우지 않고 남겨 둔다 — "이미지 표시"를 눌렀을 때
        // 다시 sanitize 를 돌리면 되지만, 디버깅할 때 원본이 있어야 한다.
        final safeUrl = url.replaceAll('"', '&quot;');
        return '<img$before src="$_blankPixel" '
            'data-blocked-src="$safeUrl" '
            'alt="[차단된 이미지]" $after>';
      },
    );

    // CSS `background-image: url(...)` 로도 추적픽셀이 들어온다. 원격이면 지운다.
    html = html.replaceAllMapped(
      RegExp(
        r'''background(-image)?\s*:\s*url\(\s*["\x27]?([^)"\x27]+)["\x27]?\s*\)''',
        caseSensitive: false,
      ),
      (m) {
        final url = (m.group(2) ?? '').trim();
        if (_isLocalImageSrc(url)) return m.group(0)!;
        blocked++;
        return 'background-image:none';
      },
    );
  }

  return MailSanitizedHtml(
    html: html,
    blockedImageCount: blocked,
    blockedExternalImages: blocked > 0,
  );
}

/// 외부로 네트워크 요청이 나가지 **않는** 이미지 주소인지.
bool _isLocalImageSrc(String url) {
  final u = url.trim().toLowerCase();
  if (u.isEmpty) return true;
  if (u.startsWith('cid:')) return true;
  if (u.startsWith('data:image/')) return true;
  return false;
}

/// 평문 본문을 HTML 로 감쌀 때 쓰는 이스케이프.
/// 평문에 `<b>` 가 들어 있어도 태그로 해석되지 않게 한다.
String escapeHtmlText(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
