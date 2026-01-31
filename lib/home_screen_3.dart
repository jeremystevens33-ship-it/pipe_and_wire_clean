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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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

  // ============================================================
  // PIPES CONTROLS (your current values)
  // ============================================================
  static const double kPipesScale = 1.0;
  static const double kPipesDx = -0.11; // fraction of screen width
  static const double kPipesDy = 0.35;  // fraction of screen height
  static const double kPipesBaseWidth = 1.25;

  // ============================================================
  // TEXT CONTROLS (NOW STABLE)
  // ============================================================
  // Moves the whole text "band" up/down
  static const double kTextBandTop = 0.46; // fraction of screen height

  // Give the band an explicit height so Stack is NOT infinite
  static const double kTextBandHeightPx = 220;

  // Horizontal positions (fractions of screen width)
  static const double kPipeLeft = 0.18;
  static const double kAmpLeft  = 0.50;
  static const double kWireLeft = 0.59;

  // Vertical nudges INSIDE the band (pixels)
  static const double kPipeDyPx = 0;
  static const double kAmpDyPx  = 66;
  static const double kWireDyPx = 91;

  // Font sizes
  static const double kWordSize = 40;
  static const double kAmpSize  = 30;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1) BORDER
          SafeArea(
            child: AnimatedBuilder(
              animation: _borderAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WireframePainter(
                    animationValue: _borderAnimationController.value,
                  ),
                  child: child,
                );
              },
              child: const SizedBox.expand(),
            ),
          ),

          // 2) PIPES
          Positioned(
            left: w * kPipesDx,
            top: h * kPipesDy,
            child: Transform.scale(
              scale: kPipesScale,
              alignment: Alignment.topLeft,
              child: Image.asset(
                'assets/images/logo/pw_pipes.png',
                width: w * kPipesBaseWidth,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          // 3) TEXT + BUTTON
          SafeArea(
            child: Stack(
              children: [
                // ✅ Text band with fixed height (prevents Infinity layout crash)
                Positioned(
                  top: h * kTextBandTop,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: kTextBandHeightPx,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: w * kPipeLeft,
                          top: kPipeDyPx,
                          child: _AnimatedGradientWord(
                            animation: _textAnimationController,
                            text: 'Pipe',
                            fontSize: kWordSize,
                            letterSpacing: 1.4,
                          ),
                        ),
                        Positioned(
                          left: w * kAmpLeft,
                          top: kAmpDyPx,
                          child: _AnimatedGradientWord(
                            animation: _textAnimationController,
                            text: '&',
                            fontSize: kAmpSize,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Positioned(
                          left: w * kWireLeft,
                          top: kWireDyPx,
                          child: _AnimatedGradientWord(
                            animation: _textAnimationController,
                            text: 'Wire',
                            fontSize: kWordSize,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ENTER BUTTON (unchanged)
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
                              MaterialPageRoute(
                                builder: (context) => const MainMenuScreen(),
                              ),
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
        ],
      ),
    );
  }
}

// =======================================================
// ANIMATED GRADIENT WORD
// =======================================================
class _AnimatedGradientWord extends AnimatedWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;

  const _AnimatedGradientWord({
    required Animation<double> animation,
    required this.text,
    required this.fontSize,
    required this.letterSpacing,
  }) : super(listenable: animation);

  Animation<double> get _progress => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.orbitron(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: letterSpacing,
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
        final dx =
            ui.lerpDouble(-bounds.width, bounds.width, _progress.value)! * 2.5;

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
      child: Text(text, style: style.copyWith(color: Colors.white)),
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

// =======================================================
// BORDER PAINTER (unchanged)
// =======================================================
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
    final double arcY = size.height * 0.18;
    const double waveHeight = 50.0;

    path.moveTo(20, arcY);
    path.quadraticBezierTo(size.width * 0.20, arcY - waveHeight, size.width * 0.35, arcY);
    path.quadraticBezierTo(size.width * 0.50, arcY + waveHeight, size.width * 0.65, arcY);
    path.quadraticBezierTo(size.width * 0.80, arcY - waveHeight, size.width - 20, arcY);

    path.lineTo(size.width - 20, size.height - 20);
    path.quadraticBezierTo(size.width - 20, size.height, size.width - 40, size.height);

    path.lineTo(40, size.height);
    path.quadraticBezierTo(20, size.height, 20, size.height - 20);
    path.close();

    final gradient = SweepGradient(
      colors: [
        Colors.red.shade400,
        Colors.yellowAccent,
        Colors.red.shade400,
      ],
      stops: const [0.0, 0.5, 1.0],
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
