import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:pipe_and_wire_clean/main_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _borderAnimationController;
  late AnimationController _textAnimationController;

  @override
  void initState() {
    super.initState();
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _borderAnimationController,
          builder: (context, child) {
            return CustomPaint(
              painter: _WireframePainter(
                  animationValue: _borderAnimationController.value),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 32.0, vertical: 48.0),
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: const Alignment(0.0, -0.6),
                  child: _AnimatedGradientText(
                      animation: _textAnimationController),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4E4E52), Color(0xFF2C2C30)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.red.withOpacity(0.3),
                          highlightColor: Colors.red.withOpacity(0.1),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            child: Text(
                              'Enter',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedGradientText extends AnimatedWidget {
  const _AnimatedGradientText({required Animation<double> animation})
      : super(listenable: animation);

  Animation<double> get _progress => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.orbitron(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      shadows: const [
        Shadow(
          blurRadius: 8.0,
          color: Colors.black,
          offset: Offset(3.0, 3.0),
        ),
      ],
    );

    return ShaderMask(
      shaderCallback: (bounds) {
        final dx = ui.lerpDouble(-bounds.width, bounds.width, _progress.value)! * 2.5;

        return LinearGradient(
          colors: const [
            Colors.red,
            Colors.yellow,
            Colors.white,
            Colors.yellow,
            Colors.red,
          ],
          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
          transform: _GradientMatrix(
            Matrix4.translationValues(dx, 0.0, 0.0).storage,
          ),
        ).createShader(bounds);
      },
      child: Text(
        'Pipe and Wire',
        textAlign: TextAlign.center,
        style: titleStyle.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GradientMatrix extends GradientTransform {
  final Float64List matrix;

  const _GradientMatrix(this.matrix);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.fromFloat64List(matrix);
  }
}

class _WireframePainter extends CustomPainter {
  final double animationValue;

  _WireframePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0);

    final path = Path();
    double arcY = size.height * 0.18;
    double waveHeight = 50.0;

    path.moveTo(20, arcY);
    path.quadraticBezierTo(size.width * 0.20, arcY - waveHeight, size.width * 0.35, arcY);
    path.quadraticBezierTo(size.width * 0.50, arcY + waveHeight, size.width * 0.65, arcY);
    path.quadraticBezierTo(size.width * 0.80, arcY - waveHeight, size.width - 20, arcY);

    path.lineTo(size.width - 20, size.height - 20);
    path.quadraticBezierTo(
        size.width - 20, size.height, size.width - 40, size.height);

    path.lineTo(40, size.height);

    path.quadraticBezierTo(20, size.height, 20, size.height - 20);
    path.close();

    final colors = [
      Colors.red.shade400,
      Colors.yellowAccent,
      Colors.red.shade400
    ];
    final stops = [0.0, 0.5, 1.0];
    final gradient = SweepGradient(
      colors: colors,
      stops: stops,
      transform: GradientRotation(2 * math.pi * animationValue),
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);
    glowPaint.shader = gradient.createShader(rect);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WireframePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
