// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'package:app_flutter/core/address/kakao_address_coordinate_result.dart';
import 'package:app_flutter/core/map/kakao_map_app_key.dart';
import 'package:app_flutter/core/map/kakao_map_app_key_io.dart';

const String _kMsgPrefix = 'yj_ac_v1|';

Uri _addressCoordinatePickerPageUri({
  required String appKey,
  double? lat,
  double? lng,
  String? address,
}) {
  final origin = html.window.location.origin;
  final baseHref =
      html.document.querySelector('base')?.getAttribute('href') ?? '/';
  final uri = Uri.parse(
    origin,
  ).resolve(baseHref).resolve('kakao_address_coordinate_picker.html');

  final params = <String, String>{'v': '20260608d'};
  if (appKey.isNotEmpty) params['appkey'] = appKey;
  if (lat != null) params['lat'] = lat.toString();
  if (lng != null) params['lng'] = lng.toString();
  final q = address?.trim() ?? '';
  if (q.isNotEmpty) params['address'] = q;
  return uri.replace(queryParameters: params);
}

Future<KakaoAddressCoordinateResult?> showKakaoAddressCoordinatePicker(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  String? initialAddress,
}) async {
  syncKakaoMapAppKeyToLocalStorage();
  final appKey = resolveKakaoMapAppKey(
    localStorageValue: readKakaoMapAppKeyFromLocalStorage(),
  );
  if (!context.mounted) return null;
  return showDialog<KakaoAddressCoordinateResult>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final w = (size.width - 48).clamp(720.0, 880.0);
      const h = 620.0;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: w,
          height: h,
          child: _KakaoAddressCoordinateIframeBody(
            dialogContext: dialogContext,
            pageUri: _addressCoordinatePickerPageUri(
              appKey: appKey,
              lat: initialLatitude,
              lng: initialLongitude,
              address: initialAddress,
            ),
          ),
        ),
      );
    },
  );
}

class _KakaoAddressCoordinateIframeBody extends StatefulWidget {
  const _KakaoAddressCoordinateIframeBody({
    required this.dialogContext,
    required this.pageUri,
  });

  final BuildContext dialogContext;
  final Uri pageUri;

  @override
  State<_KakaoAddressCoordinateIframeBody> createState() =>
      _KakaoAddressCoordinateIframeBodyState();
}

class _KakaoAddressCoordinateIframeBodyState
    extends State<_KakaoAddressCoordinateIframeBody> {
  late final String _viewType;
  StreamSubscription<html.MessageEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _viewType =
        'yeokjeon-kakao-addr-coord-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    final navigator = Navigator.of(widget.dialogContext);
    final messenger = ScaffoldMessenger.maybeOf(widget.dialogContext);

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..src = widget.pageUri.toString();
      return iframe;
    });

    _sub = html.window.onMessage.listen((event) {
      if (event.origin != html.window.location.origin) return;
      final raw = event.data;
      if (raw is! String || !raw.startsWith(_kMsgPrefix)) return;
      try {
        final payload = jsonDecode(raw.substring(_kMsgPrefix.length));
        if (payload is! Map) return;
        final map = Map<String, dynamic>.from(payload);
        if (map['error'] != null) {
          messenger?.showSnackBar(SnackBar(content: Text('${map['error']}')));
          return;
        }
        final op = map['op']?.toString() ?? '';
        if (op == 'CLOSE') {
          navigator.pop();
          return;
        }
        if (op == 'SELECT') {
          final lat = (map['latitude'] as num?)?.toDouble();
          final lng = (map['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) return;
          navigator.pop(KakaoAddressCoordinateResult.fromJson(map));
          return;
        }
      } catch (_) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('주소·좌표 정보를 처리하지 못했습니다.')),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
