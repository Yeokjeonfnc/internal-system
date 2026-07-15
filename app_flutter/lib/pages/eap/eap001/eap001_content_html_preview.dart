// 전자결재 본문 HTML 미리보기 entry (web / 그 외).

import 'package:flutter/widgets.dart';

import 'package:app_flutter/pages/eap/eap001/eap001_content_html_preview_stub.dart'
    if (dart.library.html) 'package:app_flutter/pages/eap/eap001/eap001_content_html_preview_web.dart'
    as impl;

Widget eapContentHtmlPreview(String htmlBody) =>
    impl.buildEapContentHtmlPreview(htmlBody);
