import 'dart:math' as math;

class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  double distanceTo(Point2D other) {
    return math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));
  }

  @override
  String toString() => 'POINT($x $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point2D &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class BoundingBox2D {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const BoundingBox2D(this.minX, this.minY, this.maxX, this.maxY);

  bool contains(Point2D point) {
    return point.x >= minX &&
        point.x <= maxX &&
        point.y >= minY &&
        point.y <= maxY;
  }

  bool intersects(BoundingBox2D other) {
    return !(other.minX > maxX ||
        other.maxX < minX ||
        other.minY > maxY ||
        other.maxY < minY);
  }

  double area() {
    return (maxX - minX) * (maxY - minY);
  }

  BoundingBox2D expandToInclude(BoundingBox2D other) {
    return BoundingBox2D(
      math.min(minX, other.minX),
      math.min(minY, other.minY),
      math.max(maxX, other.maxX),
      math.max(maxY, other.maxY),
    );
  }

  @override
  String toString() => 'BBOX($minX, $minY, $maxX, $maxY)';
}

class Polygon2D {
  final List<Point2D> points;

  Polygon2D(this.points) {
    if (points.length < 3) {
      throw ArgumentError('A polygon must have at least 3 points');
    }
  }

  BoundingBox2D get boundingBox {
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (var point in points) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    return BoundingBox2D(minX, minY, maxX, maxY);
  }

  bool contains(Point2D point) {
    if (!boundingBox.contains(point)) return false;

    bool inside = false;
    for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
      if ((points[i].y > point.y) != (points[j].y > point.y) &&
          point.x <
              (points[j].x - points[i].x) *
                      (point.y - points[i].y) /
                      (points[j].y - points[i].y) +
                  points[i].x) {
        inside = !inside;
      }
    }
    return inside;
  }
}
