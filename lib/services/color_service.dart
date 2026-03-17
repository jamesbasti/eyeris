import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// COLOR RESULT MODELS
// ─────────────────────────────────────────────

class ColorResult {
  final String name;
  final Color color;
  final String hex;
  final double confidence;
  final String category; // warm, cool, neutral

  const ColorResult({
    required this.name,
    required this.color,
    required this.hex,
    required this.confidence,
    this.category = 'neutral',
  });
}

class DetectedColor {
  final ColorResult color;
  final double percentage;
  final String position; // center, top, bottom, left, right, etc.

  const DetectedColor({
    required this.color,
    required this.percentage,
    required this.position,
  });
}

class MultiColorResult {
  final DetectedColor dominant;
  final List<DetectedColor> secondary;
  final List<DetectedColor> all;

  const MultiColorResult({
    required this.dominant,
    required this.secondary,
    required this.all,
  });

  /// Get a simple description like "Navy Blue with White accents"
  String get simpleDescription {
    if (secondary.isEmpty) {
      return dominant.color.name;
    }
    final accents = secondary.map((c) => c.color.name).join(' and ');
    return '${dominant.color.name} with $accents accents';
  }
}

// ─────────────────────────────────────────────
// COLOR SERVICE
// ─────────────────────────────────────────────

class ColorService {
  ColorService._();
  static final ColorService instance = ColorService._();

  bool _loggedFormat = false;

  // ── EXPANDED COLOR PALETTE (150+ colors) ──────────────────────────
  // Format: (name, R, G, B, category)
  // Categories: 'warm', 'cool', 'neutral'
  
  static const List<(String, int, int, int, String)> _palette = [
    // ── Whites & Greys (Neutral) ──
    ('White',           255, 255, 255, 'neutral'),
    ('Snow',            255, 250, 250, 'neutral'),
    ('Ivory',           255, 255, 240, 'neutral'),
    ('Linen',           250, 240, 230, 'neutral'),
    ('Antique White',   250, 235, 215, 'neutral'),
    ('Light Grey',      211, 211, 211, 'neutral'),
    ('Silver',          192, 192, 192, 'neutral'),
    ('Grey',            128, 128, 128, 'neutral'),
    ('Dim Grey',        105, 105, 105, 'neutral'),
    ('Dark Grey',        64,  64,  64, 'neutral'),
    ('Charcoal',         54,  69,  79, 'neutral'),
    ('Slate Grey',      112, 128, 144, 'neutral'),
    ('Black',             0,   0,   0, 'neutral'),
    
    // ── Reds (Warm) ──
    ('Red',             255,   0,   0, 'warm'),
    ('Crimson',         220,  20,  60, 'warm'),
    ('Dark Red',        139,   0,   0, 'warm'),
    ('Maroon',          128,   0,   0, 'warm'),
    ('Burgundy',        128,   0,  32, 'warm'),
    ('Wine',            114,  47,  55, 'warm'),
    ('Scarlet',         255,  36,   0, 'warm'),
    ('Ruby',            224,  17,  95, 'warm'),
    ('Cherry',          222,  49,  99, 'warm'),
    ('Brick Red',       203,  65,  84, 'warm'),
    ('Indian Red',      205,  92,  92, 'warm'),
    ('Fire Brick',      178,  34,  34, 'warm'),
    
    // ── Pinks (Warm) ──
    ('Pink',            255, 192, 203, 'warm'),
    ('Light Pink',      255, 182, 193, 'warm'),
    ('Hot Pink',        255, 105, 180, 'warm'),
    ('Deep Pink',       255,  20, 147, 'warm'),
    ('Fuchsia',         255,   0, 255, 'warm'),
    ('Rose',            255,   0, 127, 'warm'),
    ('Blush',           222,  93, 131, 'warm'),
    ('Salmon',          250, 128, 114, 'warm'),
    ('Coral',           255, 127,  80, 'warm'),
    ('Light Coral',     240, 128, 128, 'warm'),
    ('Dusty Rose',      194, 134, 134, 'warm'),
    ('Mauve',           224, 176, 255, 'warm'),
    
    // ── Oranges (Warm) ──
    ('Orange',          255, 165,   0, 'warm'),
    ('Dark Orange',     255, 140,   0, 'warm'),
    ('Tangerine',       255, 128,   0, 'warm'),
    ('Burnt Orange',    204,  85,   0, 'warm'),
    ('Rust',            183,  65,  14, 'warm'),
    ('Copper',          184, 115,  51, 'warm'),
    ('Terracotta',      226, 114,  91, 'warm'),
    ('Peach',           255, 218, 185, 'warm'),
    ('Apricot',         251, 206, 177, 'warm'),
    ('Tomato',          255,  99,  71, 'warm'),
    ('Persimmon',       236,  88,   0, 'warm'),
    
    // ── Yellows (Warm) ──
    ('Yellow',          255, 255,   0, 'warm'),
    ('Light Yellow',    255, 255, 224, 'warm'),
    ('Lemon',           255, 247,   0, 'warm'),
    ('Gold',            255, 215,   0, 'warm'),
    ('Golden Yellow',   255, 223,   0, 'warm'),
    ('Mustard',         255, 219,  88, 'warm'),
    ('Amber',           255, 191,   0, 'warm'),
    ('Honey',           235, 177,  32, 'warm'),
    ('Khaki',           240, 230, 140, 'warm'),
    ('Dark Khaki',      189, 183, 107, 'warm'),
    ('Cream',           255, 253, 208, 'neutral'),
    ('Beige',           245, 245, 220, 'neutral'),
    ('Champagne',       247, 231, 206, 'neutral'),
    
    // ── Browns (Warm) ──
    ('Brown',           165,  42,  42, 'warm'),
    ('Dark Brown',      101,  67,  33, 'warm'),
    ('Chocolate',       123,  63,   0, 'warm'),
    ('Coffee',          111,  78,  55, 'warm'),
    ('Espresso',         75,  54,  33, 'warm'),
    ('Mocha',           150, 105,  70, 'warm'),
    ('Tan',             210, 180, 140, 'warm'),
    ('Camel',           193, 154, 107, 'warm'),
    ('Sand',            194, 178, 128, 'warm'),
    ('Taupe',           139, 133, 120, 'neutral'),
    ('Sienna',          160,  82,  45, 'warm'),
    ('Saddle Brown',    139,  69,  19, 'warm'),
    ('Chestnut',        149,  69,  53, 'warm'),
    ('Mahogany',        192,  64,   0, 'warm'),
    
    // ── Greens (Cool) ──
    ('Green',             0, 128,   0, 'cool'),
    ('Lime',              0, 255,   0, 'cool'),
    ('Lime Green',       50, 205,  50, 'cool'),
    ('Light Green',     144, 238, 144, 'cool'),
    ('Pale Green',      152, 251, 152, 'cool'),
    ('Spring Green',      0, 255, 127, 'cool'),
    ('Mint',            152, 255, 152, 'cool'),
    ('Seafoam',         159, 226, 191, 'cool'),
    ('Sage',            176, 192, 172, 'cool'),
    ('Forest Green',     34, 139,  34, 'cool'),
    ('Dark Green',        0, 100,   0, 'cool'),
    ('Hunter Green',     53,  94,  59, 'cool'),
    ('Emerald',          80, 200, 120, 'cool'),
    ('Jade',              0, 168, 107, 'cool'),
    ('Olive',           128, 128,   0, 'cool'),
    ('Dark Olive',       85, 107,  47, 'cool'),
    ('Army Green',      107, 142,  35, 'cool'),
    ('Kelly Green',      76, 187,  23, 'cool'),
    ('Chartreuse',      127, 255,   0, 'cool'),
    
    // ── Teals & Cyans (Cool) ──
    ('Teal',              0, 128, 128, 'cool'),
    ('Dark Teal',         0, 102, 102, 'cool'),
    ('Cyan',              0, 255, 255, 'cool'),
    ('Aqua',              0, 255, 255, 'cool'),
    ('Turquoise',        64, 224, 208, 'cool'),
    ('Dark Turquoise',    0, 206, 209, 'cool'),
    ('Aquamarine',      127, 255, 212, 'cool'),
    ('Light Cyan',      224, 255, 255, 'cool'),
    
    // ── Blues (Cool) ──
    ('Blue',              0,   0, 255, 'cool'),
    ('Light Blue',      173, 216, 230, 'cool'),
    ('Sky Blue',        135, 206, 235, 'cool'),
    ('Baby Blue',       137, 207, 240, 'cool'),
    ('Powder Blue',     176, 224, 230, 'cool'),
    ('Cornflower Blue', 100, 149, 237, 'cool'),
    ('Steel Blue',       70, 130, 180, 'cool'),
    ('Dodger Blue',      30, 144, 255, 'cool'),
    ('Royal Blue',       65, 105, 225, 'cool'),
    ('Cobalt',            0,  71, 171, 'cool'),
    ('Navy',              0,   0, 128, 'cool'),
    ('Dark Blue',         0,   0, 139, 'cool'),
    ('Midnight Blue',    25,  25, 112, 'cool'),
    ('Denim',            21,  96, 189, 'cool'),
    ('Slate Blue',      106,  90, 205, 'cool'),
    ('Periwinkle',      204, 204, 255, 'cool'),
    
    // ── Purples & Violets (Cool) ──
    ('Purple',          128,   0, 128, 'cool'),
    ('Dark Purple',      75,   0, 130, 'cool'),
    ('Violet',          238, 130, 238, 'cool'),
    ('Lavender',        230, 230, 250, 'cool'),
    ('Lilac',           200, 162, 200, 'cool'),
    ('Orchid',          218, 112, 214, 'cool'),
    ('Plum',            221, 160, 221, 'cool'),
    ('Magenta',         255,   0, 255, 'cool'),
    ('Indigo',           75,   0, 130, 'cool'),
    ('Amethyst',        153, 102, 204, 'cool'),
    ('Grape',           111,  45, 168, 'cool'),
    ('Eggplant',         97,  64,  81, 'cool'),
    ('Wine Purple',     112,  41,  99, 'cool'),
    
    // ── Metallics (Neutral) ──
    ('Bronze',          205, 127,  50, 'neutral'),
    ('Brass',           181, 166,  66, 'neutral'),
    ('Copper Metallic', 184, 115,  51, 'neutral'),
    ('Rose Gold',       183, 110, 121, 'neutral'),
    ('Platinum',        229, 228, 226, 'neutral'),
    ('Pewter',          150, 150, 150, 'neutral'),
    
    // ── Skin Tones (Neutral) ──
    ('Fair Skin',       255, 224, 196, 'neutral'),
    ('Light Skin',      255, 205, 148, 'neutral'),
    ('Medium Skin',     224, 172, 105, 'neutral'),
    ('Olive Skin',      198, 166, 100, 'neutral'),
    ('Tan Skin',        190, 136,  80, 'neutral'),
    ('Brown Skin',      141,  85,  36, 'neutral'),
    ('Dark Skin',        89,  47,  42, 'neutral'),
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

  // ── Nearest named colour using CIE76 LAB distance ─────────────────────

  ColorResult _nearestNamed(Color avg) {
    String bestName = 'Unknown';
    String bestCategory = 'neutral';
    double bestDist = double.infinity;
    int bestR = 128, bestG = 128, bestB = 128;

    final ar = (avg.r * 255.0).round();
    final ag = (avg.g * 255.0).round();
    final ab = (avg.b * 255.0).round();

    // Convert input to LAB for perceptually uniform comparison
    final labInput = _rgbToLab(ar, ag, ab);

    for (final (name, r, g, b, category) in _palette) {
      final labPalette = _rgbToLab(r, g, b);
      final dist = _labDistance(labInput, labPalette);
      
      if (dist < bestDist) {
        bestDist = dist;
        bestName = name;
        bestCategory = category;
        bestR = r; bestG = g; bestB = b;
      }
    }

    // CIE76 distance: 0 = perfect match, ~100 = very different
    // Convert to 0-1 confidence (distances > 50 are considered low confidence)
    final confidence = (1.0 - (bestDist / 100.0)).clamp(0.0, 1.0);

    final hex =
        '#${bestR.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${bestG.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${bestB.toRadixString(16).padLeft(2, '0').toUpperCase()}';

    return ColorResult(
      name:       bestName,
      color:      Color.fromRGBO(bestR, bestG, bestB, 1.0),
      hex:        hex,
      confidence: confidence,
      category:   bestCategory,
    );
  }

  /// Analyze a single Color object and return the nearest named color
  ColorResult? analyzeColor(Color color) {
    return _nearestNamed(color);
  }

  // ── RGB to LAB conversion for perceptually uniform color distance ──

  List<double> _rgbToLab(int r, int g, int b) {
    // RGB to XYZ
    double rn = r / 255.0;
    double gn = g / 255.0;
    double bn = b / 255.0;

    rn = rn > 0.04045 ? math.pow((rn + 0.055) / 1.055, 2.4).toDouble() : rn / 12.92;
    gn = gn > 0.04045 ? math.pow((gn + 0.055) / 1.055, 2.4).toDouble() : gn / 12.92;
    bn = bn > 0.04045 ? math.pow((bn + 0.055) / 1.055, 2.4).toDouble() : bn / 12.92;

    rn *= 100; gn *= 100; bn *= 100;

    // Observer = 2°, Illuminant = D65
    final x = rn * 0.4124564 + gn * 0.3575761 + bn * 0.1804375;
    final y = rn * 0.2126729 + gn * 0.7151522 + bn * 0.0721750;
    final z = rn * 0.0193339 + gn * 0.1191920 + bn * 0.9503041;

    // XYZ to LAB
    const refX = 95.047;
    const refY = 100.000;
    const refZ = 108.883;

    double xn = x / refX;
    double yn = y / refY;
    double zn = z / refZ;

    xn = xn > 0.008856 ? math.pow(xn, 1/3).toDouble() : (7.787 * xn) + (16 / 116);
    yn = yn > 0.008856 ? math.pow(yn, 1/3).toDouble() : (7.787 * yn) + (16 / 116);
    zn = zn > 0.008856 ? math.pow(zn, 1/3).toDouble() : (7.787 * zn) + (16 / 116);

    final l = (116 * yn) - 16;
    final a = 500 * (xn - yn);
    final bLab = 200 * (yn - zn);

    return [l, a, bLab];
  }

  // ── CIE76 color distance (Euclidean in LAB space) ──

  double _labDistance(List<double> lab1, List<double> lab2) {
    final dL = lab1[0] - lab2[0];
    final dA = lab1[1] - lab2[1];
    final dB = lab1[2] - lab2[2];
    return math.sqrt(dL * dL + dA * dA + dB * dB);
  }

  // ── Multi-region sampling for multi-color detection ──

  MultiColorResult? analyseMultiColor(CameraImage image) {
    if (!_loggedFormat) {
      _loggedFormat = true;
      debugPrint('ColorService: format=${image.format.group} '
          'planes=${image.planes.length} '
          'size=${image.width}x${image.height}');
    }

    // Sample 9 regions (3x3 grid)
    final regions = <String, Color?>{};
    final positions = [
      ('top-left', 0.15, 0.15),
      ('top', 0.5, 0.15),
      ('top-right', 0.85, 0.15),
      ('left', 0.15, 0.5),
      ('center', 0.5, 0.5),
      ('right', 0.85, 0.5),
      ('bottom-left', 0.15, 0.85),
      ('bottom', 0.5, 0.85),
      ('bottom-right', 0.85, 0.85),
    ];

    for (final (name, xRatio, yRatio) in positions) {
      final color = _sampleRegion(image, xRatio, yRatio);
      if (color != null) {
        regions[name] = color;
      }
    }

    if (regions.isEmpty) return null;

    // Convert sampled colors to ColorResults and group similar colors
    final colorCounts = <String, (ColorResult, int, List<String>)>{};
    
    for (final entry in regions.entries) {
      if (entry.value == null) continue;
      final result = _nearestNamed(entry.value!);
      
      if (colorCounts.containsKey(result.name)) {
        final existing = colorCounts[result.name]!;
        colorCounts[result.name] = (existing.$1, existing.$2 + 1, [...existing.$3, entry.key]);
      } else {
        colorCounts[result.name] = (result, 1, [entry.key]);
      }
    }

    if (colorCounts.isEmpty) return null;

    // Sort by count (most frequent first)
    final sorted = colorCounts.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));

    final totalRegions = regions.length;
    final allDetected = <DetectedColor>[];

    for (final entry in sorted) {
      final (colorResult, count, positions) = entry.value;
      final percentage = (count / totalRegions * 100).roundToDouble();
      final position = positions.length == 1 ? positions.first : 'multiple';
      
      allDetected.add(DetectedColor(
        color: colorResult,
        percentage: percentage,
        position: position,
      ));
    }

    // Dominant = first, secondary = rest (up to 2)
    final dominant = allDetected.first;
    final secondary = allDetected.length > 1 
        ? allDetected.sublist(1, math.min(3, allDetected.length))
        : <DetectedColor>[];

    return MultiColorResult(
      dominant: dominant,
      secondary: secondary,
      all: allDetected,
    );
  }

  // ── Sample a specific region of the image ──

  Color? _sampleRegion(CameraImage image, double xRatio, double yRatio) {
    try {
      final fmt = image.format.group;
      final w = image.width;
      final h = image.height;

      // Define a small sampling area around the target point
      final centerX = (w * xRatio).round();
      final centerY = (h * yRatio).round();
      final radius = (w * 0.08).round(); // 8% of width

      final x0 = (centerX - radius).clamp(0, w - 1);
      final x1 = (centerX + radius).clamp(0, w - 1);
      final y0 = (centerY - radius).clamp(0, h - 1);
      final y1 = (centerY + radius).clamp(0, h - 1);

      if (fmt == ImageFormatGroup.yuv420 || fmt == ImageFormatGroup.nv21) {
        return _sampleYuvRegion(image, x0, x1, y0, y1);
      } else if (fmt == ImageFormatGroup.bgra8888) {
        return _sampleBgraRegion(image, x0, x1, y0, y1);
      } else {
        if (image.planes.length >= 3) {
          return _sampleYuvRegion(image, x0, x1, y0, y1);
        } else {
          return _sampleBgraRegion(image, x0, x1, y0, y1);
        }
      }
    } catch (e) {
      debugPrint('ColorService: region sampling error — $e');
      return null;
    }
  }

  Color? _sampleYuvRegion(CameraImage image, int x0, int x1, int y0, int y1) {
    if (image.planes.length < 3) return null;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yStride = yPlane.bytesPerRow;
    final uStride = uPlane.bytesPerRow;
    final vStride = vPlane.bytesPerRow;

    final uStep = uPlane.bytesPerPixel ?? 1;
    final vStep = vPlane.bytesPerPixel ?? 1;

    const steps = 4;
    final xStep = ((x1 - x0) / steps).round().clamp(1, image.width);
    final yStep = ((y1 - y0) / steps).round().clamp(1, image.height);

    int totalR = 0, totalG = 0, totalB = 0, count = 0;

    for (int y = y0; y < y1; y += yStep) {
      for (int x = x0; x < x1; x += xStep) {
        final yIdx = y * yStride + x;
        if (yIdx >= yBytes.length) continue;

        final uvX = x ~/ 2;
        final uvY = y ~/ 2;
        final uIdx = uvY * uStride + uvX * uStep;
        final vIdx = uvY * vStride + uvX * vStep;

        if (uIdx >= uBytes.length || vIdx >= vBytes.length) continue;

        final yv = yBytes[yIdx] & 0xFF;
        final uv = (uBytes[uIdx] & 0xFF) - 128;
        final vv = (vBytes[vIdx] & 0xFF) - 128;

        final r = (yv + 1.402 * vv).round().clamp(0, 255);
        final g = (yv - 0.344136 * uv - 0.714136 * vv).round().clamp(0, 255);
        final b = (yv + 1.772 * uv).round().clamp(0, 255);

        totalR += r;
        totalG += g;
        totalB += b;
        count++;
      }
    }

    if (count == 0) return null;

    return Color.fromRGBO(totalR ~/ count, totalG ~/ count, totalB ~/ count, 1.0);
  }

  Color? _sampleBgraRegion(CameraImage image, int x0, int x1, int y0, int y1) {
    final plane = image.planes[0];
    final bytes = plane.bytes;
    final stride = plane.bytesPerRow;

    if (bytes.isEmpty) return null;

    const steps = 4;
    final xStep = ((x1 - x0) / steps).round().clamp(1, image.width);
    final yStep = ((y1 - y0) / steps).round().clamp(1, image.height);

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

    return Color.fromRGBO(totalR ~/ count, totalG ~/ count, totalB ~/ count, 1.0);
  }
}
