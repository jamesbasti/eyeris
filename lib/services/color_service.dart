import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ColorResult {
  final String name;
  final Color color;
  final String hex;
  final double confidence;

  const ColorResult({
    required this.name,
    required this.color,
    required this.hex,
    required this.confidence,
  });
}

class ColorService {
  ColorService._();
  static final ColorService instance = ColorService._();

  // Print format info once so we can see what the device is sending
  bool _loggedFormat = false;

  static const List<(String, int, int, int)> _palette = [
    ('White',        255, 255, 255),
    ('Light Grey',   211, 211, 211),
    ('Silver',       192, 192, 192),
    ('Grey',         128, 128, 128),
    ('Dark Grey',     64,  64,  64),
    ('Charcoal',      54,  69,  79),
    ('Black',          0,   0,   0),
    ('Red',          220,  20,  60),
    ('Dark Red',     139,   0,   0),
    ('Coral',        255, 127,  80),
    ('Salmon',       250, 128, 114),
    ('Pink',         255, 182, 193),
    ('Hot Pink',     255, 105, 180),
    ('Deep Pink',    255,  20, 147),
    ('Orange',       255, 165,   0),
    ('Dark Orange',  255, 140,   0),
    ('Tomato',       255,  99,  71),
    ('Peach',        255, 218, 185),
    ('Yellow',       255, 255,   0),
    ('Gold',         255, 215,   0),
    ('Khaki',        240, 230, 140),
    ('Beige',        245, 245, 220),
    ('Cream',        255, 253, 208),
    ('Lime',         191, 255,   0),
    ('Green',          0, 128,   0),
    ('Lime Green',    50, 205,  50),
    ('Forest Green',  34, 139,  34),
    ('Dark Green',     0, 100,   0),
    ('Olive',        128, 128,   0),
    ('Teal',           0, 128, 128),
    ('Mint',         152, 255, 152),
    ('Sage',         176, 192, 172),
    ('Cyan',           0, 255, 255),
    ('Sky Blue',     135, 206, 235),
    ('Light Blue',   173, 216, 230),
    ('Blue',           0,   0, 255),
    ('Royal Blue',    65, 105, 225),
    ('Navy',           0,   0, 128),
    ('Dark Blue',      0,   0, 139),
    ('Steel Blue',    70, 130, 180),
    ('Slate Blue',   106,  90, 205),
    ('Violet',       238, 130, 238),
    ('Purple',       128,   0, 128),
    ('Dark Purple',   75,   0, 130),
    ('Lavender',     230, 230, 250),
    ('Magenta',      255,   0, 255),
    ('Brown',        165,  42,  42),
    ('Tan',          210, 180, 140),
    ('Sienna',       160,  82,  45),
  ];

  ColorResult? analyse(CameraImage image) {
    // ── Log format info once so we can diagnose in debug console ──
    if (!_loggedFormat) {
      _loggedFormat = true;
      debugPrint('ColorService: format=${image.format.group} '
          'planes=${image.planes.length} '
          'size=${image.width}x${image.height}');
      for (int i = 0; i < image.planes.length; i++) {
        final p = image.planes[i];
        debugPrint('  plane[$i]: bytesPerRow=${p.bytesPerRow} '
            'bytesPerPixel=${p.bytesPerPixel} '
            'bytes=${p.bytes.length}');
      }
    }

    final avg = _averageCentrePixels(image);
    if (avg == null) return null;

    debugPrint('ColorService: sampled avg R=${(avg.r * 255).round()} '
        'G=${(avg.g * 255).round()} B=${(avg.b * 255).round()}');

    return _nearestNamed(avg);
  }

  Color? _averageCentrePixels(CameraImage image) {
    try {
      final fmt = image.format.group;

      // ── Route by format ──────────────────────────────────────────
      // yuv420  = Android YUV_420_888
      // bgra8888 = iOS
      // nv21    = some Android devices report this explicitly
      // unknown  = fallback: check plane count to guess
      if (fmt == ImageFormatGroup.yuv420 ||
          fmt == ImageFormatGroup.nv21) {
        return _sampleYuv(image);
      } else if (fmt == ImageFormatGroup.bgra8888) {
        return _sampleBgra(image);
      } else {
        // Unknown format — use plane count as heuristic
        if (image.planes.length >= 3) {
          return _sampleYuv(image);
        } else {
          return _sampleBgra(image);
        }
      }
    } catch (e) {
      debugPrint('ColorService: sampling error — $e');
      return null;
    }
  }

  // ── YUV_420_888 ──────────────────────────────
  //
  // plane[0] = Y  full res, 1 byte/pixel
  // plane[1] = U (Cb) half res
  // plane[2] = V (Cr) half res
  //
  // bytesPerPixel on U/V tells us the interleave stride:
  //   1 = fully planar  (each byte is one U or V value)
  //   2 = semi-planar / NV12/NV21  (UV interleaved)
  //
  // ITU-R BT.601:
  //   R = clamp(Y + 1.402*(V-128))
  //   G = clamp(Y - 0.344*(U-128) - 0.714*(V-128))
  //   B = clamp(Y + 1.772*(U-128))

  Color? _sampleYuv(CameraImage image) {
    if (image.planes.length < 3) return null;

    final w  = image.width;
    final h  = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes  = yPlane.bytes;
    final uBytes  = uPlane.bytes;
    final vBytes  = vPlane.bytes;

    final yStride = yPlane.bytesPerRow;
    final uStride = uPlane.bytesPerRow;
    final vStride = vPlane.bytesPerRow;

    // bytesPerPixel is 1 for planar, 2 for semi-planar (interleaved UV)
    final uStep = uPlane.bytesPerPixel ?? 1;
    final vStep = vPlane.bytesPerPixel ?? 1;

    final x0 = (w * 0.30).round();
    final x1 = (w * 0.70).round();
    final y0 = (h * 0.30).round();
    final y1 = (h * 0.70).round();

    const steps = 5;
    final xStep = ((x1 - x0) / steps).round().clamp(1, w);
    final yStep = ((y1 - y0) / steps).round().clamp(1, h);

    int totalR = 0, totalG = 0, totalB = 0, count = 0;

    for (int y = y0; y < y1; y += yStep) {
      for (int x = x0; x < x1; x += xStep) {
        // Y index — full resolution
        final yIdx = y * yStride + x;
        if (yIdx >= yBytes.length) continue;

        // UV index — 2×2 subsampled
        final uvX = x ~/ 2;
        final uvY = y ~/ 2;
        final uIdx = uvY * uStride + uvX * uStep;
        final vIdx = uvY * vStride + uvX * vStep;

        if (uIdx >= uBytes.length || vIdx >= vBytes.length) continue;

        final yv = yBytes[yIdx] & 0xFF;
        final uv = (uBytes[uIdx] & 0xFF) - 128;
        final vv = (vBytes[vIdx] & 0xFF) - 128;

        final r = (yv + 1.402   * vv).round().clamp(0, 255);
        final g = (yv - 0.344136 * uv - 0.714136 * vv).round().clamp(0, 255);
        final b = (yv + 1.772   * uv).round().clamp(0, 255);

        totalR += r;
        totalG += g;
        totalB += b;
        count++;
      }
    }

    if (count == 0) return null;

    return Color.fromRGBO(
      totalR ~/ count,
      totalG ~/ count,
      totalB ~/ count,
      1.0,
    );
  }

  // ── BGRA_8888 (iOS) ──────────────────────────

  Color? _sampleBgra(CameraImage image) {
    final w      = image.width;
    final h      = image.height;
    final plane  = image.planes[0];
    final bytes  = plane.bytes;
    final stride = plane.bytesPerRow;

    if (bytes.isEmpty) return null;

    final x0 = (w * 0.30).round();
    final x1 = (w * 0.70).round();
    final y0 = (h * 0.30).round();
    final y1 = (h * 0.70).round();

    const steps = 5;
    final xStep = ((x1 - x0) / steps).round().clamp(1, w);
    final yStep = ((y1 - y0) / steps).round().clamp(1, h);

    int totalR = 0, totalG = 0, totalB = 0, count = 0;

    for (int y = y0; y < y1; y += yStep) {
      for (int x = x0; x < x1; x += xStep) {
        final idx = y * stride + x * 4;
        if (idx + 2 >= bytes.length) continue;
        totalB += bytes[idx];
        totalG += bytes[idx + 1];
        totalR += bytes[idx + 2];
        count++;
      }
    }

    if (count == 0) return null;

    return Color.fromRGBO(
      totalR ~/ count,
      totalG ~/ count,
      totalB ~/ count,
      1.0,
    );
  }

  // ── Nearest named colour ─────────────────────

  ColorResult _nearestNamed(Color avg) {
    String bestName = 'Unknown';
    double bestDist = double.infinity;
    int bestR = 128, bestG = 128, bestB = 128;

    final ar = (avg.r * 255.0).round();
    final ag = (avg.g * 255.0).round();
    final ab = (avg.b * 255.0).round();

    for (final (name, r, g, b) in _palette) {
      final dr = (ar - r).toDouble();
      final dg = (ag - g).toDouble();
      final db = (ab - b).toDouble();
      final dist = (dr * dr * 0.299) + (dg * dg * 0.587) + (db * db * 0.114);
      if (dist < bestDist) {
        bestDist = dist;
        bestName = name;
        bestR = r; bestG = g; bestB = b;
      }
    }

    final confidence = (1.0 - (bestDist / 65025.0)).clamp(0.0, 1.0);

    final hex =
        '#${bestR.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${bestG.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${bestB.toRadixString(16).padLeft(2, '0').toUpperCase()}';

    return ColorResult(
      name:       bestName,
      color:      Color.fromRGBO(bestR, bestG, bestB, 1.0),
      hex:        hex,
      confidence: confidence,
    );
  }
}
