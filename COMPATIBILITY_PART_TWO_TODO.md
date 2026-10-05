# COMPATIBILITY PART TWO TODO (Agent Handoff Briefing)

**Project Name**: `pipe_and_wire_clean`  
**Platform**: Flutter (Dart 3.13.4, Flutter 3.47.5, iOS 18 / iPhone 17 Pro Focus)  
**GitHub Repository**: `https://github.com/jeremystevens33-ship-it/pipe_and_wire_clean.git` (`master` branch)  

---

## 1. Core Engineering Philosophy & UI Standards
Our **#1 priority** across every screen in this app is **100% responsive viewability on physical iPhone and Android screens** without vertical overflow errors or awkward cutoffs.

### Established Design Rules:
1. **Zero Vertical Overflow**: Wrap main scaffold bodies in `SafeArea` + `SingleChildScrollView` with controlled vertical height constraints (`SizedBox` / `FittedBox`).
2. **Keypad & Screen Space Compression**: Automatically collapse/hide the numeric keypad when users are on selection steps (like Pipe Sizes) to reclaim ~200px of vertical screen height.
3. **Single-Line Text Enforcement**: Use `FittedBox(fit: BoxFit.scaleDown)` and `maxLines: 1` on measurement labels so numbers like `10 11/16"` scale down font size slightly rather than wrapping onto 2 lines.
4. **Hanging-Indent Bullet Lists**: Format info bar bullet points with `Row` + `Expanded` so wrapped second lines indent directly under the text of line 1 (to the right of the bullet point `•`).
5. **Unified Keypad & Operator Bar**:
   * Layout: **`✓` | `MR` | Blank | Blank | `C` | `←`**
   * **`✓`**: Green (`0xFF3AAE75`) when ready, Amber/Orange (`0xFFE0A72E`) when a warning is active, Dark Gray when incomplete.
   * **`MR`**: Cycles through persistent Memory Recall history (up to 5 items).
   * **`C`**: Clears only the active input field for the current step (does NOT reset the whole tool).
   * **`🔄 Reset` (in App Bar)**: Resets active fields back to Step 1 while preserving `MR` history.

---

## 2. Status of Completed Modules

### A. Home Screen (`lib/home_screen.dart`)
* Title text coordinates (`kPipeLeftFrac = 0.23`, `kPipeTopFrac = 0.23`, `kAmpLeftFrac = 0.47`, `kAmpTopFrac = 0.41`, `kWireLeftFrac = 0.56`, `kWireTopFrac = 0.47`) are anchored directly inside the `pw_pipes.png` coordinate stack for 100% cross-platform layout fidelity on iPhone and Android.

### B. Triangle Calculator (`lib/triangle_calculator.dart`)
* Taller diagram height clamping (`(maxHeight - calculatorHeight - 22).clamp(145.0, 240.0)`).
* Right-aligned digits in `HYP` and `OPP` fields sitting directly under letter `P`.
* Operator Bar: `✓` | `MR` | Blank | Blank | `C` | `←`.
* Persistent 5-item Memory Recall (`MR`) with green border highlight when viewing history.

### C. Box Layout Mode (`lib/box_layout_mode.dart`)
* **Enlarged Pipe Circles**: `46px` circles, `16px` bold inner trade size text, and `14.5px` single-line top/bottom measurement labels.
* **Auto-Scrolling**: `_pipeScrollController` smoothly scrolls the horizontal pipe list whenever `_activePipeIndex` moves past 5 pipes. Auto-scrolls back to `P1` on step completion.
* **1/2" Clearance Threshold (`0.5"`)**:
  * 0.5" or greater = **Sleek Black Total Box** & **Bright Green Checkmark `✓`**.
  * Less than 0.5" = **Amber/Orange Total Box**, **Amber Checkmark `✓`**, and warning prompt:
    * Top Line: `Tight clearance (< 1/2")`
    * Bottom Line: `Increase box size, or tap ✓ to proceed`
* **Live Typing in Warning Prompt**: As the user types digits on the keypad (e.g., `8`), the bottom line displays `Increase box size: 8" (tap ✓)` live. When clearance reaches ≥ 0.5", the warning vanishes automatically and the checkmark turns bright green!
* **Memory Recall (`MR`)**: Stores up to 5 box layouts automatically upon completion. Tapping **`MR`** turns the outer border **bright green (`0xFF3AAE75`)** and displays **`VIEWING MR 1`** in bold green text. Tapping **`Reset (🔄)`** returns the border to **sleek red** and clears `_mrBadge`.
* **5-Bulleted Outside Info Bar**: Positioned at the very bottom outside the red border container with hanging indents:
  1. `• Scroll left to see all pipes.`
  2. `• Measure from left edge of box to mark all pipe centers.`
  3. `• Measure from strut face or wall to pipe center for depth.`
  4. `• Edge-to-Edge: 19 7/16" (2" space)  |  STORED IN MR 1` *(or `VIEWING MR 1` in bold green)*
  5. `• TO THE RACK transfers these pipes & spacing to Rack Builder.`
* **Help Guide (`info` button)**:
  * Overview: *"This tool precisely calculates pipe spacing across a junction box."*
  * Measurements: *"Once you complete entering your conduits and box size, calculations will display for both top and bottom rows..."*
  * Pro Tips: *"You can start with a known box dimension, or determine the required box size based on the overall pipe edge-to-edge distance, including spacing."*

---

## 3. Immediate Next Focus: Pipe & Box Fill Calculator (`lib/pipe_and_box_fill.dart`)

### Action Plan for `lib/pipe_and_box_fill.dart`:
1. **Audit Screen Layout & Vertical Height**: Ensure `lib/pipe_and_box_fill.dart` uses `SafeArea` + `SingleChildScrollView` with tight padding so no bottom borders or action buttons overflow on iPhone 17 Pro / Android screens.
2. **Apply Typography & Compression Standards**:
   * Ensure text labels, dropdowns, and results cards use single-line `FittedBox` scaling where needed.
   * Verify that result tables, wire count lists, and conduit fill percentage badges fit comfortably without truncation or overflow.
3. **Verify Interactive Workflow**:
   * Audit wire size pickers, conduit type selectors (`EMT`, `RMC`, `PVC`), and box volume fill calculations.
   * Ensure all buttons, clear/reset options, and help dialogs follow the established UI/UX patterns.
