// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

const String _kKakaoMapJavaScriptKey = String.fromEnvironment(
  'KAKAO_MAP_JAVASCRIPT_KEY',
);

Uri salesAreaMapEmbedPageUri() {
  final origin = html.window.location.origin;
  final baseHref =
      html.document.querySelector('base')?.getAttribute('href') ?? '/';
  final uri = Uri.parse(
    origin,
  ).resolve(baseHref).resolve('kakao_sales_area_map.html');

  if (_kKakaoMapJavaScriptKey.trim().isEmpty) {
    return uri;
  }
  return uri.replace(queryParameters: {'appkey': _kKakaoMapJavaScriptKey});
}

class SalesAreaSearchMapFrame extends StatefulWidget {
  const SalesAreaSearchMapFrame({super.key});

  @override
  State<SalesAreaSearchMapFrame> createState() =>
      _SalesAreaSearchMapFrameState();
}

class _SalesAreaSearchMapFrameState extends State<SalesAreaSearchMapFrame> {
  late final String _viewType;
  late final String _embedSrc;

  @override
  void initState() {
    super.initState();
    _viewType =
        'yeokjeon-sales-area-map-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    _embedSrc = salesAreaMapEmbedPageUri().toString();

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..src = _embedSrc;
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
