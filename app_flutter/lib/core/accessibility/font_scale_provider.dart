import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontScaleProvider extends ChangeNotifier {
  static const _preferenceKey = 'appFontScale';
  static const minScale = 0.90;
  static const maxScale = 1.25;
  static const defaultScale = 1.0;

  double _scale = defaultScale;
  double get scale => _scale;
  int get percentage => (_scale * 100).round();

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = _clamp(prefs.getDouble(_preferenceKey) ?? defaultScale);
    notifyListeners();
  }

  Future<void> increase() => setScale(_scale + 0.05);
  Future<void> decrease() => setScale(_scale - 0.05);
  Future<void> reset() => setScale(defaultScale);

  Future<void> setScale(double value) async {
    final next = _clamp(value);
    if ((next - _scale).abs() < 0.001) return;
    _scale = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_preferenceKey, _scale);
  }

  static double _clamp(double value) => value.clamp(minScale, maxScale);
}
