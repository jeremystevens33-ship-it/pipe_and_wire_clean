import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';
import 'package:pipe_and_wire_clean/pipe_and_box_fill.dart';
import 'package:pipe_and_wire_clean/feet_inch_fraction_calculator.dart';
import 'package:pipe_and_wire_clean/triangle_calculator.dart';
import 'package:pipe_and_wire_clean/box_layout_mode.dart';
import 'package:pipe_and_wire_clean/kick_90.dart';
import 'package:pipe_and_wire_clean/rack_builder_11.dart';
import 'package:pipe_and_wire_clean/back_to_back_90_2.dart';
import 'package:pipe_and_wire_clean/code_screen.dart';
import 'package:pipe_and_wire_clean/load_calculator2.dart';
import 'package:pipe_and_wire_clean/segmented_90_plus_radius_screen.dart';
import 'package:pipe_and_wire_clean/radius_arc_finder_screen.dart';
import 'package:pipe_and_wire_clean/power_equations_solver.dart';
import 'package:pipe_and_wire_clean/reference_hub.dart';
import 'offset_starting_point_screen.dart';
import 'package:pipe_and_wire_clean/saddle_bend_screen.dart';
import 'package:pipe_and_wire_clean/angle_finder_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _infoAnimCtrl;
  bool _anySectionExpanded = false;

  @override
  void initState() {
    super.initState();
    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _infoAnimCtrl.dispose();
    super.dispose();
  }

  void _showGeneralHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
        ),
        title: const Text(
          "Pipe & Wire Guide",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  "Welcome to the ultimate field companion for electrical professionals.",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _HelpBullet(
                  icon: Icons.info_outline,
                  title: "Info Menus",
                  text: "Always look for the (i) icon at the top. It contains detailed field guides for that specific screen.",
                ),
                SizedBox(height: 12),
                _HelpBullet(
                  icon: Icons.chat_bubble_outline,
                  title: "Instruction Bar",
                  text: "The bar at the bottom of most screens will guide you step-by-step through the layout process.",
                ),
                SizedBox(height: 12),
                _HelpBullet(
                  icon: Icons.ads_click,
                  title: "Smart Buttons",
                  text: "Calculators use RED buttons for required inputs and GREEN buttons for final results or confirmations.",
                ),
                SizedBox(height: 16),
                Text(
                  "Tap any section to get started.",
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "GOT IT",
              style: TextStyle(color: Color(0xFFFF3B30), fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.orbitron(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: Colors.red,
      letterSpacing: 1.5,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000), // Deep black
              Color(0xFF1A1A1A), // Gunmetal
              Color(0xFF0A0A0A), // Back to dark
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent, // Let the gradient show through
              elevation: 0,
              centerTitle: true,
              title: Text(
                'MENU',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    RotationTransition(
                      turns: _infoAnimCtrl,
                      child: AnimatedBuilder(
                        animation: _infoAnimCtrl,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (rect) {
                              return SweepGradient(
                                colors: [
                                  Colors.white.withAlpha(0),
                                  Colors.white.withAlpha(200),
                                  Colors.white.withAlpha(0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ).createShader(rect);
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.0),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: _showGeneralHelpDialog,
                      tooltip: 'General Help',
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  // BACKGROUND LOGO
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      opacity: _anySectionExpanded ? 0.08 : 0.6,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 360.0), 
                          child: Transform.scale(
                            scale: 1.45,
                            child: Image.asset(
                              'assets/images/logo/sticker_logo.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // MENU CONTENT
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFC0C0C0).withAlpha(80), width: 1.0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                          children: [
                            // 1. PIPE
                            _buildExpansionSection(
                              title: 'Pipe',
                              style: titleStyle,
                              children: [
                                _buildMenuButton(context, 'Kick 90', () => const Kick90Screen()),
                                _buildMenuButton(context, 'Back to Back 90', () => const BackToBack90ScreenV2()),
                                _buildMenuButton(
                                  context,
                                  'Offset',
                                  () => const OffsetStartingPointScreen(),
                                ),
                                _buildMenuButton(context, 'Saddles', () => const SaddleBendScreen()),
                                _buildMenuButton(context, 'Segmented 90 + Radius', () => const Segmented90PlusRadiusScreen()),
                                _buildMenuButton(context, 'Rack Builder', () {
                                  return ChangeNotifierProvider(
                                    create: (_) => RackState(),
                                    child: const RackBuilderScreen(),
                                  );
                                }),
                                const SizedBox(height: 4),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 2. CALCULATORS
                            _buildExpansionSection(
                              title: 'Calculators',
                              style: titleStyle,
                              children: [
                                _buildMenuButton(context, 'Triangle + Shrink', () => const TriangleCalculator()),
                                _buildMenuButton(context, 'Box Layout', () => const BoxLayoutModeScreen()),
                                _buildMenuButton(context, 'Feet - Inch - Fraction', () => const FeetInchFractionCalculator()),
                                _buildMenuButton(
                                  context,
                                  'Pipe + Box Fill',
                                  () => const PipeAndBoxFill(),
                                  subtitle: 'Derate + V Drop',
                                ),
                                _buildMenuButton(context, 'Load Calculator', () => const LoadCalculator2()),
                                _buildMenuButton(context, 'Radius / Arc Finder', () => const RadiusArcFinderScreen()),
                                const SizedBox(height: 4),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 3. TOOLS & REFERENCE
                            _buildExpansionSection(
                              title: 'Tools & Reference',
                              style: titleStyle,
                              children: [
                                _buildMenuButton(context, 'Angle Finder & Level', () => const AngleFinderScreen(), subtitle: 'Real-time Tilt Meter'),
                                _buildMenuButton(context, 'Digital Reference Hub', () => const ReferenceHub(), subtitle: 'Charts, ODs, & Phase Colors'),
                                _buildMenuButton(context, 'Power Hub Solver', () => const PowerEquationsSolver(), subtitle: 'Ohm\'s Law Bubble Puzzle'),
                                const SizedBox(height: 4),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 4. CODE
                            _buildExpansionSection(
                              title: 'Code',
                              style: titleStyle,
                              children: [
                                _buildMenuButton(context, 'NEC Code Reference', () => const CodeScreen()),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // FIXED FOOTER BUTTONS
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFooterLink(
                    icon: Icons.play_circle_fill,
                    color: const Color(0xFFFF0000), // YouTube Red
                    onTap: () {
                      // TODO: Add YouTube Link
                    },
                  ),
                  _buildFooterDivider(),
                  _buildFooterLink(
                    label: 'WEB',
                    onTap: () {
                      // TODO: Add Website Link
                    },
                  ),
                  _buildFooterDivider(),
                  _buildFooterLink(
                    label: 'UPLOAD',
                    icon: Icons.cloud_upload_outlined,
                    onTap: () {
                      // TODO: Add Upload Logic
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionSection({required String title, required TextStyle style, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white38, width: 1.2),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title, style: style),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          onExpansionChanged: (expanded) {
            setState(() {
              _anySectionExpanded = expanded;
            });
          },
          children: children,
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, Widget Function() builder, {String? subtitle}) {
    return _buildStyledButton(
      context: context,
      title: title,
      subtitle: subtitle,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (context) => builder()));
      },
    );
  }

  Widget _buildStyledButton({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4E4E52), Color(0xFF2C2C30)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF9E9E9e), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.red.withAlpha(50),
            highlightColor: Colors.red.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white54, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink({String? label, IconData? icon, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color ?? Colors.white70, size: 24),
              if (label != null) const SizedBox(width: 8),
            ],
            if (label != null)
              Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterDivider() {
    return const Text(
      '/',
      style: TextStyle(
        color: Colors.white24,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
    );
  }
}

class _HelpBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _HelpBullet({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.red, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
