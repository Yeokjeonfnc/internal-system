// 자체 전자결재 — SPA 경로 상수.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

abstract final class EapRoutes {
  static const String root = '/eap';

  static const String home = '$root/home';
  static const String compose = '$root/compose';
  static const String inbox = '$root/inbox';
  static const String sent = '$root/sent';
  static const String cc = '$root/cc';
  static const String all = '$root/all';

  static const String forms = '$root/forms';
  static const String formNew = '$root/forms/new';

  static String formEdit(String formCode) =>
      '$root/forms/edit/${Uri.encodeComponent(formCode)}';

  static String composeWith(String formCode) =>
      '$compose?form=${Uri.encodeQueryComponent(formCode)}';

  static String? formCodeFromEditPath(String path) {
    const prefix = '$root/forms/edit/';
    if (!path.startsWith(prefix)) return null;
    return Uri.decodeComponent(path.substring(prefix.length));
  }

  static String documentDetail(String docId) => '$root/doc/$docId';

  static String? docIdFromPath(String path) {
    const prefix = '$root/doc/';
    if (!path.startsWith(prefix)) return null;
    final id = path.substring(prefix.length);
    return id.isEmpty ? null : id;
  }

  static String titleFor(String path) {
    final docId = docIdFromPath(path);
    if (docId != null) return '전자결재 상세';
    if (path == home || path == root) return '전자결재';
    if (path == compose) return '기안하기';
    if (path == inbox) return '받은결재';
    if (path == sent) return '올린결재';
    if (path == cc) return '수신참조결재';
    if (path == all) return '전체문서';
    if (path == forms) return '서식 관리';
    if (path == formNew) return '서식 등록';
    if (formCodeFromEditPath(path) != null) return '서식 수정';
    return '전자결재';
  }

  static String? parentFor(String path) {
    if (docIdFromPath(path) != null) return inbox;
    if (path == formNew || formCodeFromEditPath(path) != null) return forms;
    if (path == forms) return home;
    if (path == home || path == root) return '/';
    if (path == compose ||
        path == inbox ||
        path == sent ||
        path == cc ||
        path == all) {
      return home;
    }
    return home;
  }

  static void openDocument(BuildContext context, EapDocument doc) {
    context.push(documentDetail(doc.docId));
  }
}
