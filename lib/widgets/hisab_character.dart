import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small animated person doing hisab at a desk: head bobs, eyes
/// blink, the hand taps the calculator, coins float up.
/// Pure CustomPaint - no images, no packages, works on web + mobile.
class HisabCharacter extends StatefulWidget {
  /// 1.0 = 120x110. Use a smaller value on narrow phones.
  final double scale;
  const HisabCharacter({super.key, this.scale = 1});

  @override
  State<HisabCharacter> createState() => _HisabCharacterState();
}

class _HisabCharacterState extends State<HisabCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120 * widget.scale,
      height: 110 * widget.scale,
      child: FittedBox(
        child: SizedBox(
          width: 120,
          height: 110,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) =>
                CustomPaint(painter: _HisabPainter(_c.value)),
          ),
        ),
      ),
    );
  }
}

class _HisabPainter extends CustomPainter {
  final double t; // 0..1 looping
  _HisabPainter(this.t);

  static const _skin = Color(0xFFFFD2A8);
  static const _hair = Color(0xFF2B2B3A);
  static const _shirt = Color(0xFFF5B942);
  static const _navy = Color(0xFF142943);
  static const _screen = Color(0xFFB8F2E6);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    final bob = math.sin(t * 2 * math.pi) * 1.8;

    // ----- floating coins (behind everything) -----
    const coinX = [98.0, 110.0, 16.0];
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final y = 62 - p * 52;
      final x = coinX[i] + math.sin(p * 2 * math.pi) * 3;
      final op = (1 - p).clamp(0.0, 1.0);
      fill.color = const Color(0xFFFFD54F).withOpacity(op);
      canvas.drawCircle(Offset(x, y), 5.5, fill);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFC9A227).withOpacity(op);
      canvas.drawCircle(Offset(x, y), 3.4, ring);
    }

    // ----- body -----
    fill.color = _shirt;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(40, 54, 38, 36), const Radius.circular(14)),
      fill,
    );

    // ----- head -----
    final head = Offset(59, 38 + bob);
    fill.color = _skin;
    canvas.drawCircle(head, 14, fill);

    // hair (top cap)
    fill.color = _hair;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(head.dx, head.dy - 3), radius: 15),
      math.pi * 1.02,
      math.pi * 0.96,
      true,
      fill,
    );

    // eyes (blink around t ~ 0.92)
    final blink = t > 0.91 && t < 0.96;
    final eye = Paint()
      ..color = _hair
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = blink ? PaintingStyle.stroke : PaintingStyle.fill;
    for (final dx in [-5.0, 5.0]) {
      final c = Offset(head.dx + dx, head.dy + 1);
      if (blink) {
        canvas.drawLine(c.translate(-1.8, 0), c.translate(1.8, 0), eye);
      } else {
        canvas.drawCircle(c, 1.7, eye);
      }
    }
    // smile
    final smile = Paint()
      ..color = _hair
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(head.dx - 4.5, head.dy + 3, 9, 6), 0.2,
        math.pi - 0.4, false, smile);

    // ----- ledger (left of desk) -----
    fill.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(12, 75, 28, 11), const Radius.circular(3)),
      fill,
    );
    final line = Paint()
      ..color = const Color(0xFF98A2B3)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(16, 79), const Offset(36, 79), line);
    canvas.drawLine(const Offset(16, 82.5), const Offset(31, 82.5), line);

    // left arm resting on ledger
    final arm = Paint()
      ..color = _shirt
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(46, 62), const Offset(30, 79), arm);
    fill.color = _skin;
    canvas.drawCircle(const Offset(29, 79), 3.4, fill);

    // ----- calculator -----
    fill.color = _navy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(78, 64, 28, 23), const Radius.circular(4)),
      fill,
    );
    fill.color = _screen;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(81, 67, 22, 6), const Radius.circular(2)),
      fill,
    );
    // little "number bar" on the screen that grows while tapping
    fill.color = _navy.withOpacity(0.55);
    final barW = 4 + ((t * 6) % 1) * 12;
    canvas.drawRect(Rect.fromLTWH(101 - barW, 68.6, barW, 2.8), fill);

    final active = (t * 6).floor() % 6;
    for (var r = 0; r < 2; r++) {
      for (var cIdx = 0; cIdx < 3; cIdx++) {
        final idx = r * 3 + cIdx;
        fill.color = idx == active ? const Color(0xFFFFD54F) : Colors.white24;
        canvas.drawCircle(Offset(86 + cIdx * 8.0, 78 + r * 5.0), 1.9, fill);
      }
    }

    // ----- right arm tapping the calculator -----
    final col = active % 3;
    final row = active ~/ 3;
    final tap = (math.sin(t * 12 * math.pi) + 1) / 2; // 0..1
    final hand = Offset(86 + col * 8.0, 74 + row * 5.0 - tap * 3);
    canvas.drawLine(const Offset(72, 62), hand, arm);
    fill.color = _skin;
    canvas.drawCircle(hand, 3.4, fill);

    // ----- desk (drawn last so it covers the lower body) -----
    fill.color = Colors.white.withOpacity(0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 87, 112, 8), const Radius.circular(4)),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _HisabPainter old) => old.t != t;
}
