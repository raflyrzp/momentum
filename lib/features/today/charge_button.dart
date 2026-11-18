import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Durasi menahan tombol sebelum kebiasaan dinyatakan selesai.
const chargeDuration = Duration(milliseconds: 800);

/// Tombol "long-press to charge": cincin terisi selama ditahan; melepas
/// sebelum penuh membatalkan. [onCharged] dipanggil tepat saat cincin penuh.
class ChargeButton extends StatefulWidget {
  const ChargeButton({
    super.key,
    required this.done,
    required this.onCharged,
    this.onShortTap,
    this.color = AppColors.primary,
    this.size = 52,
  });

  final bool done;
  final VoidCallback onCharged;

  /// Dipanggil bila tombol dilepas sebelum penuh (untuk menampilkan petunjuk).
  final VoidCallback? onShortTap;
  final Color color;
  final double size;

  @override
  State<ChargeButton> createState() => _ChargeButtonState();
}

class _ChargeButtonState extends State<ChargeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: chargeDuration,
        reverseDuration: const Duration(milliseconds: 200),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _fired = true;
          widget.onCharged();
          _controller.value = 0;
        }
      });

  bool _fired = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    if (widget.done) return;
    _fired = false;
    _controller.forward(from: 0);
  }

  void _release({required bool tapped}) {
    if (widget.done || _fired) return;
    if (_controller.isAnimating) {
      _controller.reverse();
      if (tapped) widget.onShortTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.done ? 'Selesai' : 'Tahan untuk menyelesaikan',
      onLongPress: widget.done ? null : widget.onCharged,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _start(),
        onTapUp: (_) => _release(tapped: true),
        onTapCancel: () => _release(tapped: false),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Transform.scale(
              scale: 1 - 0.08 * Curves.easeOut.transform(t),
              child: SizedBox.square(
                dimension: widget.size,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: t,
                    color: widget.color,
                    done: widget.done,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: widget.done
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('done'),
                              color: AppColors.background,
                              size: 26,
                            )
                          : Icon(
                              Icons.fingerprint_rounded,
                              key: const ValueKey('idle'),
                              color: Color.lerp(
                                AppColors.textMuted,
                                widget.color,
                                t,
                              ),
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.done,
  });

  final double progress;
  final Color color;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;

    if (done) {
      canvas.drawCircle(center, radius, Paint()..color = AppColors.reward);
      return;
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Color.lerp(AppColors.surfaceHigh, color, progress * 0.25)!,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.textMuted.withValues(alpha: 0.25),
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.done != done;
}
