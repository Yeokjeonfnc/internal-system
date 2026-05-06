/// 브라우저에서 파일로 열 때 전용 HTML (JavascriptChannel 없음).
/// 카카오는 도메인 루트 직접 접근을 막으므로, 동일 스크립트 embed 후 선택 결과를 안내한다.
const String kKakaoPostcodeBrowserStandaloneHtml = '''
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>우편번호 검색</title>
  <style>
    html, body { margin: 0; padding: 0; height: 100%; background: #fff; font-family: sans-serif; }
    #wrap { width: 100%; height: 100%; min-height: 100vh; }
    #hint { padding: 12px 16px; font-size: 14px; color: #444; border-bottom: 1px solid #eee; }
  </style>
</head>
<body>
  <div id="hint">주소를 검색해 선택하면 우편번호·주소를 안내합니다. 내용을 복사해 앱에 붙여 넣어 주세요.</div>
  <div id="wrap"></div>
  <script>
    function uiBridge(obj) {
      if (obj.error) {
        alert('오류: ' + obj.error);
        return;
      }
      if (obj.closed) return;
      var zip = obj.zonecode || '';
      var road = obj.roadAddress || '';
      var jibun = obj.jibunAddress || '';
      var line = '';
      if (obj.userSelectedType === 'J') {
        line = jibun || road;
      } else if (obj.userSelectedType === 'R') {
        line = road || jibun;
      } else {
        line = road || jibun;
      }
      var msg = '우편번호: ' + zip + '\\n주소: ' + line +
        '\\n\\n※ 확인 후 필요하면 주소만 따로 복사하세요. (클립보드 복사를 지원하지 않으면 직접 선택해 복사)';
      alert(msg);
      try {
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(zip + '\\n' + line);
        }
      } catch (e) {}
    }
    function postcodeFindRowFromTarget(t, wrapEl) {
      if (!t || !wrapEl.contains(t)) return null;
      if (typeof t.closest === 'function') {
        var byClosest = t.closest('li, a, button, [role="button"], [role="link"], [onclick]');
        if (byClosest && wrapEl.contains(byClosest)) return byClosest;
      }
      var cur = t;
      for (var depth = 0; depth < 16 && cur && wrapEl.contains(cur); depth++) {
        var tag = cur.tagName;
        if (tag === 'LI' || tag === 'A' || tag === 'BUTTON') return cur;
        var role = cur.getAttribute && cur.getAttribute('role');
        if (role === 'button' || role === 'link' || role === 'option') return cur;
        var oc = cur.getAttribute && cur.getAttribute('onclick');
        if (oc) return cur;
        cur = cur.parentElement;
      }
      return null;
    }
    function attachPostcodeDoubleClickSelectAssist(wrapEl) {
      if (!wrapEl) return;
      wrapEl.addEventListener('dblclick', function(ev) {
        var row = postcodeFindRowFromTarget(ev.target, wrapEl);
        if (!row) {
          var hit = document.elementFromPoint(ev.clientX, ev.clientY);
          row = postcodeFindRowFromTarget(hit, wrapEl);
        }
        if (!row || !wrapEl.contains(row) || typeof row.click !== 'function') return;
        row.click();
      }, true);
    }
    function loadPostcode() {
      var script = document.createElement('script');
      script.src = 'https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js';
      script.onload = function() {
        try {
          var wrap = document.getElementById('wrap');
          new daum.Postcode({
            oncomplete: function(data) {
              uiBridge({
                zonecode: data.zonecode || '',
                roadAddress: data.roadAddress || '',
                jibunAddress: data.jibunAddress || '',
                userSelectedType: data.userSelectedType || ''
              });
            },
            onresize: function(size) {
              var el = document.getElementById('wrap');
              if (el) el.style.height = size.height + 'px';
            },
            onclose: function(state) {
              if (state === 'FORCE_CLOSE') uiBridge({ closed: true });
            },
            width: '100%',
            height: '100%'
          }).embed(wrap);
          attachPostcodeDoubleClickSelectAssist(wrap);
        } catch (e) {
          uiBridge({ error: String(e) });
        }
      };
      script.onerror = function() {
        uiBridge({ error: '우편번호 스크립트를 불러오지 못했습니다. 인터넷 연결을 확인해 주세요.' });
      };
      document.head.appendChild(script);
    }
    loadPostcode();
  </script>
</body>
</html>
''';
