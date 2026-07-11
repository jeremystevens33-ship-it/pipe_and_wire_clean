import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AngleFinderScreen(),
  ));
}

class AngleFinderScreen extends StatefulWidget {
  const AngleFinderScreen({super.key});

  @override
  State<AngleFinderScreen> createState() => _AngleFinderScreenState();
}

class _AngleFinderScreenState extends State<AngleFinderScreen> with TickerProviderStateMixin {
  double _currentAngle = 0.0;
  double _offsetAngle = 0.0;
  bool _isZeroed = false;
  bool _isHeld = false;
  double _heldAngle = 0.0;
  StreamSubscription<AccelerometerEvent>? _subscription;

  // Smoothing (Low-pass filter)
  double _smoothedAngle = 0.0;
  static const double _smoothingFactor = 0.6; // Increased for much snappier response

  // Typical Bending Angles
  final List<double> _targets = [0.0, 10.0, 15.0, 22.5, 30.0, 45.0, 60.0, 90.0];
  double? _lastSnappedAngle;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    
    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!mounted || _isHeld) return;
      
      setState(() {
        // Calculate raw tilt angle
        double rawAngle = math.atan2(event.x, event.y) * 180 / math.pi;
        
        // snappier Low-Pass Filter
        _smoothedAngle = (_smoothedAngle * (1.0 - _smoothingFactor)) + (rawAngle * _smoothingFactor);
        _currentAngle = _smoothedAngle;
        
        _checkSnapping();
      });
    });
  }

  void _checkSnapping() {
    double display = _displayAngle;
    double? currentSnap;
    
    for (double target in _targets) {
      if ((display - target).abs() < 0.5) {
        currentSnap = target;
        break;
      }
    }

    if (currentSnap != null && _lastSnappedAngle != currentSnap) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
      _lastSnappedAngle = currentSnap;
    } else if (currentSnap == null) {
      _lastSnappedAngle = null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _toggleZero() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isZeroed = !_isZeroed;
      if (_isZeroed) {
        _offsetAngle = _currentAngle;
      } else {
        _offsetAngle = 0.0;
      }
    });
  }

  void _toggleHold() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (!_isHeld) {
        _heldAngle = _displayAngle; // Freeze the current reading
        _isHeld = true;
      } else {
        _isHeld = false;
      }
    });
  }

  double get _signedAngle {
    double angle = _currentAngle - _offsetAngle;
    if (angle > 180) angle -= 360;
    if (angle < -180) angle += 360;
    return angle;
  }

  double get _displayAngle {
    if (_isHeld) return _heldAngle;
    return _signedAngle.abs();
  }

  Color _getDisplayColor() {
    if (_isHeld) return Colors.cyanAccent;
    double display = _displayAngle;
    for (double target in _targets) {
      if ((display - target).abs() < 0.5) {
        return target == 0.0 || target == 90.0 ? Colors.greenAccent : Colors.yellowAccent;
      }
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final displayColor = _getDisplayColor();
    final double displayAngle = _displayAngle;
    final double signedAngle = _isHeld ? _heldAngle : _signedAngle;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Angle Finder & Level'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF080808)],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(15)),
            border: Border.all(color: const Color(0xFFC0C0C0), width: 6),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Action Buttons (Moved to Top)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    label: _isZeroed ? 'CLEAR' : 'ZERO',
                    onPressed: _toggleZero,
                    color: _isZeroed ? const Color(0xFFE53935) : const Color(0xFF8A1010),
                    isActive: _isZeroed,
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    label: _isHeld ? 'RELEASE' : 'HOLD',
                    onPressed: _toggleHold,
                    color: _isHeld ? Colors.cyan.shade900 : const Color(0xFF4E4E52),
                    isActive: _isHeld,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isHeld || _isZeroed)
                Text(
                  _isHeld ? 'ANGLE FROZEN' : 'REF: ${_offsetAngle.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: _isHeld ? Colors.cyanAccent : Colors.redAccent, 
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              
              const Spacer(),
              
              // Big Digital Display (Centered below buttons)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: displayColor.withAlpha(30),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: _buildFixedWidthAngle(displayAngle, displayColor),
                ),
              ),
              
              const SizedBox(height: 30),

              // Visual Bubble Level
              _buildBubbleLevel(signedAngle),
              
              const Spacer(),

              const Text(
                'Hold phone vertically against surface\nto measure tilt angle.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedWidthAngle(double angle, Color color) {
    final String angleStr = angle.toStringAsFixed(1);
    final textStyle = GoogleFonts.orbitron(
      fontSize: 80, // Slightly smaller to fit fixed widths
      fontWeight: FontWeight.w700,
      color: color,
    );

    // split the string into characters and wrap each digit in a fixed-width container
    final widgets = angleStr.split('').map<Widget>((char) {
      return SizedBox(
        width: char == '.' ? 25 : 60, // Increased from 55 to 60 for better digit spacing
        child: Center(
          child: Text(char, style: textStyle),
        ),
      );
    }).toList();

    widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('°', style: textStyle),
        )
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback onPressed, required Color color, bool isActive = false}) {
    return SizedBox(
      width: 135,
      height: 65,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: isActive ? Colors.cyanAccent : const Color(0xFFC0C0C0), 
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleLevel(double signedAngle) {
    // Bubble position logic: Linear 0 to 90 scale.
    // 0 is center (0.0), 90 is full right (1.0), -90 is full left (-1.0)
    double bubblePos = (signedAngle / 90.0).clamp(-1.0, 1.0);

    final isLevel = signedAngle.abs() < 0.5 || (signedAngle.abs() - 90).abs() < 0.5;

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 60, // Slightly taller for better scale visibility
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB0B0B0), Color(0xFFE0E0E0), Color(0xFFB0B0B0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF808080), width: 2.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 6, offset: const Offset(0, 4)),
            ]
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Liquid background
              Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              
              // Bending Target Tick Marks (10, 22.5, 30, 45, 60)
              _buildLevelTicks(),

              // Center Level markings - High Visibility
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 3.5, 
                    height: 40, 
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(180),
                      boxShadow: [BoxShadow(color: Colors.white.withAlpha(50), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 44),
                  Container(
                    width: 3.5, 
                    height: 40, 
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(180),
                      boxShadow: [BoxShadow(color: Colors.white.withAlpha(50), blurRadius: 4)],
                    ),
                  ),
                ],
              ),

              // The Bubble
              AnimatedAlign(
                duration: const Duration(milliseconds: 100),
                alignment: Alignment(bubblePos, 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5), // Keeps bubble inside the rim
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isLevel 
                          ? [Colors.greenAccent, Colors.green.shade900]
                          : [Colors.yellowAccent, Colors.orange.shade900],
                        center: const Alignment(-0.3, -0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isLevel ? Colors.green : Colors.yellow).withAlpha(150),
                          blurRadius: 12,
                        )
                      ]
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isLevel ? "LEVEL / PLUMB" : "ADJUST TILT",
          style: TextStyle(
            color: isLevel ? Colors.greenAccent : Colors.white24,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.5
          ),
        )
      ],
    );
  }

  Widget _buildLevelTicks() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double centerX = constraints.maxWidth / 2;
        final double halfWidth = constraints.maxWidth / 2 - 25; // Account for bubble radius
        
        return Stack(
          children: [
            // Marks for 22.5, 30, 45, 60 on both sides
            ...[22.5, 30.0, 45.0, 60.0].expand((angle) {
              final double pos = angle / 90.0;
              return [
                Positioned(left: centerX + (halfWidth * pos), child: _tick(angle == 30 || angle == 45)),
                Positioned(left: centerX - (halfWidth * pos), child: _tick(angle == 30 || angle == 45)),
              ];
            }),
          ],
        );
      }
    );
  }

  Widget _tick(bool primary) {
    return Container(
      width: primary ? 2 : 1,
      height: primary ? 15 : 8,
      color: Colors.white.withAlpha(primary ? 60 : 30),
    );
  }
}
