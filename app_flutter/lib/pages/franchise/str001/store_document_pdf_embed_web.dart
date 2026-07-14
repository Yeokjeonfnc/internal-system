// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

final Map<String, String> _pdfBlobUrlsByViewType = {};

Widget buildStoreDocumentPdfEmbed({
  required Uint8List bytes,
  required String viewType,
}) {
  _revokePdfBlobUrl(viewType);
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  _pdfBlobUrlsByViewType[viewType] = url;

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    return iframe;
  });

  return HtmlElementView(viewType: viewType);
}

void revokeStoreDocumentPdfEmbed(String viewType) {
  _revokePdfBlobUrl(viewType);
}

void _revokePdfBlobUrl(String viewType) {
  final url = _pdfBlobUrlsByViewType.remove(viewType);
  if (url != null) {
    html.Url.revokeObjectUrl(url);
  }
}
