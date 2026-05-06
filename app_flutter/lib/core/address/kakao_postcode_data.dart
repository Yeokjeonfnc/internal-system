import 'dart:convert';

import 'package:flutter/material.dart';

/// WebView2 등에서 postMessage 페이로드가 JSON 문자열로 한 번 더 오는 경우를 풀어 준다.
dynamic unwrapKakaoPostWebMessagePayload(dynamic decoded) {
  var cur = decoded;
  for (var i = 0; i < 4 && cur is String; i++) {
    final s = cur.trim();
    if (s.isEmpty) break;
    try {
      cur = jsonDecode(s);
    } catch (_) {
      break;
    }
  }
  return cur;
}

/// 우편번호 검색 완료 시 반환 값.
class KakaoPostcodeResult {
  const KakaoPostcodeResult({
    required this.zonecode,
    required this.roadAddress,
    required this.jibunAddress,
    required this.userSelectedType,
    this.buildingName = '',
  });

  factory KakaoPostcodeResult.fromJson(Map<String, dynamic> json) {
    return KakaoPostcodeResult(
      zonecode: '${json['zonecode'] ?? ''}',
      roadAddress: '${json['roadAddress'] ?? ''}',
      jibunAddress: '${json['jibunAddress'] ?? ''}',
      userSelectedType: '${json['userSelectedType'] ?? ''}',
      buildingName: '${json['buildingName'] ?? ''}',
    );
  }

  /// 사용자가 고른 주소 유형에 맞춘 기본 주소 한 줄.
  String get addressLine {
    final road = roadAddress.trim();
    final jibun = jibunAddress.trim();
    if (userSelectedType == 'R') return road.isNotEmpty ? road : jibun;
    if (userSelectedType == 'J') return jibun.isNotEmpty ? jibun : road;
    return road.isNotEmpty ? road : jibun;
  }

  final String zonecode;
  final String roadAddress;
  final String jibunAddress;
  final String userSelectedType;
  final String buildingName;
}

/// 스크립트는 로드 완료 후 embed.
/// 브리지: Flutter WebView `JavascriptChannel` / WebView2 `chrome.webview.postMessage` /
/// 웹 iframe `parent.postMessage`.
void applyKakaoPostcodeBridgeDecoded(
  NavigatorState navigator,
  ScaffoldMessengerState? messenger, {
  required dynamic decoded,
  required bool Function() getCompleted,
  required void Function(bool v) setCompleted,
}) {
  if (getCompleted()) return;

  final normalized = unwrapKakaoPostWebMessagePayload(decoded);
  if (normalized is! Map) {
    debugPrint('Kakao postcode bridge: Map으로 해석되지 않음(무시): $decoded');
    return;
  }
  final map = Map<String, dynamic>.from(normalized);

  if (map['closed'] == true) {
    navigator.pop();
    return;
  }

  if (map['error'] != null) {
    final msg = '${map['error']}';
    if (messenger != null) {
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
    return;
  }

  setCompleted(true);
  navigator.pop(KakaoPostcodeResult.fromJson(map));
}

/// Windows 전용: JS 가 pending 문자열을 두면 Dart 가 executeScript 로 주기적으로 가져온다.
const String kKakaoPostcodeWindowsPollPendingScript = r'''
(function(){
  var p = window.__yjKakaoPostcodePending;
  if (p == null || p === '') return null;
  window.__yjKakaoPostcodePending = '';
  return p;
})()
''';

/// 스크립트는 로드 완료 후 embed.
/// Flutter 웹에서는 동일 출처 `web/kakao_postcode_embed.html` 과 내용을 반드시 맞출 것.
const String kKakaoPostcodeEmbedHtml = '''
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    html, body { margin: 0; padding: 0; height: 100%; background: #fff; }
    #wrap { width: 100%; height: 100%; min-height: 100vh; }
  </style>
</head>
<body>
  <div id="wrap"></div>
  <script>
    function bridgeSend(obj) {
      var str = JSON.stringify(obj);
      try {
        window.__yjKakaoPostcodePending = str;
        window.__yjKakaoPostcodePendingTs = Date.now();
      } catch (eGlob) {}
      try {
        console.log('[yj_kakao] bridgeSend', str);
        console.log('[yj_kakao] chrome.webview=', !!(window.chrome && window.chrome.webview));
        console.log('KAKAO_ADDR_RESULT:' + str);
      } catch (logErr) {}

      function tryWinWebViewPostMessage() {
        try {
          if (window.chrome && window.chrome.webview &&
              typeof window.chrome.webview.postMessage === 'function') {
            window.chrome.webview.postMessage(str);
            return true;
          }
        } catch (e) {}
        return false;
      }

      if (tryWinWebViewPostMessage()) {
        return;
      }

      var attempts = 0;
      var maxAttempts = 60;
      var pollMs = 50;
      var tid = setInterval(function() {
        attempts++;
        if (tryWinWebViewPostMessage() || attempts >= maxAttempts) {
          clearInterval(tid);
        }
      }, pollMs);

      try {
        if (typeof KakaoPostcode !== 'undefined' && KakaoPostcode.postMessage) {
          KakaoPostcode.postMessage(str);
          return;
        }
      } catch (e1) {}
      try {
        if (window.parent && window.parent !== window) {
          /** 브라우저 Flutter(DDC): 객체 postMessage 는 event.data 변환 시 TypeError 남. 문자열만 전달 */
          window.parent.postMessage('yj_pc_v1|' + str, '*');
        }
      } catch (e3) {}
    }
    /** WebView(특히 Windows)에서 결과 행 단일 클릭이 불안정할 때, 더블클릭으로 선택 확정 */
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
              bridgeSend({
                zonecode: data.zonecode || '',
                roadAddress: data.roadAddress || '',
                jibunAddress: data.jibunAddress || '',
                buildingName: data.buildingName || '',
                userSelectedType: data.userSelectedType || ''
              });
            },
            onresize: function(size) {
              var el = document.getElementById('wrap');
              if (el) el.style.height = size.height + 'px';
            },
            onclose: function(state) {
              if (state === 'FORCE_CLOSE') bridgeSend({ closed: true });
            },
            width: '100%',
            height: '100%'
          }).embed(wrap);
          attachPostcodeDoubleClickSelectAssist(wrap);
        } catch (e) {
          bridgeSend({ error: String(e) });
        }
      };
      script.onerror = function() {
        bridgeSend({ error: '우편번호 스크립트를 불러오지 못했습니다. 네트워크를 확인해 주세요.' });
      };
      document.head.appendChild(script);
    }
    /** WebView2가 chrome.webview를 주입한 뒤 실행되도록 load 이후에 카카오 스크립트 시작 */
    function scheduleLoadPostcode() {
      function run() {
        try {
          console.log('[yj_kakao] scheduleLoadPostcode 실행 readyState=' + document.readyState +
            ' chrome.webview=' + !!(window.chrome && window.chrome.webview));
        } catch (_) {}
        loadPostcode();
      }
      if (document.readyState === 'complete') {
        setTimeout(run, 0);
      } else {
        window.addEventListener('load', function onYL() {
          window.removeEventListener('load', onYL);
          setTimeout(run, 0);
        });
      }
    }
    scheduleLoadPostcode();
  </script>
</body>
</html>
''';
