# Pipe & Wire — general to-do

Active Android/iPhone layout work: [COMPATIBILITY_TODO.md](COMPATIBILITY_TODO.md).
As of 2026-09-29, the user has the app running on a physical iPhone from the Mac;
older Mac/iOS deferral notes below are historical.

Updated 2026-09-23. General app tasks belong here; future feature ideas belong in
[FUTURE.md](FUTURE.md). Existing Rack Builder checks and other-screen finish chunks
remain in [RACK_BUILDER_TODO.md](RACK_BUILDER_TODO.md); do not duplicate their status.

## Active finish checklist — 2026-10-06

Smaller-phone/iPhone viewability stays with the user's Mac walkthroughs under
COMPATIBILITY_TODO.md. Use one shared Flutter layout that responds to available
width/height; do not create separate iOS/Android copies of these screens.
Preserve the accepted Motorola baseline and review incoming Mac changes before
merging. The following is the current non-layout priority order.

1. [ ] **Load Calculator** — `lib/load_calculator2.dart` (first).
   - Proposed expansion and delivery order: [LOAD_CALCULATOR_PLAN.md](LOAD_CALCULATOR_PLAN.md).
   - First-release target: Quick Circuit + a saved room/lighting panel schedule,
     with named circuits and visible phase totals. Full building/service demand
     methods and specialized automatic equipment sizing are later work.
   - [x] Remove the development number from the visible Load Calculator title.
   - [x] Initial source inventory: circuit capacity, repeating-unit maximum,
     entered watts/amps and quantity, continuous/noncontinuous capacity toggle.
   - [x] Reuse the existing decimal keypad for load inputs; link watts/amps using
     the last entered basis, voltage and explicit power factor. Preserve full
     precision for totals and maximum-unit calculations. Focused numerical checks
     passed; phone keypad walkthrough remains with the user.
   - [x] Make mode guidance selection-specific and withhold repeating-load results
     for the unfinished Mixed Load and Service Check selections.
   - [x] Make the entered load unambiguous: the last entered watts or amps drives
     consistent conversion. Validate keypad confirmation, require whole positive
     quantities and power factor above 0 through 1; zero load has no unit maximum.
   - [ ] Finish and verify Basic Circuit + Repeating Load: unit current, actual
     connected total, remaining capacity, maximum whole units and overload state.
   - [x] Implement Basic Circuit + Mixed Load: named entries, quantities, individual
     continuous settings, optional power factor, Add/Edit/Remove, actual totals,
     sizing allowance and remaining capacity. Edit replaces the selected entry.
     Independent numerical checks and focused workflow test pass. Manual phone
     acceptance remains pending; circuit/project saving is a separate next chunk.
   - [ ] Service Check remains visibly deferred. Do not imply an Article 220
     service calculation from a basic circuit preview.
   - [ ] Align instructions/results with the reviewed continuous-load code page;
     mixed calculation now uses 125% continuous plus 100% noncontinuous for
     ordinary branch circuits. Equipment-specific rules remain outside this path.
   - [ ] User walkthrough of one accepted example; focused numerical checks for
     calculation changes only. Cosmetic acceptance remains manual.
2. [ ] **Power Hub Solver** — `lib/power_equations_solver.dart`,
   `lib/power_formulas.dart`.
   - [ ] Verify a complete single-phase and three-phase equation path, input
     units, required inputs, invalid/unsolvable states, and result labels.
   - [ ] Audit motor current basis, conductor/overload/protection calculations,
     motor-type distinctions, standard-rating selection and displayed references
     against the revised 2023 motor Code page. Do not assume code-copy edits
     already corrected the calculator implementation.
   - [ ] Fix only established findings, with independent worked examples for
     numerical changes; user checks the completed flow.
3. [ ] **Digital Reference Hub** — `lib/reference_hub.dart`.
   - [ ] Review its seven existing tabs: Bending, Color Codes, Pipe O.D.,
     Breakers/Ground, Box Fill, Support, and Decimals.
   - [ ] Check table values, units, explanatory limits and references against
     shared data/current reviewed Code content. Distinguish trade conventions
     from mandated phase identification. Preserve accepted bending formulas.
   - [ ] Correct specific findings; user checks category/chart swipes and return
     navigation. No broad redesign or whole-app automated screen tour.
4. [ ] **Website / YouTube buttons** — connect once exact destinations are supplied.
5. [ ] **Closeout reviews** — Code phone review and recorded source rechecks;
   retain specific Rack Builder/physical verification items in its existing list.

Angle Finder/Level: user reports it works on Android and iPhone. Occasional
startup movement remains an observation to monitor, not a current rewrite task.
Code content sweep is implemented; CODE_CONTENT_TODO.md records its remaining
manual acceptance and source checks. No store-readiness claim is implied.

## Website and YouTube button details

- [ ] Obtain the exact website URL and YouTube channel/page URL from the user.
  The recalled website name is not a confirmed destination.
- [ ] Connect the existing YouTube icon and WEB button in the main menu footer
  (`lib/main_menu_screen.dart`). Both currently have empty onTap callbacks.
- [ ] Open the intended destinations through the platform's supported URL handler;
  handle launch failure with a readable message and preserve app state on return.
- [ ] Manually verify both buttons and return-to-app behavior on Android;
  include iOS verification when that build environment is available.

Done when both existing buttons open the user-supplied destinations successfully.
The adjacent UPLOAD button is also a placeholder, but its behavior is unspecified
and is not part of this link-wiring task. Do not invent an upload destination.

## Existing app completion work

- Code reference: [CODE_CONTENT_TODO.md](CODE_CONTENT_TODO.md) tracks the page-by-page
  question-and-answer review. First-release content sweep is implemented through
  Grounding, Loads, Voltage Drop and Motors; phone acceptance and recorded source
  rechecks remain. User performs screen walkthroughs.

- Rack Builder: navigation/commit-once, Starting Point/imports, support choices,
  materials/MAX STUB checks and bender-clearance work — active checklist A1–A5.
- Load Calculator, Power Hub Solver, Code pages and Digital Reference Hub —
  active checklist B1–B4; remaining calculator walkthroughs in B5.
- Optional circle/keypad polish and later physical/iOS/release checks — active
  checklist C–D. User drives testing; investigate specific reported problems.

## Later planning

Paid new-feature packs and user-update communication are recorded in FUTURE.md.
Mac upgrade/setup remains deferred. No app or website publishing is authorized
by these planning entries.
