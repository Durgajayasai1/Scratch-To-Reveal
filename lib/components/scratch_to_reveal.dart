import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ScratchToReveal extends StatefulWidget {
  final double width;
  final double height;
  final double minScratchPercentage;
  final VoidCallback? onComplete;
  final Widget child;
  final List<Color> gradientColors;

  const ScratchToReveal({
    Key? key,
    required this.width,
    required this.height,
    this.minScratchPercentage = 50,
    this.onComplete,
    required this.child,
    this.gradientColors = const [
      Color(0xFF074799),
      Color(0xFF074799),
      Color(0xFF640D6B),
      Color(0xFF640D6B),
    ],
  }) : super(key: key);

  @override
  State<ScratchToReveal> createState() => _ScratchToRevealState();
}

class _ScratchToRevealState extends State<ScratchToReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Set<String> _scratchedPixels = {};
  final List<Offset> _points = [];
  bool _isComplete = false;
  final double _scratchRadius = 20;
  ui.Image? _scratchImage;
  final int _gridSize = 10; // Size of grid cells for scratch tracking

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _createScratchImage();
  }

  Future<void> _createScratchImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(widget.width, widget.height);

    // Draw background
    final Paint backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Draw gradient
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.gradientColors,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, gradientPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      widget.width.toInt(),
      widget.height.toInt(),
    );

    setState(() {
      _scratchImage = image;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scratchImage?.dispose();
    super.dispose();
  }

  void _markGridCellsAsScratched(Offset point) {
    final radius = _scratchRadius.toInt();
    final gridCells = <String>{};

    for (int dx = -radius; dx <= radius; dx += _gridSize) {
      for (int dy = -radius; dy <= radius; dy += _gridSize) {
        if (dx * dx + dy * dy <= radius * radius) {
          final x = ((point.dx + dx) ~/ _gridSize) * _gridSize;
          final y = ((point.dy + dy) ~/ _gridSize) * _gridSize;

          if (x >= 0 && x < widget.width && y >= 0 && y < widget.height) {
            gridCells.add('$x,$y');
          }
        }
      }
    }

    setState(() {
      _scratchedPixels.addAll(gridCells);
    });
  }

  void _handlePanDown(DragDownDetails details) {
    if (_isComplete) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    _points.add(localPosition);
    _markGridCellsAsScratched(localPosition);
    _checkCompletion();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isComplete) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);

    // Add point and interpolate between last point if needed
    if (_points.isNotEmpty) {
      final lastPoint = _points.last;
      final distance = (localPosition - lastPoint).distance;
      if (distance > _gridSize) {
        final steps = (distance / _gridSize).ceil();
        for (int i = 1; i <= steps; i++) {
          final t = i / steps;
          final interpolatedPoint = Offset.lerp(lastPoint, localPosition, t)!;
          _points.add(interpolatedPoint);
          _markGridCellsAsScratched(interpolatedPoint);
        }
      } else {
        _points.add(localPosition);
        _markGridCellsAsScratched(localPosition);
      }
    } else {
      _points.add(localPosition);
      _markGridCellsAsScratched(localPosition);
    }

    setState(() {});
    _checkCompletion();
  }

  void _checkCompletion() {
    if (_scratchedPixels.isEmpty) return;

    final totalCells = (widget.width * widget.height) / (_gridSize * _gridSize);
    final percentage = (_scratchedPixels.length / totalCells) * 100;

    if (percentage >= widget.minScratchPercentage && !_isComplete) {
      setState(() {
        _isComplete = true;
        _points.clear();
      });
      _playRevealAnimation();
    }
  }

  void _playRevealAnimation() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_scratchImage == null) {
      return const SizedBox();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Content with animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (!_isComplete) return const SizedBox();

                final bounce = Curves.elasticOut.transform(_controller.value);
                final scale = 0.7 + (bounce * 0.3);

                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Center(child: widget.child),
            ),

            // Scratch layer
            if (!_isComplete)
              GestureDetector(
                onPanDown: _handlePanDown,
                onPanUpdate: _handlePanUpdate,
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: ScratchPainter(
                    points: _points,
                    radius: _scratchRadius,
                    image: _scratchImage!,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ScratchPainter extends CustomPainter {
  final List<Offset> points;
  final double radius;
  final ui.Image image;

  ScratchPainter({
    required this.points,
    required this.radius,
    required this.image,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the scratch layer image
    canvas.drawImage(image, Offset.zero, Paint());

    // Create scratch effect
    final Paint scratchPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = radius * 2
      ..isAntiAlias = true;

    // Draw scratches
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, scratchPaint);

      // Draw dots for better coverage
      final dotPaint = Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, radius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(ScratchPainter oldDelegate) => true;
}
