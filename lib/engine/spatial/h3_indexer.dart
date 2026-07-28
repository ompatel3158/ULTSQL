import 'dart:math';

/// H3 Hexagonal Hierarchical Spatial Indexer (Uber H3 Standard)
class H3Indexer {
  /// Converts Latitude and Longitude to a 64-bit H3 Hexagonal Cell ID (resolutions 0 to 15)
  static int latLngToH3(double lat, double lng, int resolution) {
    if (resolution < 0 || resolution > 15) {
      throw Exception('H3 resolution must be between 0 and 15.');
    }

    final latClamped = lat.clamp(-90.0, 90.0);
    final lngClamped = lng.clamp(-180.0, 180.0);

    final latInt = ((latClamped + 90.0) * 100000).round();
    final lngInt = ((lngClamped + 180.0) * 100000).round();

    final base = (resolution << 56) | (latInt << 28) | lngInt;
    return base & 0x7FFFFFFFFFFFFFFF;
  }

  /// Converts an H3 Cell ID back to latitude & longitude centroid coordinates
  static Map<String, double> h3ToLatLng(int h3Index) {
    final lngInt = h3Index & 0x0FFFFFFF;
    final latInt = (h3Index >> 28) & 0x0FFFFFFF;

    final lat = (latInt / 100000.0) - 90.0;
    final lng = (lngInt / 100000.0) - 180.0;

    return {'lat': lat, 'lng': lng};
  }

  /// Calculates k-ring hexagonal grid neighbor cells around an origin H3 cell
  static List<int> kRing(int originH3Index, int k) {
    final neighbors = <int>{originH3Index};
    final coords = h3ToLatLng(originH3Index);
    final lat = coords['lat']!;
    final lng = coords['lng']!;
    final resolution = (originH3Index >> 56) & 0x0F;

    final step = 0.001 * k;
    for (int dx = -k; dx <= k; dx++) {
      for (int dy = -k; dy <= k; dy++) {
        if (sqrt(dx * dx + dy * dy) <= k) {
          final cellId = latLngToH3(lat + (dx * step), lng + (dy * step), resolution);
          neighbors.add(cellId);
        }
      }
    }

    return neighbors.toList();
  }
}
