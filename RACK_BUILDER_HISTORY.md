# Historical checklist — archived 2026-09-23

Use RACK_BUILDER_TODO.md for current priorities and status. The original checklist follows unchanged; older open boxes may be superseded by later entries. Preserve these technical examples and acceptance notes.

# Pipe & Wire Working Checklist

This is the shared working list for finishing Rack Builder and preparing the
rest of Pipe & Wire for release. Update it as items are tested or completed.
Do not change field-tested bending formulas merely to clean up or reorganize
code. Rack Builder remains the current priority.

## Current next step — screen viewability (2026-09-22)

The user accepted the Starting Point form navigation, info bar, custom straight
entry, and final Next Bend scroll position. Continue with SCREEN_VIEWABILITY_HANDOFF.md.
Do not reopen accepted pictures, selector dots, or formulas during screen work.
Unchecked functional and physical checks below remain outstanding; moving to
screen testing is not a claim that release verification is complete.

### 1. Check when a finished bend is added to the Hub

- [x] New Hub stages append to the end (2026-09-21). Expanding an earlier
  stage no longer sets an insertion point for straight pipes, pull points, or bends.
  Focused widget test covers adding a pull point and straight after expanding Stage 1.
- [x] New Kick 90 opens Kick Type expanded before measurements (2026-09-21).

This is what the old phrase "audit Hub commit timing" meant: does the bend get
added when results appear, or only when you press Next Bend? It should behave
predictably and never add the same result twice by accident.

- [x] Kick 90 now saves to Hub when Calculate opens results (2026-09-21),
  matching Parallel 90 and Offset. Previously it waited for Next Bend.
  The existing commit guard prevents Next Bend from saving it again.
- [x] Kick 90 immediate Hub-save change accepted by user (2026-09-21).
  Accepted without another on-device walkthrough; duplicate-commit test passed.
- [ ] Press Next Bend and check that it did not add a duplicate stage.
- [ ] Go Back, then Latest Results. Check that the stage still appears only once.
- [x] Parallel 90 timing confirmed by user (2026-09-21): enters Hub at Results,
  including a fresh rack after skipping Starting Point.
- [x] First Parallel 90 supports verified after skipping Starting Point
  (2026-09-21). User expanded Stage 1 and confirmed the supports were already
  present; the collapsed card hid them. No support-placement fix needed.
  Inputs: 66 to back of 90, MAX PIPE 41 3/16 after. State regression also confirms
  supports at 42 and 90 from run start, including after reset.
- [x] Standard Offset Hub timing accepted by user (2026-09-21).
- [x] Rolling Offset enters Hub at results, confirmed on-device (2026-09-21).
- [ ] Confirm Next Bend does not add the Rolling Offset again.
- [ ] Check a bend sent into Rack Builder from a standalone calculator.
- [ ] If the timing differs, agree on one behavior and fix only that difference.

### 2. Finish the remaining Hub checks

Do these individually; the current support display does not need another redesign.

- [x] Reopen earlier stages' View Results and switch between pipes; confirmed
  by user, including saved overall/cut lengths (2026-09-21).
- [x] Reviewing an old stage leaves the current bend unchanged; user returned
  and confirmed it was intact (2026-09-21).
- [x] Clear the support editor/keypad when removing a support, and hide the
  keypad when dismissing Hub by tapping outside or swiping (2026-09-21).
- [ ] Try Cancel and Move downstream when editing a support.
- [ ] Remove a support and confirm its diagram measurement disappears.
- [x] Stage resize/removal offers Cancel, Keep locations, or Shift downstream
  (2026-09-22). Shift removes supports inside the removed portion and moves later
  supports by the length change; dialog explains counts. Phone check pending.
- [x] Planned supports beyond conduit stay visible/editable; Add Support suggests
  120 inches from the previous support, editable to any positive distance.
  Straight suggestions retain 36/84 inches then 120-inch gaps. Stage references
  are displayed alongside support gaps. 90 support stations use before/after
  geometry, not gain-adjusted cut length. 21 focused tests passed (2026-09-22).

### Starting Point — separate walkthrough

- [x] Preserve Starting Point as card 3 after adding it (2026-09-22).
  Title reopens the original Starting Point form with retained input boxes,
  not a separate saved-summary card; review cannot append another Initial Run
  or box-transition 90. Existing duplicate stages are preserved for user review.
  Subsequent cards number around it, and Next Bend scroll leaves a top margin.
  User accepted original-form navigation and the final scroll position on phone.
  No automated tests run for this follow-up.
- [x] Starting Point edits implemented (2026-09-22): require an explicit
  spacing choice before advancing; warn on a box-transition 90 cut over 120
  with Go Back / Continue Anyway; save to Hub at results; hide its misleading
  parallel-90 picture in live and saved results. Kick This 90 remains available.
  Existing standalone handoff spacing choices remain accepted. No bending
  formulas changed. Code/whitespace review only; user will verify on phone.
- [ ] Start with an actual starting-point/box-transition 90; check Hub entry,
  support references, and that Next Bend does not duplicate it.

### 3. Review measurements and totals before relying on them

These are correctness checks, not visual polish. Assess each before calling the
app ready for testing; do not assume all are already verified.

- [ ] Confirm MAX STUB no longer reports an overage of zero inches.
- [ ] Physically check the updated Forward Kick progression when conduit is available.
- [ ] Review the bender-clearance warning and which Rack Builder pipes it checks.
- [x] Fix stock/coupling totals (2026-09-21): use saved per-pipe cuts, count
  joins between separately cut stages, and reset every path at one Pull Box.
  Two focused tests passed. Stock counts do not assume offcut reuse or multiple
  saved bends on a single stick; older stages without snapshots use stage length.
- [x] Hub Pull Point angle reset verified on-device (2026-09-21): adding a
  Pull Box reset displayed Degrees to 0; adding a subsequent 90 showed 90°.
  Per-conduit material paths now also reset at the Pull Box.

### 4. App-wide smaller-screen testing

Follow SCREEN_VIEWABILITY_HANDOFF.md step by step. Motorola is the accepted
tall-screen baseline; prioritize shorter/narrower emulator viewports, then
compare fixes on Motorola. Cover standalone calculators and remaining menu
screens as well as Rack Builder. Physical screen inches alone are not a layout
target. Verify keyboard states, fixed info bars, scrolling, safe areas and larger
text. Keep real iOS verification separate from Android approximations.

- [ ] Check narrow Hub straight-adder layout: stage-order widget test exposed
  an 8.3-pixel horizontal overflow at 600 logical pixels; ordering passed at 800.

- [ ] Check Back, Continue, Next Bend, and Latest Results.
- [ ] Check scrolling, keypads, and bottom instruction bars on the Motorola.
- [ ] Repeat on the Pixel emulator and record only remaining problems.
- [ ] Fix confirmed problems, then close Rack Builder's current work list.

### 5. Move on to the rest of the app and testing preparation

- [x] Saddle photographs supplied, connected, and visually accepted (2026-09-21).
- [ ] Verify four-bend Saddle placement with Notch when more pipe is available;
  see the Saddle notes below. Saddle work is otherwise paused for now.
- [ ] Review the remaining app sections below and agree on the initial release scope.
- [ ] Make a separate testing/submission checklist for the chosen app stores.

### Later improvements — not automatically required for the first release

Editing historical bends, planning multiple bends on one stick, extra dashboard
metrics, asset renaming, and large code reorganizations are separate future work.
Do not expand the release scope just because those ideas appear farther down.

## Completed work and detailed reference notes

### Hub walkthrough follow-up (confirmed 2026-09-15)

Support-origin fix (2026-09-13): first Add Support no longer unconditionally
creates "Vertical (from Box)". A first Kick after skipping Starting Point uses
"Support (from Run Start)"; real box-transition stages retain box references.
Existing erroneous automatic box labels also render as run-start references.
The reported 42 inches can be a valid remaining stage distance (78-inch stage
minus support at 36), not a fixed Starting Point value. The September 15 follow-up
also enabled Kick corner support suggestions and fixed explicit support entry.
User accepted the current Hub walkthrough; bending formulas were unchanged.

- [x] Investigate/fix skipped-Starting-Point support references: first Kick uses
  its saved run origin; support rows and edits no longer assume a box start.
- [x] Trace "Pipe beyond last support": calculated from stage end minus last
  support position (for example, 78 - 36 = 42), not a fixed Starting Point value.
- [x] Phone-check skipped Starting Point → Kick results → Hub → Add Support:
  user verified run-start references, adding supports, and remaining pipe values.
- [x] Restyle Hub View Results (2026-09-15): reuse the app's gray beveled button
  with white icon/text instead of the purple theme-default outlined button.
  Saved-review action unchanged; user accepted compact left-aligned styling.
  Back to Hub now uses white text and a neutral border as well.
- Remaining question: when does each finished bend enter the Hub? Follow Step 1
  above instead of treating this as a separate task.

Pictures and selector dots are complete. The numbered plan above identifies the
remaining checks; the entries below preserve the implementation history.

- [x] Remove the legacy Across-Kick shorter-side measurement branch and keep
  Mark A tied to the entered stub.
- [x] Add automated MAX STUB coverage for every Kick style with three and six
  pipes.
- [x] On the phone, check one Across case where Stub Height is longer than Leg
  Length and confirm the display still reads from the stub end in A, B, C order.
- [x] On the phone, check one representative overlength Kick, use MAX STUB, and
  confirm the warning, adjusted Stub Height, and 120-inch longest cut shown.
- [x] Finish Standard/Rolling Offset Pipe 1 parity and implement the
  standalone-to-Rack-Builder handoff for geometry, Toward/Past, bender,
  bending method, and Forward/Reverse orientation.
- [x] Walk through Rolling Offset once, including direction and bending method.
- [x] Graduate Parallel Rolling Offset A/B marks for Left and Right rack
  progression while preserving the standalone Pipe 1 result and cut length.
- [ ] Complete the dedicated Construction Hub work listed below.
- [ ] Complete one final Rack Builder navigation/scrolling pass on the Pixel
  emulator and Motorola phone.
- [x] Resolve the reported Results/measurements/Latest Results navigation concern;
  user confirmed that flow and Next Bend during the Hub walkthrough.
- [x] Finish and connect all 24 Kick style/direction photographs; user confirmed.
- [x] Finish Kick image alignment and selector-dot tuning; user confirmed all
  Rack Builder bend pictures and dots complete on 2026-09-13.

## Current verification

- [x] Kick Hub corner layout (2026-09-15): recognize a Kick's 90 corner despite
  its total angle exceeding 90 degrees. Save both before/after-90 distances and
  direction; reuse corner support suggestions, arrows, and support-edit offsets.
  Display "Distance from Back of 90" above the diagram and "Distance to Back
  of 90" below, followed by the stage-length/remaining-pipe row.
  Empty stages say "Stage length (no supports)" instead of claiming a last support.
  Add Support scrolls to its rendered card rather than past the scroll extent.
  Older Kick stages recover the missing after-90 value from their saved data.
  Existing authored support layouts remain preserved; user accepted the current
  display, support entry, and scroll behavior on 2026-09-15.

- [x] Fix Hub Next Support entry (2026-09-15): opening the panel no longer
  pre-adds a 120-inch support beyond the stage. Add and keypad confirmation use
  the same save path, measuring the entered gap from the last committed support.
  Removed the duplicate inch suffix and clarified the input reference.
  Existing supports are preserved; any previously created unintended supports
  must be reviewed rather than automatically deleted.

- [x] Forward progression unified (2026-09-15): user authorized inside-to-outside
  numbering for every direction. The shared bending_data.dart helper now adds
  spacing × tan(angle/2); removed the Up Left-only sign override. A, C and angle
  stay unchanged. Geometry regression checks perpendicular center spacing.
  All 26 focused Kick, saved-result and handoff tests pass.
- [x] Forward Up Left P1/P3 relabeling: reversed rack-strip identities and photo
  identity mapping together, preserving circle-to-photo-dot positions. P1 now
  identifies the top conduit and receives the smallest Mark B, like Up Right.
- [x] User checked all four Forward configurations on screen (2026-09-15):
  dots select the intended pipes and Mark B grows from inside to outside.
  Recorded the old subtraction/new addition and removed direction exception
  in bending_data.dart's Forward Mark B description.
- [ ] Physically bend and verify the updated Forward progression; on-screen
  confirmation and geometry regression tests do not replace a field check.

- [x] Fix Kick MAX STUB field rounding: floor the optimized stub to a fitting
  sixteenth instead of rounding it up past 120 inches. Small genuine overages
  now say "less than 1/16 inch" rather than displaying zero. Actual MAX STUB
  button tests cover three marking methods and both spacing modes; all 19
  selected tests pass (2026-09-13). Bending formulas are unchanged.
- [ ] Phone-check the reported "Pipe 3 exceeds by 0" case after this fix.
  Later geometry/bender/spacing changes may require pressing MAX STUB again;
  it is an action on the current inputs, not a persistent full-stick lock.

- [x] Remove the legacy Across-Kick "shorter side" branch in `rack_state.dart`.
- [x] Complete a representative six-pipe Across MAX STUB and 10-foot-warning
  test on the phone while laying out the physical Kick photographs.
- [x] Test MAX STUB on all six Kick styles with three and six pipes.
- [ ] Confirm Continue Anyway preserves the entered Stub Height and Leg Length.
- [ ] Confirm the warning names the correct longest pipe and overflow.
- [ ] Confirm smaller screens can scroll the entire Step 4 card and instruction bar.

## Construction Hub

The detailed context and safe continuation plan live in
`CONSTRUCTION_HUB_HANDOFF.md`. Keep this checklist as the master status record.

### Completed and verified

- [x] Audit the Hub sequence, accordion details, edit/remove paths, support
  behavior, degree tracking, and material-summary logic.
- [x] Preserve all existing segment metadata when a segment length or label is
  edited.
- [x] Preserve an existing support label when its position is edited.
- [x] Clear saved support labels when Clear Hub removes the run.
- [x] Continuously total bend degrees since the most recent pull point.
- [x] Allow exactly 360 degrees and show the exceeded warning only above 360.
- [x] Rename `Pipe Footage` to `Stock Footage` because it represents purchased
  10-foot sticks rather than installed conduit length.
- [x] Add focused Construction Hub state tests and rerun the existing Kick and
  Offset regression suites; all 58 selected tests passed.

### Next safe Hub pass

- [x] Stabilize expanded-card, selected-stage, and editing indices when a stage
  is inserted or removed.
- [x] Replace the broad geometry-based duplicate guard with explicit commit
  identity so two intentionally identical consecutive bends are allowed while
  a double-tap is still rejected.
- [x] Make bend insertion honor the selected Hub stage consistently, as Straight
  and Pull Point insertion already attempt to do.
- [ ] Decide and test whether downstream support locations move with an edited
  stage or remain fixed field locations before changing recalculation behavior.
- [ ] Perform an on-device Hub sequence walkthrough after these state changes.

Sequence identity pass: all 60 selected Hub, Kick, Offset parity, and Offset
formula tests passed. Stage IDs survive edits; removed selections resolve to no
selection, so insertion falls back to the end. Device walkthrough remains pending.

### Support clarity and starting-point follow-up (2026-09-07)

- [x] User verified the MAX PIPE fix, first-stage arrows, and live support/
  overhang changes on-device.
- [x] Rename Pipe past Support to Pipe beyond last support; clarify previous
  support references while retaining last coupling wording as requested.
- [x] Display saved stub and leg in their entered roles, without sorting by size
  or displaying invented zero values when a stage has no stored measurement.
- [x] Add Cancel / Just this support / Move downstream confirmation to support
  edits. Downstream moves apply the same signed displacement to later supports;
  conduit geometry stays unchanged. Preserve authored positions when adding stages.
- [x] Restore the latest starting-point 90 input panel on Back, and allow Back
  to undo skipping Starting Point while the run is empty.
- [x] Verify 72 selected Hub and bend regression tests; static analysis has no
  errors, with existing warnings/lints remaining.
- [x] User verified the support edit warning, entered stub labels, and
  Results → measurements → Latest Results / Next Bend navigation.
- [ ] Explicitly exercise both support movement choices and Cancel; also check
  starting-point labels with a longer stub. These combinations are not yet confirmed.
- [ ] Define support behavior when a conduit stage itself is resized or removed;
  this is separate from the explicit support movement choice.

### Bend review and materials after the safety pass

- [x] Store a read-only result snapshot for each saved bend, including its bend
  type, inputs, bender/method choices, direction, and per-pipe marks.
- [x] Add `View Results` for any saved bend before allowing completed bends to be
  edited.
- [ ] Design Save/Cancel and downstream recalculation rules before adding
  `Edit Bend`.
- [x] Store exact per-pipe cuts in saved bend snapshots attached to Hub stages.
- [x] Material counts use saved per-pipe cuts (2026-09-21).
- [x] Pull Point resets every active conduit path and counts one physical box
  (2026-09-21).
- [ ] Decide whether the dashboard should also show installed footage and
  fittings in addition to stock footage, sticks, couplings, run distance, and
  degrees.

### Future conduit-stick planning

- [ ] Explore multiple bends on one conduit stick, including an Offset or Saddle
  followed by a 90.
- [ ] Track cumulative mark positions and consumed length on each physical
  120-inch conduit so the planner can identify when another bend fits before a
  coupling is required.
- [ ] Define minimum straight/end-clearance warnings for a bend located near the
  end of a stick without changing the trusted bend formulas.

## Kick results presentation

Completed and user-approved 2026-09-13: all Rack Builder bend picture cards have
their pictures, alignment, and final selector-dot configurations in place.
All 24 Kick style/direction variants are finished. Preserve the tuned values.

- [x] Officially rename Change Plane "Across" to "Parallel" (2026-09-13):
  update choices, defaults, style comparisons, saved-review title, and all six
  visualization configuration maps. Legacy saved "Across" style names normalize
  to "Parallel" on review. Underlying parallel calculations are unchanged.
  Older audit notes below may still use the former name.

User tuning preference (2026-09-13): keep explicit numeric rows for every
direction in the existing configuration maps. Shared Change Plane Match Bend
aliases were removed at user request; copied values and the 50-pixel downward
dot adjustment remain. Do not consolidate these rows into shared constants.

- [x] Copy completed Change Plane / 90 to Match Bend Up Right tuning to Up Left,
  including the Step 4 preview. Final tuning uses independent numeric rows.
- [x] Finish Down Right/Down Left dot profiles after establishing starting values.
- [x] Change Plane / 90 to Match Bend Up Right top rack now starts with Pipe 1
  on the left. This addresses the presumed top-selector reversal; photograph
  dot identity is unchanged pending clarification if that was the reported issue.
- [x] User confirms final Up Left, Down Right, Down Left, and Up Right picture
  and selector configurations. No bending formulas changed.

- [x] Tune the main image for each available photograph across the six styles and four direction combinations.
- [x] Choose vertical or horizontal selector dots for every style/direction.
- [x] Tune each style's dot coordinates in `bend_visualization_config.dart`.
- [x] Define the finished Kick direction controls as two choices: Kick Up/Down and Turn Left/Right.
- [x] Inventory which of the four direction combinations each existing Kick picture represents: Up+Left, Up+Right, Down+Left, and Down+Right.
- [x] Determine which direction variants can be produced accurately by mirroring and which require separate photographs.
- [x] Use a clearly labeled placeholder and instruction-bar guidance where a direction photograph is still missing.
- [ ] Adopt consistent direction-based asset names before adding more Kick photographs.
- [x] Confirm A/B/C anchors remain readable with long fractional measurements.
- [x] Confirm every Kick result uses the fixed stub-end A, B, C measuring order.
- [x] Support all four visual directions independently rather than forcing one canonical picture to represent every layout.

### Kick picture inventory

An `[x]` means a usable current photograph is available. A possible mirrored
version remains unchecked until it is generated and visually approved.

| Kick style | Up + Right | Down + Right | Up + Left | Down + Left |
| --- | :---: | :---: | :---: | :---: |
| Parallel | [x] | [x] | [x] | [x] |
| Forward | [x] | [x] | [x] | [x] |
| Same Angle (Change Plane) | [x] | [x] | [x] | [x] |
| 90 → Match Bend (Change Plane) | [x] | [x] | [x] | [x] |
| Same Angle 2 (Same Plane) | [x] | [x] | [x] | [x] |
| 90 → Match Bend 2 (Same Plane) | [x] | [x] | [x] | [x] |

- [x] Connect the dedicated Forward Down+Right photograph (`kick_forward_90_2.png`); no mirrored substitute is needed.
- [x] Replace all four 90 → Match Bend 2 pictures with new photographs (2026-09-12).
- [x] Connect Same Angle 2 Up+Left and Down+Left photographs. All 24 Kick
  style/direction combinations now have dedicated assets in the shared map.
- [x] User confirms all Rack Builder Kick pictures are in place (2026-09-12).
  Further image/selector position tuning remains tracked separately above.

## Parallel 90 results

- [x] Reproduce the walkthrough MAX PIPE overflow: 66-inch stub, 2 5/16-inch
  centers, cuts 116 / 120 5/8 / 125 1/4. Use actual calculated rack cuts for
  MAX PIPE and its warning instead of treating the entered clear gap as centers.
- [x] Add Parallel 90 coverage for the reported marks and three/six pipes in
  all four directions, including different per-pipe gains. All 69 selected tests pass.
- [x] Recheck this MAX PIPE case on-device after rebuilding: expected cuts
  110 3/4 / 115 3/8 / 120 with the same bender and spacing.
- [x] Show the existing Hub corner-arrow diagram for Stage 1 and distinguish
  Before turn (IN) from After turn (OUT) support references.
- [x] Verify the first-stage diagram and support wording on-device.

- [x] Replace or finish the Parallel 90 result pictures.
- [x] Tune its pipe-selector dots and picture-card marks.
- [x] Recheck MAX PIPE, overlength warning, and Align Ends behavior.

## Standalone Offset results

- [x] Condense the Results instruction bar so Start New Bend and Parallel are
  visibly discoverable below the result graphic.
- [x] Verify the reported 6-inch vertical × 3-inch horizontal, 30-degree Ideal
  notch example and preserve it as a regression test.
- [x] Display predefined bender take-up, gain, and CLR as field fractions while
  retaining the exact database values for calculations and Rack handoff.
- [x] Add regression coverage proving Centerline is orientation-independent and Notch/Hook reverse equally around the true center.
- [x] Add regression coverage proving Toward/Past and Forward/Reverse preserve A/B order and center-to-center bend spacing.
- [x] Make the Hook Faces indicator match the fixed right-to-left measuring direction: place a left-pointing arrow before the words `Hook Faces` for standard orientation and point it right for Reverse.
- [ ] Manually verify the Hook Faces label/arrow on-device for Toward/Past × Forward/Reverse; the underlying combinations already have regression coverage.

## Offset to Rack Builder handoff

- [x] Transfer Toward/Past, the selected bender data, Arrow/Notch/Centerline/
  Hook, and Forward/Reverse orientation instead of resetting those choices.
- [x] Preserve Rolling Offset mode when the handoff opens Rack Builder.
- [x] Keep Rolling Offset mode active when its rack-direction arrows are
  changed; direction selection no longer falls back to Standard Offset.
- [x] Preload the handed-off Rolling distance, vertical, horizontal, overall,
  and angle fields when returning from Results to Measurements.
- [x] Retain the handed-off bender selection when switching among matching
  Rack Builder pipe sizes.
- [x] Show both header arrows on an imported result: left advances to Next
  Bend, while right returns to the standalone Offset measurements.
- [x] After advancing, keep navigation inside Rack Builder rather than sending
  the user back to the standalone Offset screen.
- [x] Match Offset result-value boxes to the compact 150-pixel, right-aligned
  Rack Builder presentation.
- [x] First prove standalone Pipe 1 and Rack Builder Pipe 1 parity using the
  same shared Offset layout inputs. Rack Builder still has a separate local
  Standard Offset path; Rolling Pipe 1 now uses the authoritative shared
  `bending_data.dart` layout and reference conversions.
- [x] Walk from standalone Offset into Parallel Rack Builder and confirm the
  handed-off geometry, pipe count, spacing, selected Ideal bender, Notch
  method, Toward layout, direction, Pipe 1 result, and graduated rack results.
- [x] Confirm Pipe 1 in Rack Builder matches the completed standalone Offset
  result for both Standard and Rolling offsets across Arrow, Centerline,
  Notch, Hook, Forward, and Reverse combinations.
- [ ] Field-confirm the Rolling Offset centerline and reverse-bender/radius behavior before changing any shared formula.

## Responsive testing

- [ ] Build one reusable collapsible instruction-bar shell: expanded by default, a small labeled chevron when collapsed, and remembered for the current app session.
- [ ] Refactor Pipe and Box Fill so its central visuals/results region fills the available height on larger phones and scrolls inside a bounded minimum-height viewport on shorter phones.
- [ ] Replace full-screen `MediaQuery` vertical-position factors in detail views with local `LayoutBuilder` constraints and clamped spacing.
- [ ] Test the complete Rack Builder flow on the Pixel 9 Pro emulator.
- [ ] Test on the Motorola Stylus.
- [ ] Add Android emulator profiles approximating current smaller iPhones.
- [ ] Test on real iOS simulators in Xcode before release.
- [ ] Recheck all keypads, sticky instruction bars, scrolling, and safe areas.

## Rack Builder navigation

- [x] Kick Type Continue explicitly expands the measurements card, including
  when returning from Results to change type. Preserve entered values (2026-09-13).
- [ ] Phone-check Results → Back → change Kick Type → Continue: measurements
  and their Continue action should appear without another header tap.

- [x] Preserve the latest result type when moving to Next Bend.
- [x] Make Latest Results reopen Parallel 90, Offset/Rolling Offset, or Kick results instead of a blank view.
- [x] Make the Back control return through the preceding measurements/method/geometry phase.
- [x] Show the Next Bend arrow only when a completed result is visible.
- [x] Prevent Calculate plus Next Bend from adding the same result to the Construction Hub twice.
- [ ] Walk through Back, Next Bend, and Latest Results once for Parallel 90, Offset, Rolling Offset, and Kick 90 on the emulator.

## Whole-app release backlog

### Cross-device layout and final walkthrough

- [ ] Audit the physical height of every non-Rack-Builder screen on small and large phones.
- [ ] Add scrolling or another responsive layout where content can overflow vertically.
- [ ] Check width, safe areas, keypads, and bottom instruction bars across representative Android phones.
- [ ] Repeat the screen-size audit on iPhone simulators before release.
- [ ] Perform a final walkthrough and targeted random testing of Pipe, Calculators, Tools & Reference, and Code.

### Calculators

- [ ] Finish the Load Calculator and decide its final feature scope and presentation.
- [ ] Give the otherwise-complete calculator screens a final functional and responsive review.

### Tools & Reference

- [ ] Define the final purpose, workflow, and UI for the Power Hub Solver.
- [ ] Review its Ohm's-law, motor-configuration, and other selectable starting-point paths.
- [ ] Give the Digital Reference Hub a final content and usability review; major redesign is not currently required.

### Code section

- [ ] Audit the entire Code section for placeholder, generic, or incomplete material.
- [ ] Replace filler content with accurate, field-useful facts and problem-solving guidance.
- [ ] Verify sources and technical accuracy before treating Code content as release-ready.
- [ ] Redesign any Code screens whose organization makes information hard to find or apply.

## Formula safety and regression coverage

- [ ] Record trusted field-tested input/output examples for every bend style.
- [ ] Add tests proving Rack Builder and standalone calculators return the same results.
- [ ] Verify all complete bend formulas are authoritative in `bending_data.dart`.
- [ ] Review Across and Forward Kick orchestration in `rack_state.dart`; do not move it until tests exist.
- [x] Replace Rack Builder's duplicate base Offset/Rolling geometry with the
  authoritative `bending_data.dart` layout and center-mark helpers after parity
  tests passed; keep only rack-specific pipe-progression orchestration local.

## Organization after behavior is stable

- [x] Extract picture-card tuning into `bend_visualization_config.dart`.
- [ ] Replace positional Kick configuration lists with clearly named tuning objects.
- [ ] Extract duplicated Offset/Rolling input-card UI.
- [ ] Extract custom-bender management UI and state.
- [ ] Extract Project Hub/support-management sections.
- [ ] Standardize the term "instruction bar" for the bottom screen guidance.
- [ ] Inventory and remove genuinely unused duplicate files and assets only after verification.

## Safe work that can be assigned to Gemini

- [x] Inventory Rack Builder image assets and identify which style/direction uses each one.
- [ ] Build a screenshot matrix listing device, screen, bend style, direction, and visible issue.
- [ ] Locate duplicated widgets and report their line ranges without editing them.
- [ ] Compare user-facing wording across standalone and Rack Builder screens.

## Keep under Codex/manual review

- Formula changes in `bending_data.dart`.
- Changes to `RackState` calculation or measurement direction.
- MAX STUB and overlength behavior.
- Navigation, responsive sizing, scrolling, and safe-area behavior.
- Any deletion or large extraction from `rack_builder_11.dart`.

## Hub walkthrough update (2026-09-07)

- [x] User verified saved stub labels with a shorter stub, return from Results
  to measurements, Latest Results, Next Bend navigation, and the edit warning.
- [x] Hide a removed IN/OUT support measurement in the corner diagram while
  retaining arrows and IN/OUT labels. Preserve deletion when adding another bend.
- [x] All 73 selected Hub and bending regression tests pass.
- [ ] Confirm removed-support diagram measurements on-device after rebuilding.

Saved bend-result snapshots and read-only View Results are now implemented.
Next: verify the saved-result round trip on device. Stage resize/removal support
policy and exact per-pipe material totals remain open. No extra Start Over action
is requested; Next Bend and Clear Hub cover the current navigation needs.

## Standalone Saddles — display complete; field verification deferred

- [x] 2026-09-19: connected user-provided 3_bend_saddle.png and
  4_bend_saddle.png in assets/images/bends; corrected reversed filenames.
  Final photo area is 85 pixels, overall graphic block 215 pixels. User accepted
  the pictures, compact layout, and measuring-end caption on 2026-09-21.
- [x] Moved standalone kick_90.png, btb_1.png, and btb_parallel.png into Bends;
  updated screen references and Flutter asset registration. Straight pipe unchanged.

- [x] Removed the Kick placeholder and connected the correct three-/four-bend photos.
- [x] User verified that skipping optional overall length shows bend marks only,
  without the fabricated 120-inch-plus-shrink cut warning.
- [x] Both Saddle mark/cut calculators are already in bending_data.dart.
- [ ] Verify four-bend Saddle centering with Notch when more pipe is available.
  Example: Ideal 1/2-inch EMT, rise 3.5, center distance 18.75, obstruction width
  7, angle 30, finished length 34. Displayed A/B/C/D = 30 3/4, 23 3/4,
  14 1/2, 7 1/2; cut = 35 7/8. User obtained the correct rise but suspects
  roughly 1/2-inch rightward displacement. Tape starts at right; hook faces left
  throughout the push-through sequence. Current code subtracts 0.5686 inches
  from all four center marks. Arithmetic matches; physical placement/sign remains
  unverified. Do not change correction signs or attribute this to bending error
  without evidence. Compare finished flat-top midpoint with 18.75 inches from
  the original measuring end. No formula changes made during this investigation.
- [ ] When resuming Saddle work, reconcile the four-bend screen's bend-order
  decision (distance plus half width) with the central formula (distance already
  means center). They agree for the example above; other inputs can disagree.
  Keep the decision in bending_data.dart rather than duplicating it in the UI.

## Saved Hub results implementation (2026-09-07)

- [x] Capture immutable per-pipe marks/cuts, entered geometry, bender data,
  method/orientation, rack direction, Kick picture variant, spacing and asset.
- [x] Add View Results to expanded bend stages. Reuse the active result-picture
  renderer in an isolated read-only route with pipe selection and Back to Hub.
- [x] Preserve snapshots on stage rename/length copy; mark older stages without
  snapshots as unavailable instead of substituting the latest calculation.
- [x] Verify 78 selected tests; all four saved result modes also pass at
  390 × 844 with six-pipe selection. No bending formulas changed.
- [ ] On-device: save different bends, reopen the first stage, switch pipes,
  and return to the Hub; verify original pictures, marks and measurement direction.
- Missing-photo walkthrough is no longer applicable to the current 24 Kick
  variants: all have photographs. Keep the fallback for unavailable assets.

Snapshots currently share the Hub's in-memory lifetime; this does not add
project persistence across app restarts or historical bend editing.

## Kick top-rack order correction (2026-09-09)

Superseded for Same Angle 2 / Up Left on 2026-09-13: after horizontal-dot tuning,
user requested reversing the top selector again. It now reads P3, P2, P1 from
left to right for three pipes. Actual pipe identities/measurements and tuned
photo-dot coordinates are preserved; the earlier P1-left decision below is history.

- [x] Same Angle 2 (Same Angle, Same Plane), Up Left: display the top rack
  left-to-right as P1, P2, P3, with P1 on the inside/left. Preserve pipe identity,
  calculated marks, photograph-dot order, and every other style/direction.
- [x] Final selector configuration confirmed by user on 2026-09-13; later
  order adjustments supersede the original order described above.

## Kick bender-clearance warning audit (2026-09-11)

- [x] Locate existing standalone Kick 90 warning: kick_90.dart calculate()
  checks Mark B against calculateCurveEnd(), and displays an amber warning
  above the results. No corresponding Rack Builder check is wired in.
- [ ] Reconcile the current 0.5-inch trigger with the 5-inch suggestion target;
  validate the intended seating allowance for the actual bender before claiming fit.
- [ ] Resolve the reference mismatch: isBenderClearanceSafe documents a hook
  position, but standalone passes selected-method Mark B (Notch/Centerline/Hook).
- [ ] Make angle suggestions conditional on finding a passing candidate; the
  current loop can report its final angle even when the target was never met.
- [ ] Add focused warning tests without changing trusted bend-mark formulas.
- [ ] Add a reviewed per-pipe Rack Builder check appropriate to each Kick style,
  naming affected pipes and retaining warnings in saved results.
- [ ] Show the warning before the user starts bending; field-check a tight case
  and a workable case with the selected bender. Angle changes must also recheck cut length.

## Standalone Kick 90 → Parallel Rack handoff audit (2026-09-11)

- [x] Confirm the current Parallel button passes only raw A/B/C, angle, gain,
  and take-up. Rack Builder checks A/B/C only to skip a Parallel 90 reset;
  it does not load them as Kick inputs or select Kick mode. This explains why
  the handoff opens initial Rack Setup without the selected bender.
- [x] Add an Offset-style Parallel Setup card below standalone Kick results:
  pipe count, spacing, Space Between / Center to Center; choose direction in Step 4.
- [x] Transfer original stub, kick rise, angle, leg, conduit size/type, selected
  bender and effective calculation data, marking method and supported direction
  choices. Do not reconstruct inputs from A/B/C or silently choose new bender data.
- [x] Add a dedicated Kick handoff path in Rack Builder that bypasses initial
  rack/bender/starting-point setup and opens prefilled Kick measurements/style review.
- [x] Prove imported Pipe 1 A/B/C parity with effective fractional bender values
  across all three marking methods and both spacing modes.
- [ ] Extend parity coverage to custom benders and mixed pipe sizes.
- [x] Preserve the original collision warning during handoff and saved review.
- [ ] Implement reviewed per-pipe clearance validation before claiming a whole rack fits.
- [ ] Verify Back, Next Bend, Hub commit-once, and saved-result review after import.

The handoff implementation below resolves the original audit's navigation and
data-transfer issues. The remaining clearance and verification work is separate.

## Kick Parallel handoff implementation (2026-09-11)

- [x] Capture the completed standalone Kick inputs and effective bender values
  in an immutable handoff instead of rebuilding inputs from result marks.
- [x] Parallel opens count/spacing setup; Continue opens Step 4 Kick Type and
  direction, followed by prefilled measurements. Starting Point is skipped.
- [x] Preserve Notch/Centerline/Hook and EMT/RMC selection. Keep the original
  collision warning visibly labeled as source information, including saved review.
- [x] Prove exact Pipe 1 parity using the Ideal 1 1/4-inch effective rounded gain
  across all three marking methods and both spacing modes. All 84 selected tests pass.
- [x] Allow Back from the initial imported Kick type screen to return to standalone.
- [x] User walkthrough confirms the Parallel handoff reaches Rack Builder with
  the measurements filled in and functionality working (2026-09-11).
- [x] Match Kick Parallel Setup to the Offset card: dark panel, silver frame,
  equal-width spacing buttons with red selected fill/outline, and red Continue.
- [x] Confirm the updated Parallel Setup styling on device: user approved its
  appearance in the 2026-09-11 screenshots.
- [ ] On-device: finish a standalone Kick, Parallel → count/spacing → Step 4,
  change type/direction, Continue → confirm prefilled measurements and bender,
  calculate, and compare Pipe 1 marks before edits. Verify Next Bend and View Results.
- [ ] Extend handoff tests to custom benders/mixed sizes and source-screen interaction.

The inherited warning describes the original bend only; whole-rack bender
clearance validation remains a separate open task. No bending formulas changed.

## Kick results layout follow-up for tomorrow (2026-09-12)

Screenshot references: Screenshot_20260911-204329.png (results) and
Screenshot_20260911-204403.png (Parallel Setup expanded).

- [x] Move Start New Bend and Parallel out of the results card to below its
  bottom border, after the picture and "Measure from this end", and before the
  fixed "Kick 90 complete" information bar.
- [x] Compare Offset and Back-to-Back results: both use bordered results groups,
  with differing action placement. Keep Kick's border around the results header,
  marks, picture, and measurement-end guidance; actions now sit outside it.
- [x] Parallel now enters a separate setup stage at the top of the screen,
  replacing the results content while preserving the completed bend. Retain
  approved card styling, with Back to Results and app/system Back support.
- [x] Pipe count and spacing are explicitly cleared every time Parallel is
  opened, as well as on Start New Bend. This also removes retained values from
  an already-running screen after hot reload; no default numbers are inserted.
- [x] Mirror the standalone Kick illustration horizontally in the widget layout;
  place A on the left, B in the middle, C on the right, and point the measurement
  arrow left. Original image asset and bending formulas are unchanged.
- [x] Replace the standalone results photo with the user's new
  `assets/images/rack_builder/kick_90.png` (2026-09-12). It already faces left,
  so remove the old widget mirror; retain the left-facing marks and guidance.
- [x] Fit the new standalone Kick photo inside the results card width with side
  padding. Remove the old overflowing viewport-width image and fixed 200-pixel
  picture slot; use its natural aspect ratio with compact vertical padding.
- [x] User approved the final standalone Kick picture placement: compact image
  area, measurement block lifted 20 pixels, picture shifted 10 pixels left.
- [x] User reported the separate Parallel stage functioning correctly; the
  subsequently reported retained defaults were fixed by clearing fields on entry.
- [ ] Explicitly verify blank inputs/validation after that final clearing fix,
  keypad use, and both Back controls returning to preserved results.

Layout changes implemented and picture placement approved 2026-09-12.
The results group still shares one border; it does not have
a separate Rack Builder-style picture card.

## Match Bend 2 Up Left follow-up (2026-09-12)

- [x] Top rack selector now orders Pipe 1/2/3 left to right for
  90 to Match Bend 2 / Up Left, matching the existing Same Angle 2 fix.
  Pipe identities and bending formulas are unchanged.
- [x] Confirm this variant's selector visually on device (user closeout 2026-09-13).
- Field reconstruction, not confirmed original inputs: Ideal 1/2-inch EMT,
  Notch, stub 12, match distance 16, kick 7, leg 35 1/8, centers 2 inches.
  Existing formulas reproduce Pipe 1 A/B/C = 7 / 26 1/2 / 46 3/16 and
  Pipe 2 A/B = 9 / 30 5/8. Pipe 2 C calculates 50, differing from the
  user's approximate 49 7/8. Calculated angles: 25.9445 / 22.8854 / 20.4873
  degrees for three pipes. Verify the remembered inputs and Pipe 2 cut before
  treating this as the original layout. Thirteen Kick regression tests pass.
- Updated field readings resolve the fractional-leg discrepancy: user now reads
  C = 46 1/16, 49 7/8, 53 11/16. All three match base leg 35 exactly at display
  precision with the same stub 12, kick 7, match 16, centers 2 and Ideal 1/2 EMT
  Notch settings. Base leg 36 produces 47 1/16, 50 7/8, 54 11/16. This supersedes
  the earlier fitted 35 1/8 candidate. It establishes matching inputs, not proof
  of yesterday's entries. A/B and angles are independent of leg in this style.

