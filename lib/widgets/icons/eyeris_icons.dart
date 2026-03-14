import 'package:flutter/material.dart';
import 'package:eyeris/core/app_theme.dart';

// ─────────────────────────────────────────────
// EYERIS ICON SYSTEM
// All icons: CustomPainter, stroke-based, #FFD100 default
// Size: 26×26 logical pixels by default
// strokeWidth: 2.0 for outlines, 1.8 for detail
// strokeCap: round, strokeJoin: round
// No text inside icons — all purely geometric
// ─────────────────────────────────────────────

class EyerisIcon extends StatelessWidget {
  final CustomPainter painter;
  final double size;

  const EyerisIcon({super.key, required this.painter, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: painter,
    );
  }
}

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint _fill(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.fill;

// ── READ ICON ─────────────────────────────────
// Document rectangle with 3 text lines
class _ReadPainter extends CustomPainter {
  final Color color;
  _ReadPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 2.0);
    final s = size;

    // Document body
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.15, s.height * 0.08,
                    s.width * 0.70, s.height * 0.84),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, p);

    // Three text lines
    final lp = _stroke(color, 1.8);
    canvas.drawLine(Offset(s.width * 0.30, s.height * 0.38),
                    Offset(s.width * 0.70, s.height * 0.38), lp);
    canvas.drawLine(Offset(s.width * 0.30, s.height * 0.52),
                    Offset(s.width * 0.70, s.height * 0.52), lp);
    canvas.drawLine(Offset(s.width * 0.30, s.height * 0.66),
                    Offset(s.width * 0.55, s.height * 0.66), lp);
  }

  @override
  bool shouldRepaint(_ReadPainter old) => old.color != color;
}

// ── NAVIGATE ICON ─────────────────────────────
// Compass crosshair + center pin circle
class _NavigatePainter extends CustomPainter {
  final Color color;
  _NavigatePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 2.0);
    final s = size;
    final cx = s.width / 2;
    final cy = s.height * 0.44;

    // Outer circle
    canvas.drawCircle(Offset(cx, cy), s.width * 0.30, p);
    // Center dot
    canvas.drawCircle(Offset(cx, cy), s.width * 0.07, _fill(color));

    // Crosshair ticks
    final tp = _stroke(color, 1.8);
    canvas.drawLine(Offset(cx, cy - s.height * 0.38),
                    Offset(cx, cy - s.height * 0.30), tp);
    canvas.drawLine(Offset(cx, cy + s.height * 0.30),
                    Offset(cx, cy + s.height * 0.38), tp);
    canvas.drawLine(Offset(cx - s.width * 0.38, cy),
                    Offset(cx - s.width * 0.30, cy), tp);
    canvas.drawLine(Offset(cx + s.width * 0.30, cy),
                    Offset(cx + s.width * 0.38, cy), tp);

    // Location pin drop tail
    final path = Path()
      ..moveTo(cx - s.width * 0.10, cy + s.height * 0.30)
      ..quadraticBezierTo(cx, cy + s.height * 0.50,
                          cx + s.width * 0.10, cy + s.height * 0.30);
    canvas.drawPath(path, tp);
  }

  @override
  bool shouldRepaint(_NavigatePainter old) => old.color != color;
}

// ── IDENTIFY ICON ─────────────────────────────
// Camera body + lens circle + center dot
class _IdentifyPainter extends CustomPainter {
  final Color color;
  _IdentifyPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 2.0);
    final s = size;

    // Camera body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.08, s.height * 0.24,
                    s.width * 0.84, s.height * 0.54),
      const Radius.circular(3),
    );
    canvas.drawRRect(body, p);

    // Viewfinder bump
    final path = Path()
      ..moveTo(s.width * 0.35, s.height * 0.24)
      ..lineTo(s.width * 0.38, s.height * 0.14)
      ..lineTo(s.width * 0.62, s.height * 0.14)
      ..lineTo(s.width * 0.65, s.height * 0.24);
    canvas.drawPath(path, p);

    // Lens circle
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.51), s.width * 0.18, p);
    // Center dot
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.51), s.width * 0.05, _fill(color));
  }

  @override
  bool shouldRepaint(_IdentifyPainter old) => old.color != color;
}

// ── COMMUNICATE ICON ──────────────────────────
// Speech bubble + two content lines
class _CommunicatePainter extends CustomPainter {
  final Color color;
  _CommunicatePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 2.0);
    final s = size;

    final path = Path()
      ..moveTo(s.width * 0.19, s.height * 0.20)
      ..lineTo(s.width * 0.81, s.height * 0.20)
      ..quadraticBezierTo(s.width * 0.92, s.height * 0.20,
                          s.width * 0.92, s.height * 0.34)
      ..lineTo(s.width * 0.92, s.height * 0.62)
      ..quadraticBezierTo(s.width * 0.92, s.height * 0.76,
                          s.width * 0.78, s.height * 0.76)
      ..lineTo(s.width * 0.36, s.height * 0.76)
      ..lineTo(s.width * 0.15, s.height * 0.88)
      ..lineTo(s.width * 0.19, s.height * 0.76)
      ..quadraticBezierTo(s.width * 0.08, s.height * 0.76,
                          s.width * 0.08, s.height * 0.62)
      ..lineTo(s.width * 0.08, s.height * 0.34)
      ..quadraticBezierTo(s.width * 0.08, s.height * 0.20,
                          s.width * 0.19, s.height * 0.20)
      ..close();
    canvas.drawPath(path, p);

    final lp = _stroke(color, 1.8);
    canvas.drawLine(Offset(s.width * 0.28, s.height * 0.44),
                    Offset(s.width * 0.72, s.height * 0.44), lp);
    canvas.drawLine(Offset(s.width * 0.28, s.height * 0.57),
                    Offset(s.width * 0.57, s.height * 0.57), lp);
  }

  @override
  bool shouldRepaint(_CommunicatePainter old) => old.color != color;
}

// ── MICROPHONE ICON ───────────────────────────
class _MicPainter extends CustomPainter {
  final Color color;
  _MicPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 2.0);
    final s = size;
    final cx = s.width / 2;

    // Mic body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - s.width * 0.20, s.height * 0.10,
                    s.width * 0.40, s.height * 0.50),
      Radius.circular(s.width * 0.20),
    );
    canvas.drawRRect(body, p);

    // Arc stand
    final arcRect = Rect.fromLTWH(s.width * 0.18, s.height * 0.32,
                                  s.width * 0.64, s.height * 0.42);
    canvas.drawArc(arcRect, 0, 3.14159, false, p);

    // Stem
    canvas.drawLine(Offset(cx, s.height * 0.74),
                    Offset(cx, s.height * 0.90), p);
    // Base bar
    canvas.drawLine(Offset(cx - s.width * 0.22, s.height * 0.90),
                    Offset(cx + s.width * 0.22, s.height * 0.90), p);
  }

  @override
  bool shouldRepaint(_MicPainter old) => old.color != color;
}

// ── BACK ARROW ICON ───────────────────────────
class _BackArrowPainter extends CustomPainter {
  final Color color;
  _BackArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 2.5);
    final s = size;

    // Arrow shaft
    canvas.drawLine(Offset(s.width * 0.75, s.height / 2),
                    Offset(s.width * 0.25, s.height / 2), p);
    // Arrow head
    canvas.drawLine(Offset(s.width * 0.25, s.height / 2),
                    Offset(s.width * 0.46, s.height * 0.30), p);
    canvas.drawLine(Offset(s.width * 0.25, s.height / 2),
                    Offset(s.width * 0.46, s.height * 0.70), p);
  }

  @override
  bool shouldRepaint(_BackArrowPainter old) => old.color != color;
}

// ── PERSON ICON (profile avatar) ─────────────
class _PersonPainter extends CustomPainter {
  final Color color;
  _PersonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;
    final cx = s.width / 2;

    // Head
    canvas.drawCircle(Offset(cx, s.height * 0.33), s.width * 0.20, p);

    // Shoulder arc
    final arcRect = Rect.fromLTWH(s.width * 0.12, s.height * 0.52,
                                  s.width * 0.76, s.height * 0.52);
    canvas.drawArc(arcRect, 3.14159, 3.14159, false, p);
  }

  @override
  bool shouldRepaint(_PersonPainter old) => old.color != color;
}

// ── CAMERA (small — for action rows) ─────────
class _CameraSmallPainter extends CustomPainter {
  final Color color;
  _CameraSmallPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.08, s.height * 0.22,
                    s.width * 0.84, s.height * 0.56),
      const Radius.circular(2),
    );
    canvas.drawRRect(body, p);
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.50), s.width * 0.18, p);
  }

  @override
  bool shouldRepaint(_CameraSmallPainter old) => old.color != color;
}

// ── DOCUMENT ICON ─────────────────────────────
// Rectangle + 3 lines of varying width
class _DocumentPainter extends CustomPainter {
  final Color color;
  _DocumentPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.20, s.height * 0.08,
                    s.width * 0.60, s.height * 0.84),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, p);

    canvas.drawLine(Offset(s.width * 0.33, s.height * 0.34),
                    Offset(s.width * 0.67, s.height * 0.34), p);
    canvas.drawLine(Offset(s.width * 0.33, s.height * 0.50),
                    Offset(s.width * 0.67, s.height * 0.50), p);
    canvas.drawLine(Offset(s.width * 0.33, s.height * 0.66),
                    Offset(s.width * 0.55, s.height * 0.66), p);
  }

  @override
  bool shouldRepaint(_DocumentPainter old) => old.color != color;
}

// ── CLOCK ICON ────────────────────────────────
// Circle + hour hand + minute hand
class _ClockPainter extends CustomPainter {
  final Color color;
  _ClockPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r  = s.width * 0.40;

    canvas.drawCircle(Offset(cx, cy), r, p);

    // Hour hand (pointing ~10 o'clock)
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx - r * 0.45, cy - r * 0.55),
      p,
    );
    // Minute hand (pointing ~12 o'clock)
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, cy - r * 0.72),
      p,
    );
    // Center dot
    canvas.drawCircle(Offset(cx, cy), s.width * 0.04, _fill(color));
  }

  @override
  bool shouldRepaint(_ClockPainter old) => old.color != color;
}

// ── VOICE / SPEECH ICON ───────────────────────
// Speech bubble with sound-wave lines to the right
class _VoicePainter extends CustomPainter {
  final Color color;
  _VoicePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;

    // Bubble body
    final path = Path()
      ..moveTo(s.width * 0.12, s.height * 0.18)
      ..lineTo(s.width * 0.62, s.height * 0.18)
      ..quadraticBezierTo(s.width * 0.72, s.height * 0.18,
                          s.width * 0.72, s.height * 0.30)
      ..lineTo(s.width * 0.72, s.height * 0.54)
      ..quadraticBezierTo(s.width * 0.72, s.height * 0.66,
                          s.width * 0.60, s.height * 0.66)
      ..lineTo(s.width * 0.28, s.height * 0.66)
      ..lineTo(s.width * 0.12, s.height * 0.80)
      ..lineTo(s.width * 0.14, s.height * 0.66)
      ..quadraticBezierTo(s.width * 0.04, s.height * 0.66,
                          s.width * 0.04, s.height * 0.54)
      ..lineTo(s.width * 0.04, s.height * 0.30)
      ..quadraticBezierTo(s.width * 0.04, s.height * 0.18,
                          s.width * 0.12, s.height * 0.18)
      ..close();
    canvas.drawPath(path, p);

    // Sound waves (right side)
    final wp = _stroke(color, 1.6);
    canvas.drawArc(
      Rect.fromLTWH(s.width * 0.74, s.height * 0.28,
                    s.width * 0.10, s.height * 0.28),
      -1.05, 2.10, false, wp,
    );
    canvas.drawArc(
      Rect.fromLTWH(s.width * 0.82, s.height * 0.20,
                    s.width * 0.12, s.height * 0.44),
      -1.05, 2.10, false, wp,
    );
  }

  @override
  bool shouldRepaint(_VoicePainter old) => old.color != color;
}

// ── WALK ICON ─────────────────────────────────
// Stick figure in walking pose
class _WalkPainter extends CustomPainter {
  final Color color;
  _WalkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;
    final cx = s.width * 0.52;

    // Head
    canvas.drawCircle(Offset(cx, s.height * 0.16), s.width * 0.10, p);
    // Torso
    canvas.drawLine(Offset(cx, s.height * 0.26),
                    Offset(cx, s.height * 0.56), p);
    // Left arm
    canvas.drawLine(Offset(cx, s.height * 0.36),
                    Offset(cx - s.width * 0.18, s.height * 0.48), p);
    // Right arm
    canvas.drawLine(Offset(cx, s.height * 0.36),
                    Offset(cx + s.width * 0.14, s.height * 0.44), p);
    // Left leg
    canvas.drawLine(Offset(cx, s.height * 0.56),
                    Offset(cx - s.width * 0.14, s.height * 0.78), p);
    canvas.drawLine(Offset(cx - s.width * 0.14, s.height * 0.78),
                    Offset(cx - s.width * 0.22, s.height * 0.90), p);
    // Right leg
    canvas.drawLine(Offset(cx, s.height * 0.56),
                    Offset(cx + s.width * 0.16, s.height * 0.74), p);
    canvas.drawLine(Offset(cx + s.width * 0.16, s.height * 0.74),
                    Offset(cx + s.width * 0.08, s.height * 0.90), p);
  }

  @override
  bool shouldRepaint(_WalkPainter old) => old.color != color;
}

// ── INDOOR MAP ICON ───────────────────────────
// 3×3 dashed grid + filled center dot
class _IndoorMapPainter extends CustomPainter {
  final Color color;
  _IndoorMapPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size;
    final dashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Outer rectangle
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.10, s.height * 0.10,
                    s.width * 0.80, s.height * 0.80),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, dashPaint);

    // Inner grid lines (dashed)
    _drawDashedLine(canvas, dashPaint,
        Offset(s.width * 0.43, s.height * 0.10),
        Offset(s.width * 0.43, s.height * 0.90));
    _drawDashedLine(canvas, dashPaint,
        Offset(s.width * 0.10, s.height * 0.43),
        Offset(s.width * 0.90, s.height * 0.43));

    // Center dot
    canvas.drawCircle(
      Offset(s.width * 0.66, s.height * 0.66),
      s.width * 0.08,
      _fill(color),
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Paint paint,
    Offset start,
    Offset end,
  ) {
    const dashLen = 4.0;
    const gapLen  = 3.0;
    final dx     = end.dx - start.dx;
    final dy     = end.dy - start.dy;
    final length = Offset(dx, dy).distance;
    if (length == 0) return;
    final unitX = dx / length;
    final unitY = dy / length;
    var drawn   = 0.0;
    var drawing = true;
    while (drawn < length) {
      final step = drawing ? dashLen : gapLen;
      final segLen = (drawn + step < length) ? step : length - drawn;
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitX * drawn,       start.dy + unitY * drawn),
          Offset(start.dx + unitX * (drawn + segLen), start.dy + unitY * (drawn + segLen)),
          paint,
        );
      }
      drawn   += segLen;
      drawing  = !drawing;
    }
  }

  @override
  bool shouldRepaint(_IndoorMapPainter old) => old.color != color;
}

// ── BUS ICON ──────────────────────────────────
// Rectangular bus body + windows + 2 wheels
class _BusPainter extends CustomPainter {
  final Color color;
  _BusPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;

    // Body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.10, s.height * 0.18,
                    s.width * 0.80, s.height * 0.52),
      const Radius.circular(3),
    );
    canvas.drawRRect(body, p);

    // Windshield divider
    canvas.drawLine(
      Offset(s.width * 0.10, s.height * 0.36),
      Offset(s.width * 0.90, s.height * 0.36),
      p,
    );

    // Window 1
    canvas.drawRect(
      Rect.fromLTWH(s.width * 0.18, s.height * 0.22,
                    s.width * 0.18, s.height * 0.10),
      p,
    );
    // Window 2
    canvas.drawRect(
      Rect.fromLTWH(s.width * 0.42, s.height * 0.22,
                    s.width * 0.18, s.height * 0.10),
      p,
    );
    // Window 3
    canvas.drawRect(
      Rect.fromLTWH(s.width * 0.66, s.height * 0.22,
                    s.width * 0.16, s.height * 0.10),
      p,
    );

    // Wheel left
    canvas.drawCircle(
      Offset(s.width * 0.28, s.height * 0.74),
      s.width * 0.09,
      p,
    );
    // Wheel right
    canvas.drawCircle(
      Offset(s.width * 0.72, s.height * 0.74),
      s.width * 0.09,
      p,
    );
  }

  @override
  bool shouldRepaint(_BusPainter old) => old.color != color;
}

// ── COLOR DETECT ICON ─────────────────────────
// 3 overlapping circles in triangular arrangement
class _ColorDetectPainter extends CustomPainter {
  final Color color;
  _ColorDetectPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;
    final r = s.width * 0.22;

    // Top circle
    canvas.drawCircle(Offset(s.width * 0.50, s.height * 0.30), r, p);
    // Bottom-left
    canvas.drawCircle(Offset(s.width * 0.32, s.height * 0.62), r, p);
    // Bottom-right
    canvas.drawCircle(Offset(s.width * 0.68, s.height * 0.62), r, p);
  }

  @override
  bool shouldRepaint(_ColorDetectPainter old) => old.color != color;
}

// ── PHONE ICON ────────────────────────────────
// Classic curved handset
class _PhonePainter extends CustomPainter {
  final Color color;
  _PhonePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;

    final path = Path()
      ..moveTo(s.width * 0.18, s.height * 0.14)
      ..lineTo(s.width * 0.38, s.height * 0.14)
      ..lineTo(s.width * 0.46, s.height * 0.34)
      ..lineTo(s.width * 0.36, s.height * 0.42)
      ..quadraticBezierTo(s.width * 0.44, s.height * 0.60,
                          s.width * 0.58, s.height * 0.64)
      ..lineTo(s.width * 0.66, s.height * 0.54)
      ..lineTo(s.width * 0.86, s.height * 0.62)
      ..lineTo(s.width * 0.86, s.height * 0.82)
      ..quadraticBezierTo(s.width * 0.56, s.height * 0.96,
                          s.width * 0.18, s.height * 0.46)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_PhonePainter old) => old.color != color;
}

// ── MESSAGE ICON ──────────────────────────────
// Rounded speech bubble with corner tail
class _MessagePainter extends CustomPainter {
  final Color color;
  _MessagePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;

    final path = Path()
      ..moveTo(s.width * 0.16, s.height * 0.16)
      ..lineTo(s.width * 0.84, s.height * 0.16)
      ..quadraticBezierTo(s.width * 0.94, s.height * 0.16,
                          s.width * 0.94, s.height * 0.30)
      ..lineTo(s.width * 0.94, s.height * 0.60)
      ..quadraticBezierTo(s.width * 0.94, s.height * 0.74,
                          s.width * 0.80, s.height * 0.74)
      ..lineTo(s.width * 0.36, s.height * 0.74)
      ..lineTo(s.width * 0.16, s.height * 0.88)
      ..lineTo(s.width * 0.18, s.height * 0.74)
      ..quadraticBezierTo(s.width * 0.06, s.height * 0.74,
                          s.width * 0.06, s.height * 0.60)
      ..lineTo(s.width * 0.06, s.height * 0.30)
      ..quadraticBezierTo(s.width * 0.06, s.height * 0.16,
                          s.width * 0.16, s.height * 0.16)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_MessagePainter old) => old.color != color;
}

// ── WARNING / SOS ICON ────────────────────────
// Equilateral triangle + vertical bar + dot
class _WarningPainter extends CustomPainter {
  final Color color;
  _WarningPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(color, 1.8);
    final s = size;

    final path = Path()
      ..moveTo(s.width * 0.50, s.height * 0.08)
      ..lineTo(s.width * 0.92, s.height * 0.86)
      ..lineTo(s.width * 0.08, s.height * 0.86)
      ..close();
    canvas.drawPath(path, p);

    // Exclamation bar
    canvas.drawLine(
      Offset(s.width * 0.50, s.height * 0.36),
      Offset(s.width * 0.50, s.height * 0.62),
      p,
    );
    // Exclamation dot
    canvas.drawCircle(
      Offset(s.width * 0.50, s.height * 0.72),
      s.width * 0.04,
      _fill(color),
    );
  }

  @override
  bool shouldRepaint(_WarningPainter old) => old.color != color;
}

// ── PUBLIC FACTORY WIDGETS ────────────────────
// Usage: EyerisIcons.read(size: 26, color: EyerisColors.primary)

class EyerisIcons {
  EyerisIcons._();

  // Hub card icons
  static Widget read({double size = 26, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _ReadPainter(color), size: size);

  static Widget navigate({double size = 26, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _NavigatePainter(color), size: size);

  static Widget identify({double size = 26, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _IdentifyPainter(color), size: size);

  static Widget communicate({double size = 26, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _CommunicatePainter(color), size: size);

  // UI chrome icons
  static Widget mic({double size = 28, Color color = EyerisColors.black}) =>
      EyerisIcon(painter: _MicPainter(color), size: size);

  static Widget backArrow({double size = 20, Color color = EyerisColors.black}) =>
      EyerisIcon(painter: _BackArrowPainter(color), size: size);

  static Widget person({double size = 18, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _PersonPainter(color), size: size);

  // Read screen
  static Widget camera({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _CameraSmallPainter(color), size: size);

  static Widget document({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _DocumentPainter(color), size: size);

  static Widget clock({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _ClockPainter(color), size: size);

  static Widget voice({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _VoicePainter(color), size: size);

  // Navigate screen
  static Widget walk({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _WalkPainter(color), size: size);

  static Widget indoorMap({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _IndoorMapPainter(color), size: size);

  static Widget bus({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _BusPainter(color), size: size);

  // Identify screen
  static Widget colorDetect({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _ColorDetectPainter(color), size: size);

  // Communicate screen
  static Widget phone({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _PhonePainter(color), size: size);

  static Widget message({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _MessagePainter(color), size: size);

  static Widget warning({double size = 22, Color color = EyerisColors.primary}) =>
      EyerisIcon(painter: _WarningPainter(color), size: size);
}
