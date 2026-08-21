// 전자결재 기안 — 결재선 슬롯·역할 배타 규칙.

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_approval_line.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

/// 결재 / 합의 / 참조 / 열람 한 줄 슬롯.
class EapComposeLinePick {
  List<String> names = List<String>.filled(kActivityApprovalLineSlotCount, '');
  List<String> titles = List<String>.filled(kActivityApprovalLineSlotCount, '');
  List<String> userIds = List<String>.filled(
    kActivityApprovalLineSlotCount,
    '',
  );

  void assignFrom(ActivityApprovalLineResult r) {
    names = List<String>.from(r.names);
    titles = List<String>.from(r.titles);
    userIds = List<String>.from(r.userIds);
  }

  Set<String> occupiedKeys() {
    final keys = <String>{};
    for (var i = 0; i < userIds.length; i++) {
      final id = userIds[i].trim();
      final nm = i < names.length ? names[i].trim() : '';
      if (id.isNotEmpty) keys.add(id.toUpperCase());
      if (nm.isNotEmpty) keys.add(nm.toUpperCase());
    }
    return keys;
  }

  int removeKeys(Set<String> keys) {
    if (keys.isEmpty) return 0;
    var n = 0;
    final newNames = List<String>.filled(kActivityApprovalLineSlotCount, '');
    final newTitles = List<String>.filled(kActivityApprovalLineSlotCount, '');
    final newIds = List<String>.filled(kActivityApprovalLineSlotCount, '');
    var w = 0;
    for (var i = 0; i < userIds.length; i++) {
      final id = userIds[i].trim();
      final nm = i < names.length ? names[i].trim() : '';
      final hit =
          (id.isNotEmpty && keys.contains(id.toUpperCase())) ||
          (nm.isNotEmpty && keys.contains(nm.toUpperCase()));
      if (hit) {
        n++;
        continue;
      }
      if (id.isEmpty && nm.isEmpty) continue;
      newIds[w] = userIds[i];
      newNames[w] = i < names.length ? names[i] : '';
      newTitles[w] = i < titles.length ? titles[i] : '';
      w++;
    }
    names = newNames;
    titles = newTitles;
    userIds = newIds;
    return n;
  }

  String get summary {
    final parts = <String>[];
    for (var i = 0; i < names.length; i++) {
      final nm = names[i].trim();
      if (nm.isEmpty) continue;
      final title = i < titles.length ? titles[i].trim() : '';
      parts.add(title.isEmpty ? nm : '$title $nm');
    }
    return parts.join(', ');
  }

  List<EapLineMember> toMembers(String roleCd, {int skipLeading = 0}) {
    final out = <EapLineMember>[];
    var order = 0;
    for (var i = skipLeading; i < userIds.length; i++) {
      final id = userIds[i].trim();
      final nm = i < names.length ? names[i].trim() : '';
      final uid = id.isNotEmpty ? id : nm;
      if (uid.isEmpty) continue;
      out.add(
        EapLineMember(
          roleCd: roleCd,
          sortOrder: order,
          userId: uid,
          userNm: nm.isNotEmpty ? nm : uid,
          titleNm: i < titles.length ? titles[i].trim() : '',
        ),
      );
      order++;
    }
    return out;
  }
}

/// 결재·합의·참조·열람 네 줄 + 기안자 제외·역할 배타 규칙.
class EapComposeLineSet {
  final approvers = EapComposeLinePick();
  final agreers = EapComposeLinePick();
  final ccs = EapComposeLinePick();
  final viewers = EapComposeLinePick();

  static Set<String> drafterKeys(AuthProvider auth) {
    final keys = <String>{};
    final id = auth.userId.trim();
    final name = auth.userName.trim();
    if (id.isNotEmpty) keys.add(id.toUpperCase());
    if (name.isNotEmpty) keys.add(name.toUpperCase());
    return keys;
  }

  int purgeDrafter(AuthProvider auth) {
    final keys = drafterKeys(auth);
    if (keys.isEmpty) return 0;
    return approvers.removeKeys(keys) +
        agreers.removeKeys(keys) +
        ccs.removeKeys(keys) +
        viewers.removeKeys(keys);
  }

  Set<String> blockedKeysFor(EapComposeLinePick pick, AuthProvider auth) {
    final blocked = drafterKeys(auth);
    if (identical(pick, approvers)) return blocked;
    if (identical(pick, agreers)) {
      blocked.addAll(approvers.occupiedKeys());
      return blocked;
    }
    if (identical(pick, ccs)) {
      blocked.addAll(approvers.occupiedKeys());
      blocked.addAll(agreers.occupiedKeys());
      return blocked;
    }
    blocked.addAll(approvers.occupiedKeys());
    blocked.addAll(agreers.occupiedKeys());
    blocked.addAll(ccs.occupiedKeys());
    return blocked;
  }

  /// 한 사람은 한 역할만. 결재 > 합의 > 참조 > 열람.
  int applyExclusiveRoles(EapComposeLinePick changed) {
    if (identical(changed, approvers)) {
      final ids = approvers.occupiedKeys();
      return agreers.removeKeys(ids) +
          ccs.removeKeys(ids) +
          viewers.removeKeys(ids);
    }
    if (identical(changed, agreers)) {
      final dropped = agreers.removeKeys(approvers.occupiedKeys());
      final ids = agreers.occupiedKeys();
      return dropped + ccs.removeKeys(ids) + viewers.removeKeys(ids);
    }
    if (identical(changed, ccs)) {
      final blocked = {...approvers.occupiedKeys(), ...agreers.occupiedKeys()};
      return ccs.removeKeys(blocked) + viewers.removeKeys(ccs.occupiedKeys());
    }
    final blocked = {
      ...approvers.occupiedKeys(),
      ...agreers.occupiedKeys(),
      ...ccs.occupiedKeys(),
    };
    return viewers.removeKeys(blocked);
  }

  List<EapLineMember> allLines(AuthProvider auth) {
    final drafter = drafterKeys(auth);
    final out = <EapLineMember>[
      ...approvers.toMembers('APPROVER'),
      ...agreers.toMembers('AGREE'),
      ...ccs.toMembers('CC'),
      ...viewers.toMembers('VIEWER'),
    ];
    return out.where((m) {
      final id = m.userId.trim().toUpperCase();
      final nm = m.userNm.trim().toUpperCase();
      if (id.isNotEmpty && drafter.contains(id)) return false;
      if (nm.isNotEmpty && drafter.contains(nm)) return false;
      return true;
    }).toList();
  }

  String get approvalSummary {
    String count(EapComposeLinePick pick) {
      var n = 0;
      for (final nm in pick.names) {
        if (nm.trim().isNotEmpty) n++;
      }
      return '$n명';
    }

    return '결재 ${count(approvers)} · '
        '합의 ${count(agreers)} · '
        '참조 ${count(ccs)} · '
        '열람 ${count(viewers)}';
  }
}
