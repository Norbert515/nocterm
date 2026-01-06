import 'package:nocterm/nocterm.dart';

/// Rectangle area
class Rect {
  const Rect.fromLTWH(this.left, this.top, this.width, this.height);

  const Rect.fromLTRB(this.left, this.top, double right, double bottom)
    : width = right - left,
      height = bottom - top;

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  bool contains(Offset offset) {
    return offset.dx >= left &&
        offset.dx < right &&
        offset.dy >= top &&
        offset.dy < bottom;
  }

  Rect translate(double dx, double dy) {
    return Rect.fromLTWH(left + dx, top + dy, width, height);
  }

  Rect inner(double margin) {
    if (margin * 2 >= width || margin * 2 >= height) {
      return Rect.fromLTWH(left, top, 0, 0);
    }
    return Rect.fromLTWH(
      left + margin,
      top + margin,
      width - margin * 2,
      height - margin * 2,
    );
  }

  @override
  String toString() => 'Rect.fromLTWH($left, $top, $width, $height)';
}
