// lib/widgets/icons/eyeris_icons.dart
// Stroke-based icons for Eyeris. Default 26×26, color #FFD100, strokeWidth 2.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

const double _defaultSize = 26;
const double _defaultStroke = 2;

/// Props for all Eyeris icons: size, color, strokeWidth.
class EyerisIconProps {
  const EyerisIconProps({
    this.size = _defaultSize,
    this.color = EyerisTheme.primary,
    this.strokeWidth = _defaultStroke,
  });

  final double size;
  final Color color;
  final double strokeWidth;
}

/// Base painter for stroke icons. Subclasses implement [paintIcon].
abstract class _StrokeIconPainter extends CustomPainter {
  _StrokeIconPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  void paintIcon(Canvas canvas, Size size);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    paintIcon(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Generic stroke icon widget.
class _EyerisIcon extends StatelessWidget {
  const _EyerisIcon({
    required this.size,
    required this.color,
    required this.strokeWidth,
    required this.painterBuilder,
  });

  final double size;
  final Color color;
  final double strokeWidth;
  final CustomPainter Function(Color color, double strokeWidth) painterBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: painterBuilder(color, strokeWidth),
      ),
    );
  }
}

// --- Navigation & UI ---

class _BackArrowPainter extends _StrokeIconPainter {
  _BackArrowPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width * 0.7, size.height * 0.2)
      ..lineTo(size.width * 0.3, size.height * 0.5)
      ..lineTo(size.width * 0.7, size.height * 0.8);
    canvas.drawPath(p, Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round);
  }
}

class BackArrowIcon extends StatelessWidget {
  const BackArrowIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _BackArrowPainter(color: c, strokeWidth: w));
}

class _MicPainter extends _StrokeIconPainter {
  _MicPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    final r = Rect.fromLTWH(size.width * 0.25, size.height * 0.15, size.width * 0.5, size.height * 0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.65), Offset(size.width * 0.5, size.height * 0.85), p);
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.85), Offset(size.width * 0.65, size.height * 0.85), p);
  }
}

class MicIcon extends StatelessWidget {
  const MicIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _MicPainter(color: c, strokeWidth: w));
}

class _ChevronRightPainter extends _StrokeIconPainter {
  _ChevronRightPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width * 0.35, size.height * 0.2)
      ..lineTo(size.width * 0.75, size.height * 0.5)
      ..lineTo(size.width * 0.35, size.height * 0.8);
    canvas.drawPath(p, Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round);
  }
}

class ChevronRightIcon extends StatelessWidget {
  const ChevronRightIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _ChevronRightPainter(color: c, strokeWidth: w));
}

// --- Hub cards: Read, Navigate, Identify, Communicate ---

class _ReadIconPainter extends _StrokeIconPainter {
  _ReadIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    final r = Rect.fromLTWH(size.width * 0.2, size.height * 0.15, size.width * 0.6, size.height * 0.7);
    canvas.drawRect(r, p);
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.35), Offset(size.width * 0.7, size.height * 0.35), p);
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.5), Offset(size.width * 0.65, size.height * 0.5), p);
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.65), Offset(size.width * 0.55, size.height * 0.65), p);
  }
}

class ReadIcon extends StatelessWidget {
  const ReadIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _ReadIconPainter(color: c, strokeWidth: w));
}

class _NavigateIconPainter extends _StrokeIconPainter {
  _NavigateIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.35, p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.2), Offset(size.width * 0.5, size.height * 0.5), p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.5), Offset(size.width * 0.5, size.height * 0.8), p);
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.5), Offset(size.width * 0.5, size.height * 0.5), p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.5), Offset(size.width * 0.8, size.height * 0.5), p);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.08, p);
  }
}

class NavigateIcon extends StatelessWidget {
  const NavigateIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _NavigateIconPainter(color: c, strokeWidth: w));
}

class _IdentifyIconPainter extends _StrokeIconPainter {
  _IdentifyIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    final r = Rect.fromLTWH(size.width * 0.15, size.height * 0.2, size.width * 0.7, size.height * 0.55);
    canvas.drawRect(r, p);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.48), size.width * 0.2, p);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.48), size.width * 0.05, p);
  }
}

class IdentifyIcon extends StatelessWidget {
  const IdentifyIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _IdentifyIconPainter(color: c, strokeWidth: w));
}

class _CommunicateIconPainter extends _StrokeIconPainter {
  _CommunicateIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    final r = Rect.fromLTWH(size.width * 0.2, size.height * 0.2, size.width * 0.6, size.height * 0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), p);
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.38), Offset(size.width * 0.65, size.height * 0.38), p);
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.52), Offset(size.width * 0.55, size.height * 0.52), p);
  }
}

class CommunicateIcon extends StatelessWidget {
  const CommunicateIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _CommunicateIconPainter(color: c, strokeWidth: w));
}

// --- Read screen: Camera, Document, Clock, Voice ---

class _CameraIconPainter extends _StrokeIconPainter {
  _CameraIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    final r = Rect.fromLTWH(size.width * 0.15, size.height * 0.25, size.width * 0.7, size.height * 0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), p);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.18, p);
  }
}

class CameraIcon extends StatelessWidget {
  const CameraIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _CameraIconPainter(color: c, strokeWidth: w));
}

class DocumentIcon extends StatelessWidget {
  const DocumentIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ReadIcon(size: size, color: color, strokeWidth: strokeWidth);
}

class _ClockIconPainter extends _StrokeIconPainter {
  _ClockIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.4, p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.5), Offset(size.width * 0.5, size.height * 0.28), p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.5), Offset(size.width * 0.68, size.height * 0.5), p);
  }
}

class ClockIcon extends StatelessWidget {
  const ClockIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _ClockIconPainter(color: c, strokeWidth: w));
}

class VoiceIcon extends StatelessWidget {
  const VoiceIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => CommunicateIcon(size: size, color: color, strokeWidth: strokeWidth);
}

// --- Navigate: Walk, IndoorMap, Bus ---

class _WalkIconPainter extends _StrokeIconPainter {
  _WalkIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.22), size.width * 0.12, p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.34), Offset(size.width * 0.5, size.height * 0.55), p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.55), Offset(size.width * 0.35, size.height * 0.78), p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.55), Offset(size.width * 0.65, size.height * 0.78), p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.45), Offset(size.width * 0.3, size.height * 0.5), p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.45), Offset(size.width * 0.7, size.height * 0.48), p);
  }
}

class WalkIcon extends StatelessWidget {
  const WalkIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _WalkIconPainter(color: c, strokeWidth: w));
}

class _IndoorMapIconPainter extends _StrokeIconPainter {
  _IndoorMapIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    final w = size.width / 3;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(Offset(0, i * w), Offset(size.width, i * w), p);
      canvas.drawLine(Offset(i * w, 0), Offset(i * w, size.height), p);
    }
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.08, p);
  }
}

class IndoorMapIcon extends StatelessWidget {
  const IndoorMapIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _IndoorMapIconPainter(color: c, strokeWidth: w));
}

class _BusIconPainter extends _StrokeIconPainter {
  _BusIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    final r = Rect.fromLTWH(size.width * 0.1, size.height * 0.25, size.width * 0.8, size.height * 0.45);
    canvas.drawRect(r, p);
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.78), size.width * 0.1, p);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.78), size.width * 0.1, p);
  }
}

class BusIcon extends StatelessWidget {
  const BusIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _BusIconPainter(color: c, strokeWidth: w));
}

// --- Identify: Scene, Person, Color ---

class SceneIcon extends StatelessWidget {
  const SceneIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => IdentifyIcon(size: size, color: color, strokeWidth: strokeWidth);
}

class _PersonIconPainter extends _StrokeIconPainter {
  _PersonIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.28), size.width * 0.18, p);
    canvas.drawArc(Rect.fromLTWH(size.width * 0.2, size.height * 0.35, size.width * 0.6, size.height * 0.4), 0, 3.14159, false, p);
  }
}

class PersonIcon extends StatelessWidget {
  const PersonIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _PersonIconPainter(color: c, strokeWidth: w));
}

class _ColorIconPainter extends _StrokeIconPainter {
  _ColorIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    final r = size.width * 0.35;
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.4), r, p);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.4), r, p);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), r, p);
  }
}

class ColorIcon extends StatelessWidget {
  const ColorIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _ColorIconPainter(color: c, strokeWidth: w));
}

// --- Communicate: Phone, Message, Warning ---

class _PhoneIconPainter extends _StrokeIconPainter {
  _PhoneIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.55, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.2, size.width * 0.9, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.8, size.width * 0.55, size.height * 0.8)
      ..moveTo(size.width * 0.45, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.2, size.width * 0.1, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.8, size.width * 0.45, size.height * 0.8);
    canvas.drawPath(path, p);
  }
}

class PhoneIcon extends StatelessWidget {
  const PhoneIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _PhoneIconPainter(color: c, strokeWidth: w));
}

class MessageIcon extends StatelessWidget {
  const MessageIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => CommunicateIcon(size: size, color: color, strokeWidth: strokeWidth);
}

class _WarningIconPainter extends _StrokeIconPainter {
  _WarningIconPainter({required super.color, required super.strokeWidth});

  @override
  void paintIcon(Canvas canvas, Size size) {
    final p = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.12)
      ..lineTo(size.width * 0.9, size.height * 0.85)
      ..lineTo(size.width * 0.1, size.height * 0.85)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.5), Offset(size.width * 0.5, size.height * 0.6), p);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.72), size.width * 0.04, p);
  }
}

class WarningIcon extends StatelessWidget {
  const WarningIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _WarningIconPainter(color: c, strokeWidth: w));
}

// --- Onboarding: Vision, Touch, Switch, Mixed (stubs reusing existing) ---

class VisionIcon extends StatelessWidget {
  const VisionIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _NavigateIconPainter(color: c, strokeWidth: w));
}

class TouchIcon extends StatelessWidget {
  const TouchIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => PersonIcon(size: size, color: color, strokeWidth: strokeWidth);
}

class SwitchIcon extends StatelessWidget {
  const SwitchIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => _EyerisIcon(size: size, color: color, strokeWidth: strokeWidth, painterBuilder: (c, w) => _IndoorMapIconPainter(color: c, strokeWidth: w));
}

class MixedIcon extends StatelessWidget {
  const MixedIcon({super.key, this.size = _defaultSize, this.color = EyerisTheme.primary, this.strokeWidth = _defaultStroke});
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ColorIcon(size: size, color: color, strokeWidth: strokeWidth);
}

// --- Dynamic icon lookup ---

Widget getIcon(String name, [EyerisIconProps props = const EyerisIconProps()]) {
  switch (name) {
    case 'backArrow':
      return BackArrowIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'mic':
      return MicIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'chevronRight':
      return ChevronRightIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'read':
      return ReadIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'navigate':
      return NavigateIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'identify':
      return IdentifyIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'communicate':
      return CommunicateIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'camera':
      return CameraIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'document':
      return DocumentIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'clock':
      return ClockIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'voice':
      return VoiceIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'walk':
      return WalkIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'indoorMap':
      return IndoorMapIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'bus':
      return BusIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'scene':
      return SceneIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'person':
      return PersonIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'color':
      return ColorIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'phone':
      return PhoneIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'message':
      return MessageIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'warning':
      return WarningIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'vision':
      return VisionIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'touch':
      return TouchIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'switch':
      return SwitchIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    case 'mixed':
      return MixedIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
    default:
      return ReadIcon(size: props.size, color: props.color, strokeWidth: props.strokeWidth);
  }
}
