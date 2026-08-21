import 'dart:ui';

final class ReaderPinchFontScaleController {
  ReaderPinchFontScaleController({
    required this.minFontScale,
    required this.maxFontScale,
  }) : assert(minFontScale > 0),
       assert(maxFontScale >= minFontScale);

  final double minFontScale;
  final double maxFontScale;

  final Map<int, Offset> _pointers = <int, Offset>{};
  int? _firstPointer;
  int? _secondPointer;
  double? _initialDistance;
  double? _baseFontScale;
  double? _currentFontScale;

  bool get isActive => _initialDistance != null;

  bool addPointer({
    required int pointer,
    required Offset position,
    required double baseFontScale,
  }) {
    if (_pointers.containsKey(pointer) || _pointers.length >= 2) {
      return false;
    }
    _pointers[pointer] = position;
    if (_pointers.length != 2) return false;

    final pointers = _pointers.keys.toList(growable: false);
    final distance =
        (_pointers[pointers[0]]! - _pointers[pointers[1]]!).distance;
    if (distance <= 0) return false;

    _firstPointer = pointers[0];
    _secondPointer = pointers[1];
    _initialDistance = distance;
    _baseFontScale = baseFontScale.clamp(minFontScale, maxFontScale);
    _currentFontScale = _baseFontScale;
    return true;
  }

  double? updatePointer({required int pointer, required Offset position}) {
    if (!_pointers.containsKey(pointer)) return null;
    _pointers[pointer] = position;
    if (!isActive || (pointer != _firstPointer && pointer != _secondPointer)) {
      return null;
    }

    final distance =
        (_pointers[_firstPointer]! - _pointers[_secondPointer]!).distance;
    final nextScale = (_baseFontScale! * distance / _initialDistance!).clamp(
      minFontScale,
      maxFontScale,
    );
    _currentFontScale = nextScale;
    return nextScale;
  }

  double? removePointer(int pointer, {required bool commit}) {
    if (!_pointers.containsKey(pointer)) return null;
    if (isActive && (pointer == _firstPointer || pointer == _secondPointer)) {
      final committedScale = commit ? _currentFontScale : null;
      reset();
      return committedScale;
    }
    _pointers.remove(pointer);
    return null;
  }

  void reset() {
    _pointers.clear();
    _firstPointer = null;
    _secondPointer = null;
    _initialDistance = null;
    _baseFontScale = null;
    _currentFontScale = null;
  }
}
