// 메신저 공용 위젯·헬퍼 — 아바타, 시간 포맷, 색상 팔레트, 첨부 유틸.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

/// 이름 해시 기반 아바타 배경색 팔레트 (브랜드 톤과 어울리는 채도).
const List<Color> _kAvatarPalette = [
  Color(0xFFBC1F26), // brand red
  Color(0xFFE8743B),
  Color(0xFF2E86DE),
  Color(0xFF7C3AED),
  Color(0xFF16A085),
  Color(0xFFD81B60),
  Color(0xFF455A64),
  Color(0xFFF39C12),
];

Color chatColorFor(String seed) {
  if (seed.isEmpty) return AppTheme.accentRed;
  var hash = 0;
  for (final code in seed.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return _kAvatarPalette[hash % _kAvatarPalette.length];
}

String chatInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  // 첫 글자로 표시(영문은 대문자).
  return trimmed.characters.first.toUpperCase();
}

/// 원형 이니셜 아바타. 그룹방은 [isGroup] 으로 그룹 아이콘을 표시한다.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    this.isGroup = false,
    this.size = 46,
  });

  final String name;
  final bool isGroup;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = chatColorFor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.18)!],
        ),
      ),
      alignment: Alignment.center,
      child: isGroup
          ? Icon(Icons.groups_rounded, color: Colors.white, size: size * 0.5)
          : Text(
              chatInitials(name),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
              ),
            ),
    );
  }
}

/// 대화목록용 짧은 시간 표기 (오늘=시:분, 어제, 그 이전=월/일).
String formatChatListTime(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(time.year, time.month, time.day);
  final diffDays = today.difference(that).inDays;
  if (diffDays == 0) {
    final h = time.hour;
    final ampm = h < 12 ? '오전' : '오후';
    final hh = h % 12 == 0 ? 12 : h % 12;
    return '$ampm $hh:${time.minute.toString().padLeft(2, '0')}';
  }
  if (diffDays == 1) return '어제';
  if (time.year == now.year) return '${time.month}/${time.day}';
  return '${time.year % 100}.${time.month}.${time.day}';
}

/// 말풍선 옆 시간 (오전/오후 시:분).
String formatBubbleTime(DateTime time) {
  final h = time.hour;
  final ampm = h < 12 ? '오전' : '오후';
  final hh = h % 12 == 0 ? 12 : h % 12;
  return '$ampm $hh:${time.minute.toString().padLeft(2, '0')}';
}

/// 날짜 구분선 라벨 (예: 2026년 6월 18일 목요일).
String formatDateDivider(DateTime time) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final wd = weekdays[(time.weekday - 1) % 7];
  return '${time.year}년 ${time.month}월 ${time.day}일 $wd요일';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 파일명 확장자로 대략적인 MIME 타입을 추정한다. (없으면 null)
String? guessAttachmentContentType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.bmp')) return 'image/bmp';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  return null;
}

/// 바이트 크기를 사람이 읽기 좋은 단위로 변환.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB'];
  double size = bytes / 1024;
  var i = 0;
  while (size >= 1024 && i < units.length - 1) {
    size /= 1024;
    i++;
  }
  final v = size >= 10 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$v ${units[i]}';
}

/// 인라인 표시용 URL 에 download 플래그를 붙여 강제 다운로드 URL 을 만든다.
/// (이미지는 기본이 inline 이라 받아두려면 이 URL 을 쓴다.)
String forceDownloadUrl(String url) {
  return url.contains('?') ? '$url&download=true' : '$url?download=true';
}

/// 첨부 파일/이미지를 새 탭(웹) 또는 외부 앱에서 연다.
Future<void> openAttachment(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('첨부 열기 실패: $e');
  }
}
