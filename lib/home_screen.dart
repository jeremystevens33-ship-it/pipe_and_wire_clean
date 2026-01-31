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
  late Animation<double> _linearTextAnimation;

  // ============================================================
  // PIPES CONTROLS
  // ============================================================
  static const double kPipesScale = 1.05;
  static const double kPipesDx = -0.135; // fraction of screen width
  static const double kPipesDy = 0.33;  // fraction of screen height
  static const double kPipesBaseWidth = 1.25;

  // ============================================================
  // TEXT CONTROLS (layout)
  // ============================================================
  static const double kTextBandTop = 0.46; // fraction of screen height
  static const double kTextBandHeightPx = 220;

  static const double kPipeLeft = 0.18;
  static const double kAmpLeft  = 0.49;
  static const double kWireLeft = 0.59;

  static const double kPipeDyPx = -9;
  static const double kAmpDyPx  = 61;
  static const double kWireDyPx = 85;

  static const double kWordSize = 40;
  static const double kAmpSize  = 30;

  // ============================================================
  // TEXT ANIMATION CONTROLS (Coordinated for a mellow, even flow)
  // ============================================================
  // DURATION: Total time for one full sweep (left-to-right-to-left).
  static const double kTextCycleSeconds = 3.0;

  // WIDTH: How "wide" the bright spot is as a fraction of the total animation track (0..1).
  // A smaller value creates a tighter, faster flash.
  static const double kPulseWidth = 0.15;

  @override
  void initState() {
    super.initState();

    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // The base controller goes back and forth.
    _textAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (kTextCycleSeconds * 1000).round()),
    )..repeat(reverse: true);

    // We wrap it in a Linear curve to ensure constant speed.
    // This is the key to the smooth, even animation.
    _linearTextAnimation = CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

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
                            animation: _linearTextAnimation,
                            text: 'Pipe',
                            fontSize: kWordSize,
                            letterSpacing: 1.4,
                            pulseCenter: 0.55, // Position on the 0..1 track
                          ),
                        ),
                        Positioned(
                          left: w * kAmpLeft,
                          top: kAmpDyPx,
                          child: _AnimatedGradientWord(
                            animation: _linearTextAnimation,
                            text: '&',
                            fontSize: kAmpSize,
                            letterSpacing: 1.0,
                            pulseCenter: 0.7, // Position on the 0..1 track
                          ),
                        ),
                        Positioned(
                          left: w * kWireLeft,
                          top: kWireDyPx,
                          child: _AnimatedGradientWord(
                            animation: _linearTextAnimation,
                            text: 'Wire',
                            fontSize: kWordSize,
                            letterSpacing: 1.4,
                            pulseCenter: 0.85, // Position on the 0..1 track
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
                          splashColor: Colors.red.withAlpha(77),
                          highlightColor: Colors.red.withAlpha(26),
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
// ANIMATED GRADIENT WORD (REWRITTEN LOGIC)
// =======================================================
class _AnimatedGradientWord extends AnimatedWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;
  final double pulseCenter; // 0..1, position on the animation track

  const _AnimatedGradientWord({
    required Animation<double> animation,
    required this.text,
    required this.fontSize,
    required this.letterSpacing,
    required this.pulseCenter,
  }) : super(listenable: animation);

  Animation<double> get _progress => listenable as Animation<double>;

  // A smooth curve for the brightness pulse (bell curve)
  double _gaussian(double x, double peak, double width) {
    return math.exp(-math.pow(x - peak, 2) / (2 * math.pow(width, 2)));
  }

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.orbitron(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: letterSpacing,
    );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        final t = _progress.value; // This value now moves linearly from 0->1->0

        // 1. Calculate distance from the animation's progress to this word's center.
        final dist = (t - pulseCenter).abs();

        // 2. Use a Gaussian function to create a smooth brightness pulse based on distance.
        // The pulse is at its peak when the distance is 0.
        final activation = _gaussian(dist, 0.0, _HomeScreenState.kPulseWidth / 2);

        // 3. Map activation to brightness.
        final brightness = activation.clamp(0.0, 1.0);

        // 4. Calculate shimmer position. It moves across the word as 't' passes through the pulseCenter.
        // This value goes from -1 to 1 as the animation passes over the word.
        final shimmerPosition = ((t - pulseCenter) / (_HomeScreenState.kPulseWidth / 2)).clamp(-1.0, 1.0);

        // 5. Calculate the actual pixel offset for the gradient.
        final dx = shimmerPosition * bounds.width / 2;

        // 6. Blend colors based on brightness.
        const baseRed = Colors.red;
        const activeColors = [
          Colors.red, Colors.yellow, Colors.white, Colors.yellow, Colors.red,
        ];
        const activeStops = [0.0, 0.4, 0.5, 0.6, 1.0];

        final blendedColors =
        activeColors.map((c) => Color.lerp(baseRed, c, brightness)!).toList();

        // 7. Create the final gradient with the calculated offset.
        return LinearGradient(
          colors: blendedColors,
          stops: activeStops,
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
    const double waveHeight = 57.0;

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
