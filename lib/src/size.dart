class Size {
  const Size(this.width, this.height);

  final double width;
  final double height;

  static const Size zero = Size(0, 0);
  static const Size infinite = Size(double.infinity, double.infinity);

  @override
  String toString() => 'Size($width, $height)';

  @override
  bool operator ==(covariant Size other) {
    if (identical(this, other)) return true;

    return other.width == width && other.height == height;
  }

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}
