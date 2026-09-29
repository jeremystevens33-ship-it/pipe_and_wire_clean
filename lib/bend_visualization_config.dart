/// Shared presentation configuration for conduit picture cards.
///
/// This file owns visual coordinates, scales, and asset-layout measurements.
/// It must not contain or alter conduit bending formulas. Calculation authority
/// remains in `bending_data.dart`, with rack-wide application in `rack_state.dart`.

// Rack Builder results use a fixed design canvas that is scaled to card width.
const double designW = 1920;
const double designH = 1080;

// ---------------------------------------------------------------------------
// RACK BUILDER — SHARED RESULT-CARD ANCHORS
// ---------------------------------------------------------------------------

// All vertical distances are measured upward from the picture-card border.
const double bottomPipeGlue = 150.0;
const double bottomMarkGlue = 240.0;
const double bottomMeasureTextGlue = 0.0;
const double bottomPipePaddingX = 40.0;

// "Measure from this end" presentation. Direction still comes from RackState.
const double measureInstructionHorizontalPadding = 16.0;
const double measureInstructionVerticalPadding = 6.0;
const double measureInstructionArrowGap = 8.0;
const double measureInstructionLeftXShift = 0.0;
const double measureInstructionRightXShift = 0.0;
const double measureInstructionLeftArrowYShift = 0.0;
const double measureInstructionRightArrowYShift = -3.0;

// Minimum card aspect ratio, with a taller-phone expansion target.
const double resultsCardHeightViewportFraction = 0.34;

// ---------------------------------------------------------------------------
// RACK BUILDER — PARALLEL 90 RESULTS
// ---------------------------------------------------------------------------

// LEFT picture: main image.
// X: increase to move right; decrease to move left.
// Y: distance upward from the bottom; increase to move the picture up.
const double p90MainXShift_Left = -40.0;
const double p90MainYShift_Left = 385.0;
const double p90MainScale_Left = 0.95;
const double p90MainScaleY_Left = 0.90;

// LEFT picture: marks and selector dots.
const double p90BottomMarkGlue_Left = 220.0;
const double p90MarkA_Left_X = 300.0;
const double p90MarkC_Left_X = 100.0;
const double p90DotX_Left = 1835.0;
const double p90DotY1_Left = 1225.0;
const double p90DotY2_Left = 1085.0;
const double p90DotY3_Left = 935.0;

// RIGHT picture: main image.
const double p90MainXShift_Right = -40.0;
const double p90MainYShift_Right = 350.0;
const double p90MainScale_Right = 0.95;
const double p90MainScaleY_Right = 0.95;

// RIGHT picture: marks and selector dots.
const double p90BottomMarkGlue_Right = 240.0;
const double p90MarkA_Right_X = 1200.0;
const double p90MarkC_Right_X = 1400.0;
const double p90DotX_Right = 1830.0;
const double p90DotY1_Right = 810.0;
const double p90DotY2_Right = 660.0;
const double p90DotY3_Right = 505.0;

// ---------------------------------------------------------------------------
// RACK BUILDER — OFFSET RESULTS
// ---------------------------------------------------------------------------

// Main images. Y is measured upward from the picture-card bottom.
const double offMainY_Left = 475.0;
const double offMainY_Right = 400.0;
const double offMainY_Up = 400.0;
const double offMainY_Down = 400.0;
const double offsetMainScale = 0.95;

// LEFT picture: marks and selector dots.
const double offMarkC_Left_X = 100.0;
const double offMarkA_Left_X = 520.0;
const double offMarkB_Left_X = 960.0;
const double offDotX_Left = 15.0;
const double offDotY1_Left = 1015.0;
const double offDotY2_Left = 825.0;
const double offDotY3_Left = 635.0;

// RIGHT picture: marks and selector dots.
const double offMarkC_Right_X = 100.0;
const double offMarkA_Right_X = 520.0;
const double offMarkB_Right_X = 960.0;
const double offDotX_Right = 15.0;
const double offDotY1_Right = 1280.0;
const double offDotY2_Right = 1090.0;
const double offDotY3_Right = 900.0;

// ---------------------------------------------------------------------------
// RACK BUILDER — KICK 90 RESULTS (STEP 5)
// ---------------------------------------------------------------------------

// Row format:
// [ImageX, ImageY, ScaleX, ScaleY, MarkA, MarkB, MarkC,
//  DotX, DotY1, DotY2, DotY3]
//
// Direction keys combine the selected kick direction and 90 turn direction:
// upRight, downRight, upLeft, and downLeft.
// A missing entry uses the shared result-card height above.
const Map<String, Map<String, double>> kickResultCardHeightFractions = {
  'Same Angle': {
    'downLeft': 0.28,
  },
};

// Verified result/preview photographs. Null means that direction still needs
// a photograph and must display the explicit placeholder card.
const Map<String, Map<String, String?>> kickPictureAssets = {
  'Parallel': {
    'upRight': 'assets/images/rack_builder/parallel_90.png',
    'downRight': 'assets/images/rack_builder/parallel_90_2.png',
    'upLeft': 'assets/images/rack_builder/kick_90s_parallel_up_left.png',
    'downLeft': 'assets/images/rack_builder/kick_90s_parallel_down_left.png',
  },
  'Forward': {
    'upRight': 'assets/images/rack_builder/kick_90_forward.png',
    'downRight': 'assets/images/rack_builder/kick_forward_90_2.png',
    'upLeft': 'assets/images/rack_builder/kick_90s_forward_up_left.png',
    'downLeft': 'assets/images/rack_builder/kick_90s_forward_down_left.png',
  },
  'Same Angle': {
    'upRight': 'assets/images/rack_builder/kick_90s_cp_same_angle.png',
    'downRight':
        'assets/images/rack_builder/kick_90s_cp_same_angle_down_right.png',
    'upLeft': 'assets/images/rack_builder/kick_90s_cp_same_angle_up_left.png',
    'downLeft': 'assets/images/rack_builder/kick_90s_cp_same_angle_ld.png',
  },
  '90 → Match Bend': {
    'upRight': 'assets/images/rack_builder/cp_90_to_match_bend_right.png',
    'downRight':
        'assets/images/rack_builder/kick_90s_CP_90_to_match_bend_down_right.png',
    'upLeft':
        'assets/images/rack_builder/kick_90s_CP_90_to_match_bend_up_left_.png',
    'downLeft': 'assets/images/rack_builder/cp_90_to_match_bend_left.png',
  },
  'Same Angle 2': {
    'upRight': 'assets/images/rack_builder/sp_same_angle_down_right.png',
    'downRight':
        'assets/images/rack_builder/sp_same_angle_down_right_.png',
    'upLeft': 'assets/images/rack_builder/sp_same_angle_up_left.png',
    'downLeft': 'assets/images/rack_builder/sp_same_angle_down__left.png',
  },
  '90 → Match Bend 2': {
    'upRight': 'assets/images/rack_builder/sp_90_to_match_bend_up_right.png',
    'downRight': 'assets/images/rack_builder/sp_90_to_match_bend_down__right.png',
    'upLeft': 'assets/images/rack_builder/sp_90_to_match_bend_up__left.png',
    'downLeft': 'assets/images/rack_builder/sp_90_to_match_bend_down_left.png',
  },
};

const int kickImageXIndex = 0;
const int kickImageYIndex = 1;
const int kickImageScaleXIndex = 2;
const int kickImageScaleYIndex = 3;
const int kickMarkAIndex = 4;
const int kickMarkBIndex = 5;
const int kickMarkCIndex = 6;
const int kickDotXIndex = 7;
const int kickDotY1Index = 8;
const int kickDotY2Index = 9;
const int kickDotY3Index = 10;

// dart format off
const Map<String, Map<String, List<double>>> kickResultsConfig = {
  // PARALLEL — Change Plane
  'Parallel': {
    'upRight':    [-40.0, 350.0, .95, 1.10, 200.0, 700.0, 1600.0, 1855.0, 860.0, 745.0, 635.0],
    'downRight':  [-45.0, 350.0, .93, 1.05, 200.0, 700.0, 1600.0, 1840.0, 1100.0, 995.0, 875.0],
    'upLeft':     [-40.0, 350.0, .93, 1.05, 200.0, 700.0, 1600.0, 1850.0, 805.0, 687.0, 580.0],
    'downLeft':   [-45.0, 350.0, .93, 1.10, 200.0, 700.0, 1600.0, 1850.0, 1180.0, 1055.0, 925.0],
  },

  // FORWARD — Change Plane
  'Forward': {
    'upRight':    [-40.0, 350.0, .94, 1.0, 200.0, 700.0, 1600.0, 1850.0, 860.0, 735.0, 600.0],
    'downRight':  [-25.0, 350.0, 1.12, 1.12, 200.0, 700.0, 1600.0, 1860.0, 1125.0, 1000.0, 875.0],
    'upLeft':     [-55.0, 350.0, .94, 1.0, 200.0, 700.0, 1600.0, 1850.0, 820.0, 670.0, 525.0],
    'downLeft':   [50.0, 350.0, 1.0, .95, 200.0, 700.0, 1600.0, 25.0, 880.0, 710.0,535.0],
  },

  // SAME ANGLE — Change Plane.
  // The current left asset is the photographed DOWN + LEFT variant.
  'Same Angle': {
    // Equal X/Y scales preserve the photographed round conduit openings.
    'upRight':    [-15.0, 350.0, .94, 1.5, 200.0, 700.0, 1600.0, 21.0, 1265.0, 1110.0, 955.0],
    'downRight':  [-15.0, 350.0, .94, 1.5, 200.0, 700.0, 1600.0, 21.0, 770, 630.0, 480.0],
    'upLeft':     [ 25.0, 260.0, .95, 1.15, 200.0, 700.0, 1600.0, 15.0, 1040.0, 920.0, 800.0],
    'downLeft':   [ 20.0, 260.0, .95, 1.15, 200.0, 700.0, 1600.0, 15.0, 760.0, 640.0, 520.0],
  },

  // 90 TO MATCH BEND — Change Plane
  '90 → Match Bend': {
    'upRight':    [30.0, 350.0, 1.0, 1.0, 200.0, 700.0, 1600.0, 25.0, 1185.0, 1050.0, 895.0],
    'downRight':  [40.0, 350.0, 1.0, 1.0, 200.0, 700.0, 1600.0, 25.0, 860.0, 730.0, 590.0],
    'upLeft':     [35.0, 350.0, 1.0, 1.0, 200.0, 700.0, 1600.0, 25.0, 1140.0, 985.0, 825.0],
    'downLeft':   [50.0, 350.0, 1.0, 1.0, 200.0, 700.0, 1600.0, 25.0, 790.0, 640.0, 480.0],
  },

  // SAME ANGLE 2 — Same Plane
  'Same Angle 2': {
    'upRight':    [-12.0, 350.0, 1.0, 1.0, 200.0, 700.0, 1600.0, 1880.0, 565.0, 410.0, 260.0],
    'downRight':  [-12.0, 400.0, 1.0, 1.0, 200.0, 700.0, 1600.0, 1700.0, 565.0, 410.0, 260.0],
    'upLeft':     [-12.0, 350.0, 1.0, 1.2, 200.0, 700.0, 1600.0, 1880.0, 565.0, 410.0, 260.0],
    'downLeft':   [-12.0, 350.0, .97, 1.15, 200.0, 700.0, 1600.0, 1880.0, 570.0, 410.0, 260.0],
  },

  // 90 TO MATCH BEND 2 — Same Plane
  '90 → Match Bend 2': {
    'upRight':    [-12.0, 350.0, .97, 1.2, 200.0, 700.0, 1600.0, 1880.0, 565.0, 410.0, 260.0],
    'downRight':  [-12.0, 430.0, .97, 1.2, 200.0, 700.0, 1600.0, 1880.0, 565.0, 410.0, 260.0],
    'upLeft':     [-12.0, 350.0, 1.0, 1.15, 200.0, 700.0, 1600.0, 1880.0, 565.0, 410.0, 260.0],
    'downLeft':   [-12.0, 400.0, 1.0, 1.15, 200.0, 700.0, 1600.0, 1880.0, 565.0, 410.0, 260.0],
  },
};
// dart format on

// Change an entry to true when that picture is clearer with selector dots
// running left-to-right instead of top-to-bottom.
const Map<String, Map<String, bool>> kickDotsHorizontal = {
  'Parallel': {'upRight': false, 'downRight': false, 'upLeft': false, 'downLeft': false},
  'Forward': {'upRight': false, 'downRight': false, 'upLeft': false, 'downLeft': false},
  'Same Angle': {'upRight': false, 'downRight': false, 'upLeft': false, 'downLeft': false},
  '90 → Match Bend': {'upRight': false, 'downRight': false, 'upLeft': false, 'downLeft': false},
  'Same Angle 2': {'upRight': true, 'downRight': true, 'upLeft': true, 'downLeft': true,},
  '90 → Match Bend 2': {'upRight': true, 'downRight': true, 'upLeft': true, 'downLeft': true},
};

// Picture-specific pipe-order overrides for result-card selector dots.
// true means the photographed order is outside-to-inside from top to bottom,
// so visual pipe 1 belongs on the bottom conduit.
const Map<String, Map<String, bool>> kickReversePipeOrder = {
  'Parallel': {
    'downRight': true,
    // This photograph shows the inside pipe at the top.
    'upLeft': false,
  },
  'Forward': {
    'downRight': true,
    // Up Left now uses the same P1-at-top identity as Up Right. Paired with
    // the rack-strip reversal, each circle still targets the same photo dot.
    'upLeft': false,
  },
  'Same Angle 2': {
    'downRight': true,
  },
  '90 → Match Bend 2': {
    'upRight': true,
    'downRight': true,
    'upLeft': true,
  },
  'Same Angle': {
    'downRight': false,
    'downLeft': false,
  },
};

// Used only when the matching orientation above is true.
// Row format: [Dot1X, Dot1Y, Dot2X, Dot2Y, Dot3X, Dot3Y]
const Map<String, Map<String, List<double>>> kickHorizontalDotPositions = {
  'Parallel': {
    'upRight': [260, 900, 650, 900, 1400, 900],
    'downRight': [260, 900, 650, 900, 1400, 900],
    'upLeft': [260, 900, 650, 900, 1400, 900],
    'downLeft': [260, 900, 650, 900, 1400, 900],
  },
  'Forward': {
    'upRight': [260, 900, 650, 900, 1400, 900],
    'downRight': [260, 900, 650, 900, 1400, 900],
    'upLeft': [260, 900, 650, 900, 1400, 900],
    'downLeft': [260, 900, 650, 900, 1400, 900],
  },
  'Same Angle': {
    'upRight': [260, 900, 650, 900, 1400, 900],
    'downRight': [260, 900, 650, 900, 1400, 900],
    'upLeft': [260, 900, 650, 900, 1400, 900],
    'downLeft': [260, 900, 650, 900, 1400, 900],
  },
  '90 → Match Bend': {
    'upRight': [260, 900, 650, 900, 1400, 900],
    'downRight': [260, 900, 650, 900, 1400, 900],
    'upLeft': [260, 900, 650, 900, 1400, 900],
    'downLeft': [260, 900, 650, 900, 1400, 900],
  },
  'Same Angle 2': {
    'upRight': [30, 1280, 195, 1280, 340, 1280],
    'downRight': [30, 550, 200, 550, 340, 550],
    'upLeft': [30, 1200, 195, 1200, 340, 1200],
    'downLeft': [60, 600, 200, 600, 340, 600],
  },
  '90 → Match Bend 2': {
    'upRight': [35, 1220, 185,1220, 310, 1220],
    'downRight': [35, 520, 185, 520, 325, 520],
    'upLeft': [80, 1200, 230, 1200, 370, 1200],
    'downLeft': [80, 575, 230, 575, 370, 575],
  },
};

// ---------------------------------------------------------------------------
// RACK BUILDER — KICK 90 PREVIEW (STEP 4)
// ---------------------------------------------------------------------------

// Format: [ImageX, ImageY, ScaleX, ScaleY]
const Map<String, Map<String, List<double>>> kickPreviewConfig = {
  'Parallel': {
    'upRight': [-12.0, -10.0, 1.0, 1.0],
    'downRight': [-12.0, -10.0, 1.0, 1.0],
    'upLeft': [-12.0, -10.0, 1.0, 1.0],
    'downLeft': [-12.0, -10.0, 1.0, 1.0],
  },
  'Forward': {
    'upRight': [-12.0, -10.0, 1.0, 1.0],
    // The down-right photograph has a wider source canvas than up-right.
    // Keep the scale uniform and bias it right so the visible rack is centered.
    'downRight': [-3.0, -10.0, 1.17, 1.17],
    'upLeft': [-12.0, -10.0, 1.0, 1.0],
    'downLeft': [-12.0, -10.0, 1.0, 1.0],
  },
  'Same Angle': {
    'upRight': [-0.0, 0.0, 1.00, 1.4],
    'downRight': [-0.0, 0.0, 1.00, 1.4],
    'upLeft': [-0.0, 0.0, 1.00, 1.15],
    'downLeft': [-0.0, 0.0, 1.00, 1.15],
  },
  '90 → Match Bend': {
    // Pull the up-right photograph inside the rounded preview border.
    'upRight': [-4.0, 0.0, .95, .95],
    'downRight': [-12.0, -10.0, 1.0, 1.0],
    'upLeft': [-4.0, 0.0, .95, .95],
    'downLeft': [-12.0, -10.0, 1.0, 1.0],
  },
  'Same Angle 2': {
    'upRight': [-12.0, -10.0, 1.0, 1.2],
    'downRight': [-12.0, -10.0, 1.0, 1.0],
    'upLeft': [-12.0, -10.0, 1.0, 1.2],
    'downLeft': [-12.0, -10.0, .97, 1.2],
  },
  '90 → Match Bend 2': {
    'upRight': [-12.0, -10.0,.97, 1.2],
    'downRight': [-12.0, -10.0, .97, 1.2],
    'upLeft': [-12.0, -10.0, 1.0, 1.15],
    'downLeft': [-12.0, -10.0, 1.0, 1.15],
  },
};
