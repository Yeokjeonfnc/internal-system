import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'package:app_flutter/core/address/kakao_postcode_browser_standalone_html.dart';

/// 임시 HTML 파일(embed 포함)을 열어 카카오 우편번호 검색을 쓸 수 있게 한다.
/// 도메인 루트 직접 접근은 "잘못된 접근"으로 막히므로 이 방식이 필요하다.
Future<bool> launchKakaoPostcodeStandaloneInBrowser() async {
  final dir = Directory.systemTemp.createTempSync('yj_kakao_pc');
  final file = File('${dir.path}/kakao_postcode.html');
  await file.writeAsString(kKakaoPostcodeBrowserStandaloneHtml, flush: true);
  final uri = Uri.file(file.path, windows: Platform.isWindows);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
