// 다우오피스 전자결재 연동 — SPA 경로 상수.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

abstract final class EapRoutes {
  static const String root = '/eap';
  static const String home = '$root/home';

  // 결재하기
  static const String pending = '$root/pending';
  static const String received = '$root/received';
  static const String ccPending = '$root/cc-pending';
  static const String scheduled = '$root/scheduled';

  // 개인 문서함
  static const String drafted = '$root/drafted';
  static const String tempSaved = '$root/temp-saved';
  static const String approved = '$root/approved';
  static const String ccRead = '$root/cc-read';
  static const String inbox = '$root/inbox';
  static const String sent = '$root/sent';
  static const String official = '$root/official';

  // 설정
  static const String settings = '$root/settings';

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
    if (path == home || path == root) return '전자결재 홈';
    if (path == pending) return '결재 대기 문서';
    if (path == received) return '결재 수신 문서';
    if (path == ccPending) return '참조/열람 대기 문서';
    if (path == scheduled) return '결재 예정 문서';
    if (path == drafted) return '기안 문서함';
    if (path == tempSaved) return '임시 저장함';
    if (path == approved) return '결재 문서함';
    if (path == ccRead) return '참조/열람 문서함';
    if (path == inbox) return '수신 문서함';
    if (path == sent) return '발송 문서함';
    if (path == official) return '공문 문서함';
    if (path == settings) return '전자결재 환경설정';
    return '전자결재';
  }

  static String? parentFor(String path) {
    if (docIdFromPath(path) != null) return home;
    if (path == home || path == root) return '/';
    return home;
  }

  static void openDocument(BuildContext context, EapDocument doc) {
    context.push(documentDetail(doc.docId));
  }
}
