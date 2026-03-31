import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';
import 'package:pipe_and_wire_clean/feeder_calculator.dart';
import 'package:pipe_and_wire_clean/fraction_calculator_1.dart';
import 'package:pipe_and_wire_clean/triangle_calculator.dart';
import 'package:pipe_and_wire_clean/box_layout_mode.dart';
import 'package:pipe_and_wire_clean/kick_90.dart';
import 'package:pipe_and_wire_clean/rack_builder_11.dart';
import 'package:pipe_and_wire_clean/back_to_back_90_screen.dart';
import 'package:pipe_and_wire_clean/code_screen.dart';
import 'package:pipe_and_wire_clean/code_sections/Load_Calculator.dart';
import 'package:pipe_and_wire_clean/load_calculator2.dart';
import 'package:pipe_and_wire_clean/segmented_90_plus_radius_screen.dart'; // Added import for new screen
import 'package:pipe_and_wire_clean/radius_arc_finder_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.orbitron(
      fontSize: 35,
      fontWeight: FontWeight.w700,
      color: Colors.red,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        // Removed: automaticallyImplyLeading: false, // This removes the back arrow
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          ExpansionTile(
            title: Text('Calculators', style: titleStyle),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            children: [
              _buildMenuButton(context, 'Triangle + Shrink', () => const TriangleCalculator()),
              _buildMenuButton(context, 'Box Layout', () => const BoxLayoutModeScreen()),
              _buildMenuButton(context, 'Feet - Inch - Fraction', () => const FractionCalculator()),
              _buildMenuButton(
                context,
                'Pipe + Box Fill',
                () => const UnifiedFeederCalculator(),
                subtitle: 'Derate + V Drop',
              ),
              _buildMenuButton(context, 'Load Calculator', () => const LoadCalculator()), // Corrected class name
              const SizedBox(height: 8.0),
              _buildMenuButton(context, 'Load Calculator 2', () => const LoadCalculator2()),
              _buildMenuButton(context, 'Radius / Arc Finder', () => const RadiusArcFinderScreen()), // Added new screen
            ],
          ),
          ExpansionTile(
            title: Text('Pipe', style: titleStyle),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            children: [
              _buildMenuButton(context, 'Kick 90', () => const BendCalculator()),
              _buildMenuButton(context, 'Back to Back 90', () => const BackToBack90ScreenV2()),
              _buildMenuButton(context, 'Segmented 90 + Radius', () => const Segmented90PlusRadiusScreen()), // Added new screen
              _buildMenuButton(context, 'Rack Builder', () {
                // This screen needs its own provider, which is fine
                return ChangeNotifierProvider(
                  create: (_) => RackState(),
                  child: const RackBuilderScreen(),
                );
              }),
              const SizedBox(height: 8.0),
            ],
          ),
          ExpansionTile(
            title: Text('Code', style: titleStyle),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            children: [
              _buildMenuButton(context, 'NEC Code Reference', () => const CodeScreen()), // Consolidated to CodeScreen
              const SizedBox(height: 8.0),
            ],
          ),
        ],
      ),
    );
  }

  // General purpose button for all sections
  Widget _buildMenuButton(BuildContext context, String title, Widget Function() builder, {String? subtitle}) {
    return _buildStyledButton(
      context: context,
      title: title,
      subtitle: subtitle,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => builder())),
    );
  }

  // Shared button styling to reduce code duplication
  Widget _buildStyledButton({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
            splashColor: Colors.grey.withAlpha(77), // 0.3 opacity
            highlightColor: Colors.grey.withAlpha(26), // 0.1 opacity
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}