import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Semburan partikel halus yang diputar sekali setiap kali [trigger] berubah.
/// Tidak menangkap sentuhan; ditumpuk di atas kartu kebiasaan.
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.trigger,
    required this.origin,
    required this.color,
  });

  final int trigger;

  /// Titik asal semburan dalam koordinat relatif (Alignment).
  final Alignment origin;
  final Color color;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  var _seed = 0;

  @override
  void didUpdateWidget(ParticleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _seed = widget.trigger;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _controller.isAnimating
            ? CustomPaint(
                size: Size.infinite,
                painter: _BurstPainter(
                  t: _controller.value,
                  seed: _seed,
                  origin: widget.origin,
                  color: widget.color,
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.t,
    required this.seed,
    required this.origin,
    required this.color,
  });

  final double t;
  final int seed;
  final Alignment origin;
  final Color color;

  static const _count = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final center = origin.alongSize(size);
    final eased = Curves.easeOutCubic.transform(t);
    final paint = Paint();

    for (var i = 0; i < _count; i++) {
      final angle = 2 * math.pi * i / _count + random.nextDouble() * 0.5;
      final distance = 28 + random.nextDouble() * 44;
      final radius = 1.5 + random.nextDouble() * 2.5;
      final position =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (16 + distance * eased);
      paint.color = color.withValues(alpha: (1 - t) * 0.9);
      canvas.drawCircle(position, radius * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.seed != seed;
}
