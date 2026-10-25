import 'package:flutter/foundation.dart';

@immutable
class ResizeEdges {
  const ResizeEdges({
    this.left = false,
    this.top = false,
    this.right = false,
    this.bottom = false,
  });

  final bool left;
  final bool top;
  final bool right;
  final bool bottom;

  static const ResizeEdges topEdge = ResizeEdges(top: true);
  static const ResizeEdges bottomEdge = ResizeEdges(bottom: true);
  static const ResizeEdges leftEdge = ResizeEdges(left: true);
  static const ResizeEdges rightEdge = ResizeEdges(right: true);
  static const ResizeEdges topLeft = ResizeEdges(top: true, left: true);
  static const ResizeEdges topRight = ResizeEdges(top: true, right: true);
  static const ResizeEdges bottomLeft = ResizeEdges(bottom: true, left: true);
  static const ResizeEdges bottomRight =
      ResizeEdges(bottom: true, right: true);
}
