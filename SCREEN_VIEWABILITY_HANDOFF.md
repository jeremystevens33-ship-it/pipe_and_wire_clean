# Pipe & Wire small-screen handoff — 2026-09-22

## Current direction — 2026-09-23 (supersedes the old test priority below)

User-led Medium Phone walkthroughs replace agent-driven app-wide Small Phone
sweeps. User reports the visited screens are usable, scrollable and generally
look good; app completion is now the priority. Motorola is still the accepted
baseline. Small Phone stress checks and Mac/iOS setup are deferred.

Existing AVDs inspected: Small Phone, Medium Phone API 36.0, Pixel 9 Pro.
Small Phone ran the app at measured 720 × 1280, 320 dpi, font scale 1.0
(360 × 640 logical). Medium Phone profile is 1080 × 2400 at 420 dpi
(approximately 411 × 914 logical); runtime Flutter safe areas, text scale and
keyboard insets have not been measured there. Do not infer them from screenshots.

User screenshots/reports, 2026-09-22–23:
- Rack Builder results/picture/marks and scrolling usable; title ellipsized.
- Pipe and Box Fill main screen usable, narrow margins/crowded Ambient Temp label.
- Pipe Dashboard circle slightly clipped at both sides: optional local width fix.
- Triangle calculator diagram and keypad fit in the shown state.
- Back-to-Back results picture, marks and banners fit; numeric/name keypads usable,
  but Android gesture bar overlaps bottom keys in the screenshots.
- Other visited screens reported generally good, unnamed: no individual full-pass claims.

No app code or formulas changed during this walkthrough. The two latest navigation
changes were source-confirmed, but explicit user confirmation remains open in A1
of RACK_BUILDER_TODO.md. Back-to-Back custom CLR uses the same gain helper as Kick;
pipe size must be selected before gain entry (unselected in the supplied photos).

Use RACK_BUILDER_TODO.md for the active queue. The original procedure below is
retained as reference, not an instruction to resume an exhaustive automated tour.


## Goal and baseline

Verify the whole app on shorter and narrower phones, not only Rack Builder on
one tall Motorola. The user's Motorola Stylus currently looks good; use it as
an accepted baseline and regression comparison, not the primary stress device.
The user measured visible screen height at roughly 6½ inches on the Motorola
and 5⅞ inches on an iPhone 17 Pro. These are physical-height observations, not
logical viewport measurements or diagonal specifications.

Flutter layout depends on logical width/height, display density, text scale,
safe-area insets and keyboard space. Do not pick a test device solely because
it is described as a six-inch phone. Resizing the emulator's desktop window
only changes viewing scale, not necessarily the app's layout constraints.

Scope includes standalone calculators and other app screens with fixed sizes,
Positioned widgets and placement constants. Preserve formulas, results, accepted
pictures and selector-dot alignment. Fix actual clipping/overlap/reachability,
not the app's design. Do not blindly shrink text or scale the entire screen.

## Step 1 — establish compact test devices

- [ ] Inspect existing Android Studio Device Manager AVDs before creating more.
- [ ] Select/create a shorter portrait phone and record actual Flutter logical
  dimensions, safe-area padding, text scale and keyboard/view insets.
- [ ] Use approximately 360 × 640 logical pixels as the first compact target;
  add 320 × 568 as a smaller stress target if practical. These are test viewport
  targets, NOT claimed dimensions of the user's iPhone. Record achieved sizes
  if the chosen AVD differs. Also cover a modern medium-height phone.
- [ ] Run the actual Flutter app in the Android emulator. Static previews can
  help inspect individual layouts but do not establish keyboard/navigation behavior.
- [ ] Start with normal system text/display size, then repeat affected screens
  with larger text (about 1.3×, or the nearest available setting).
- [ ] Android approximations do not certify iPhone behavior. Keep a separate
  iOS check on an actual device or iOS Simulator on macOS for cutouts, safe areas,
  keyboard and navigation. Android Studio on Windows is the Android test route.

Android Studio: View → Tool Windows → Device Manager → + → Create Virtual Device.
Prefer an existing suitable system image; do not install a fleet of emulators.

## Step 2 — inventory, then walk screens in this order

Use the current main menu to confirm reachable screens; do not assume this list
covers every route. Record each screen's states in the table below.

1. Home/main menu and navigation/help overlays.
2. Standalone bend calculators first: offsets/rolling offsets, Kick 90,
   back-to-back 90, three-/four-bend saddles, segmented 90/radius tools.
   These may have more rigid picture/mark positioning than Rack Builder.
3. Rack Builder: setup, bender picker, Starting Point, Next Bend, standard/rolling
   offsets, Kick types/measurements, results, Hub, saved results and support dialogs.
4. Box layout, pipe/box fill, feet-inch-fraction and triangle calculators,
   load/power tools, angle finder, reference/code screens reachable from the menu.

## Step 3 — repeat the same short check on each screen

- [ ] Fresh inputs and a completed example; long fractional values and labels.
- [ ] Every input with the custom or system keyboard open and then dismissed.
- [ ] Expanded/collapsed cards, warnings, pickers, menus and dialogs.
- [ ] Results: full picture visible where intended; marks/dots stay aligned;
  instructions and Continue/Back/Next remain readable and reachable.
- [ ] Scroll to both ends. No horizontal overflow, clipped titles, inaccessible
  controls or content hidden under fixed bars or the keyboard.
- [ ] Where a bottom info bar is intended to stay fixed, keep the main content
  independently scrollable above it. Allow the bar's text to wrap; on very short
  viewports choose a bounded readable solution rather than covering all content.
- [ ] Test landscape only where supported; do not enable new orientations casually.

Scrolling on a short phone is acceptable. Fitting every result on one screen
is not required if it makes text, diagrams or tap targets too small.

## Step 4 — log, fix, verify one problem at a time

| Screen/state | Device + logical size | Text/keyboard state | Actual problem | Fix | Compact recheck | Motorola recheck |
|---|---|---|---|---|---|---|
| Hub straight entry | Prior widget viewport 600 wide | Needs reproduction | 8.3-pixel horizontal overflow reported by a test, not observed by user | Pending | Pending | No issue reported |

Capture a screenshot and reproduction steps only for failures; mark passing
screens once. Inspect layout constraints before touching constants. Prefer
responsive widths, wrapping and correct scroll/safe-area structure. Preserve
picture aspect ratios and normalized overlay positions where possible.

After a fix, recheck the failing screen on compact size and Motorola baseline.
Broaden checks only if a shared widget changed. User phone/emulator walkthroughs
are the default for cosmetic edits: no automated test suite after every spacing
or color change. Reserve focused tests for changed behavior or persistent layout
regressions; do not rerun the 21 already-passing support tests for screen polish.

Accepted Next Bend scroll: 650ms easeInOut, alignment 0.04 minus 15 logical pixels
converted to viewport alignment. Preserve its Motorola position; adjust only
if another viewport exposes a concrete clipping issue. User accepted Starting
Point returning to its original populated form, not a separate summary card.
Final navigation follow-up: Continue from Rack Setup results to Bender no longer
animates to a fixed 140-pixel offset. Skip Starting Point now uses the same
Next Bend transition/heading scroll as completing Starting Point, replacing
its old fixed 200-pixel scroll. These last two changes await user phone confirmation.

## Step 5 — completion

- [ ] Reachable screen inventory checked on compact portrait with keyboard states.
- [ ] Larger-text pass and supported-landscape pass complete.
- [ ] Shared-widget fixes spot-checked on the tall Motorola baseline.
- [ ] Known failures fixed or explicitly recorded; do not call untested screens passed.
- [ ] Separate real iOS verification and functional/physical release checks remain
  visible if they have not been completed. Do not equate Android layout checks
  with store readiness.

## Reference documentation

- Android virtual devices: https://developer.android.com/studio/run/managing-avds
- Flutter adaptive layout: https://docs.flutter.dev/ui/adaptive-responsive/general

## Functional checks still separate from screen polish

- Confirm no duplicate stages after Next Bend/Back/Latest Results, including
  starting-point and standalone calculator handoffs.
- Explicitly exercise support-edit Cancel and Move downstream; deletion is a
  different action. Confirm removed corner-support dimensions disappear.
- Phone-check stage resize/removal choices now implemented: Cancel, Keep
  locations, Shift downstream. Shift removes supports in the removed portion
  and translates later supports. Future supports remain visible/editable beyond
  conduit; suggested gap is 120 inches and is editable. Support stations for 90s
  now use before/after distances rather than gain-adjusted cut length.
  21 focused support/sequence/entry tests passed on 2026-09-22; do not rerun
  this suite for cosmetic screen adjustments.
- Material-count fix passed focused tests; manually spot-check a known rack.
  Counts assume separate stage pieces, no offcut reuse, and older snapshots
  without per-pipe cuts fall back to stage length.
- Before release: MAX STUB zero-overage check, clearance coverage for all pipes,
  physical Forward Kick progression and four-bend Saddle notch placement when
  conduit is available. Do not change formulas speculatively.

Read RACK_BUILDER_TODO.md for detailed status and CONSTRUCTION_HUB_HANDOFF.md
for implementation history. Leave existing duplicate stages for user review.

