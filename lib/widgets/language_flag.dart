import 'package:flutter/material.dart';

/// The flag of a language of the app: Romania's, or the United Kingdom's
/// for English. Drawn here, so that it looks the same everywhere: Windows
/// has no flag emojis.
class LanguageFlag extends StatelessWidget {
  const LanguageFlag(this.locale, {super.key});

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 27,
      height: 18,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        // A thin edge, so that the white parts show on a light background.
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: CustomPaint(
        painter: locale.languageCode == 'ro'
            ? const _RomanianFlag()
            : const _BritishFlag(),
      ),
    );
  }
}

class _RomanianFlag extends CustomPainter {
  const _RomanianFlag();

  @override
  void paint(Canvas canvas, Size size) {
    const stripes = [Color(0xFF002B7F), Color(0xFFFCD116), Color(0xFFCE1126)];
    final width = size.width / stripes.length;
    for (final (index, color) in stripes.indexed) {
      canvas.drawRect(
        Rect.fromLTWH(width * index, 0, width, size.height),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RomanianFlag oldDelegate) => false;
}

/// The Union Jack, simplified for its size: the red diagonals run through
/// the middle of the white ones.
class _BritishFlag extends CustomPainter {
  const _BritishFlag();

  @override
  void paint(Canvas canvas, Size size) {
    const blue = Color(0xFF012169);
    const red = Color(0xFFC8102E);
    final white = Paint()..color = Colors.white;
    final center = size.center(Offset.zero);
    final height = size.height;

    canvas.drawRect(Offset.zero & size, Paint()..color = blue);
    for (final (color, stroke) in [
      (Colors.white, height / 5),
      (red, height / 15),
    ]) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = stroke;
      canvas
        ..drawLine(Offset.zero, Offset(size.width, height), paint)
        ..drawLine(Offset(0, height), Offset(size.width, 0), paint);
    }
    // The upright cross: white, with a red one inside it.
    for (final (paint, band) in [
      (white, height / 3),
      (Paint()..color = red, height / 5),
    ]) {
      canvas
        ..drawRect(
          Rect.fromCenter(center: center, width: size.width, height: band),
          paint,
        )
        ..drawRect(
          Rect.fromCenter(center: center, width: band, height: height),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_BritishFlag oldDelegate) => false;
}
