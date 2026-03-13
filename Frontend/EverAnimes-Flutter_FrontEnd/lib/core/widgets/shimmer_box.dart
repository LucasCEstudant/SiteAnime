import 'package:flutter/material.dart';

/// Shimmer effect widget – replaces static grey boxes with a
/// horizontal sweep animation. Lightweight, no external packages.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    // RepaintBoundary prevents the shimmer animation (rebuilds every frame)
    // from cascading dirty-paint flags up to parent widgets.
    // CustomPaint avoids creating new BoxDecoration/LinearGradient objects
    // every animation frame — the painter reuses the same object and only
    // repaints via the Listenable animation (no widget rebuild needed).
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: CustomPaint(
          painter: _ShimmerPainter(
            animation: _controller,
            baseColor: baseColor,
            highlightColor: highlightColor,
            borderRadius: widget.borderRadius,
          ),
        ),
      ),
    );
  }
}

/// CustomPainter that avoids creating new Gradient / BoxDecoration objects
/// every frame. Listens to the animation directly — Flutter calls paint()
/// without rebuilding any widget tree.
class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required Animation<double> animation,
    required this.baseColor,
    required this.highlightColor,
    required this.borderRadius,
  }) : super(repaint: animation),
       _animation = animation;

  final Animation<double> _animation;
  final Color baseColor;
  final Color highlightColor;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final gradient = LinearGradient(
      begin: Alignment(-1.0 + 2.0 * _animation.value, 0),
      end: Alignment(-1.0 + 2.0 * _animation.value + 1, 0),
      colors: [baseColor, highlightColor, baseColor],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.baseColor != baseColor ||
      old.highlightColor != highlightColor ||
      old.borderRadius != borderRadius;
}
