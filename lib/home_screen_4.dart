import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:typed_data';
// =============================================================
//  RUN-BY-ITSELF DEMO FILE (Home Screen Logo Art - v4)
//  Style: "Industrial / Tool" readable PW logo (bold + crisp)
//  Motion: subtle scan highlight across the monogram (not doodly)
// =============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const _DemoApp());
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: false),
      home: const HomeScreen(),
    );
  }
}

// Dummy target screen so Enter works in this standalone file.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Main Menu (Demo)"),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          "Placeholder screen.\nWire your real MainMenuScreen later.",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _borderAnimationController;
  late AnimationController _textAnimationController;

  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  // ✅ NEW (GREEN ARROW): Logo scan controller
  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  late AnimationController _logoScanController;
  // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

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

    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    // ✅ NEW (GREEN ARROW): slow scan = “industrial panel” vibe
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    _logoScanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _textAnimationController.dispose();
    _logoScanController.dispose();
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
              painter: _WireframePainter(animationValue: _borderAnimationController.value),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: _AnimatedGradientText(animation: _textAnimationController),
                ),
                const SizedBox(height: 26),

                // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                // ✅ NEW (GREEN ARROW): Center logo (bold / readable)
                // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                Expanded(
                  child: Center(
                    child: _PwIndustrialLogo(animation: _logoScanController),
                  ),
                ),
                // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900]?.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: const Text(
                      'Enter',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
      fontSize: 46,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      shadows: const [
        Shadow(
          blurRadius: 8.0,
          color: Colors.black,
          offset: Offset(3.0, 3.0),
        ),
      ],
    );

    // Your title scan
    return ShaderMask(
      shaderCallback: (bounds) {
        final dx = ui.lerpDouble(-bounds.width, bounds.width, _progress.value)! * 2.5;
        return LinearGradient(
          colors: const [Colors.red, Colors.yellow, Colors.white, Colors.yellow, Colors.red],
          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
          transform: _GradientMatrix(Matrix4.translationValues(dx, 0.0, 0.0).storage),
        ).createShader(bounds);
      },
      child: Text(
        'Pipe and Wire',
        textAlign: TextAlign.center,
        style: titleStyle.copyWith(color: Colors.white),
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

// =============================================================
// ✅ NEW: Industrial / readable PW logo
// - Bold monogram (not “wire squiggle”)
// - Badge plate + controlled glow
// - Scan highlight across the monogram
// =============================================================

class _PwIndustrialLogo extends StatelessWidget {
  final Animation<double> animation;
  const _PwIndustrialLogo({required this.animation});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = math.min(320.0, math.max(240.0, w * 0.64));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _PwIndustrialPainter(t: animation.value),
          ),
        );
      },
    );
  }
}

class _PwIndustrialPainter extends CustomPainter {
  final double t;
  _PwIndustrialPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Badge plate
    final plateRect = Rect.fromLTWH(size.width * 0.10, size.height * 0.10,
        size.width * 0.80, size.height * 0.80);
    final radius = Radius.circular(size.shortestSide * 0.14);
    final plate = RRect.fromRectAndRadius(plateRect, radius);

    // Plate fill (subtle)
    final plateFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withOpacity(0.35);
    canvas.drawRRect(plate, plateFill);

    // Plate outline (glow + core)
    final plateStroke = math.max(3.0, size.shortestSide * 0.018);

    final plateGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = plateStroke * 2.0
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8)
      ..shader = _brandSweep(rect, t).createShader(rect);

    final plateCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = plateStroke
      ..shader = _brandSweep(rect, t).createShader(rect);

    canvas.drawRRect(plate, plateGlow);
    canvas.drawRRect(plate, plateCore);

    // Monogram geometry: bold “PW” as engineered paths
    final pwPath = _buildPwMonogram(size);

    // Bold stroke so it feels like a tool logo
    final monoStroke = math.max(10.0, size.shortestSide * 0.055);

    // Under-glow (controlled, not foggy)
    final monoGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = monoStroke * 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10)
      ..shader = _monoGradient(rect).createShader(rect);

    // Solid core
    final monoCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = monoStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = _monoGradient(rect).createShader(rect);

    canvas.drawPath(pwPath, monoGlow);
    canvas.drawPath(pwPath, monoCore);

    // Scan highlight (thin bright band that moves across the monogram only)
    _drawScanHighlight(canvas, size, pwPath, monoStroke);
  }

  // Crisp, readable PW built from deliberate segments (not doodles).
  Path _buildPwMonogram(Size s) {
    final w = s.width;
    final h = s.height;

    final box = Rect.fromLTWH(w * 0.22, h * 0.26, w * 0.56, h * 0.48);

    final left = box.left;
    final right = box.right;
    final top = box.top;
    final bottom = box.bottom;
    final midY = (top + bottom) * 0.5;

    final p = Path();

    // --- P ---
    final pStemX = left + box.width * 0.12;
    final pTopY = top + box.height * 0.08;
    final pBotY = bottom - box.height * 0.08;

    final pBowlRightX = left + box.width * 0.40;
    final pBowlMidY = top + box.height * 0.30;

    p.moveTo(pStemX, pBotY);
    p.lineTo(pStemX, pTopY);
    p.lineTo(pBowlRightX, pTopY);

    // bowl back to mid
    p.quadraticBezierTo(
      left + box.width * 0.46,
      pBowlMidY,
      pBowlRightX,
      top + box.height * 0.46,
    );
    p.lineTo(pStemX, top + box.height * 0.46);

    // connector into W
    p.moveTo(left + box.width * 0.50, top + box.height * 0.36);

    // --- W ---
    final wStartX = left + box.width * 0.52;
    final wEndX = right - box.width * 0.08;

    final peakY = top + box.height * 0.20;
    final valleyY = bottom - box.height * 0.10;

    final x1 = wStartX;
    final x2 = left + box.width * 0.62;
    final x3 = left + box.width * 0.72;
    final x4 = left + box.width * 0.82;
    final x5 = wEndX;

    // Start high -> valley -> peak -> valley -> end
    p.moveTo(x1, peakY);
    p.lineTo(x2, valleyY);
    p.lineTo(x3, midY);
    p.lineTo(x4, valleyY);
    p.lineTo(x5, peakY + box.height * 0.12);

    return p;
  }

  SweepGradient _brandSweep(Rect rect, double t) {
    return SweepGradient(
      colors: [Colors.red.shade400, Colors.yellowAccent, Colors.red.shade400],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(2 * math.pi * t),
    );
  }

  LinearGradient _monoGradient(Rect rect) {
    return const LinearGradient(
      begin: Alignment(-1, 0),
      end: Alignment(1, 0),
      colors: [Colors.red, Colors.orange, Colors.yellow, Colors.white, Colors.yellow, Colors.orange, Colors.red],
      stops: [0.0, 0.18, 0.38, 0.50, 0.62, 0.82, 1.0],
    );
  }

  void _drawScanHighlight(Canvas canvas, Size size, Path pwPath, double monoStroke) {
    // Mask the scan to the monogram shape.
    canvas.save();
    canvas.clipPath(pwPath);

    final bounds = pwPath.getBounds();

    // Scan band position
    final bandX = ui.lerpDouble(bounds.left - bounds.width, bounds.right + bounds.width, t)!;

    final bandRect = Rect.fromLTWH(
      bandX - bounds.width * 0.10,
      bounds.top - monoStroke,
      bounds.width * 0.20,
      bounds.height + monoStroke * 2,
    );

    final scanPaint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bandRect);

    canvas.drawRect(bandRect, scanPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PwIndustrialPainter oldDelegate) => t != oldDelegate.t;
}

// =============================================================
// Border painter (same as yours)
// =============================================================

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
    path.quadraticBezierTo(size.width - 20, size.height, size.width - 40, size.height);

    path.lineTo(40, size.height);

    path.quadraticBezierTo(20, size.height, 20, size.height - 20);
    path.close();

    final colors = [Colors.red.shade400, Colors.yellowAccent, Colors.red.shade400];
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
