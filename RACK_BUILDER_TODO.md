# Pipe & Wire — active work list

Updated 2026-09-23. This is the master checklist for the next work sessions.
General app tasks (including website/YouTube links): [TODO.md](TODO.md).
Future feature ideas and paid-add-on planning: [FUTURE.md](FUTURE.md).
The complete previous list, test history, field examples and accepted tuning are
preserved in [RACK_BUILDER_HISTORY.md](RACK_BUILDER_HISTORY.md).
Hub implementation history: [CONSTRUCTION_HUB_HANDOFF.md](CONSTRUCTION_HUB_HANDOFF.md).
Screen observations: [SCREEN_VIEWABILITY_HANDOFF.md](SCREEN_VIEWABILITY_HANDOFF.md).

## Working agreement

- User drives manual emulator/phone walkthroughs; investigate reported issues.
  Do not restart a broad automated screen tour. Cosmetic work uses manual checks.
- Medium Phone is the current practical test device; Motorola remains the
  accepted tall-screen baseline. Small Phone stress testing is deferred.
- Preserve existing work, stages, accepted pictures, selector dots and bending
  formulas. Do not delete existing duplicate stages to make checks pass.
- Mac setup is deferred. iOS testing and store preparation remain future work;
  Android screen acceptance does not establish release readiness.
- Implemented, manually verified and physically verified are different states.
  Close only the specific check actually completed; fix one reported issue at a time.

## Already settled — do not reopen without a new issue

- All 24 Rack Builder Kick photographs and selector-dot tuning accepted.
- Starting Point reopens its original populated form; final Next Bend scroll accepted.
- Hub additions append. Kick, Parallel 90 and Offset results save to Hub;
  commit-once protection implemented. Specific round trips below remain to check.
- Saved historical results/pipe selection and return to the unchanged current
  bend were confirmed on 2026-09-21. No repeat general saved-review task needed.
- Material counts now use per-pipe saved cuts and separate-stage joins; Pull Box
  resets all material paths. Focused tests passed; manual totals check remains.
- Stage resize/removal choices and future-support handling are implemented and
  tested. The task is now a manual check, not another policy-design exercise.
- Medium Phone: user reports usable scrolling/banners in Rack Builder and other
  visited screens. Screenshots show readable Rack results, Pipe/Box Fill main,
  Triangle and Back-to-Back results; Back-to-Back numeric/name keyboards are usable.
  This is not an exhaustive pass of every route, input state or larger text size.
- Back-to-Back custom radius: source comparison confirms the same gain-to-CLR
  helper as Kick 90. Select pipe size before entering Gain90; screenshots had no
  size selected. No formula fix established; actual retry is not yet confirmed.

## A. Rack Builder — finish one walkthrough at a time

### Continuing rack configuration (2026-09-24)

- 2026-09-26: Next Bend now offers one Continue / Branch / End Pipes editor.
  Taps cycle gray (continue), yellow (branch), red (end here). Group previews
  show preserved spacing, widths and suggested strut lengths. Only yellow
  selections require a branch name; at least one gray pipe must remain.
  Apply preserves earlier stages and uses existing continuation/branch logic.
  Removed the size/spacing/add-pipe editor from Next Bend. This supersedes
  the broader continuing-rack UI described below. Manual walkthrough pending;
  focused Dart analysis run, no automated walkthrough or test suite.

- [x] 2026-09-25 source verification: Space Between converts each neighboring
  pair using gap + half of each actual OD, then accumulates center positions.
  Parallel 90, Kick, Standard Offset and Rolling Offset consume those positions
  (with their existing direction/style rules). No bend-formula changes needed
  for the proposed mixed-size spacing choice. No automated tests run.
- [x] Mixed-size spacing card above setup-preview rack dimensions: Keep Center
  to Center dismisses the question; Use Equal Gaps opens the existing green gap
  input/keypad. A uniform rack's gap before changing size is suggested when known;
  otherwise the gap is left blank for entry. Quick setup remains intact. Converted
  mixed-size spacing uses neighboring actual ODs and shows a range when needed.
  No bend formulas changed; no automated tests run. User accepts the interaction
  and will try it in ongoing use (2026-09-25).
- [x] User accepts inline pipe interaction and shared-before-split Hub stages.
  Removed Active Rack heading, kept selector buttons, and hid dimensions when
  collapsed. Change/Split editors show dimensions while editing.
- [x] Next Bend → 90s resets stored parallel measurements as well as fields;
  the old MAX PIPE value can no longer refill the new bend. One focused widget
  regression passed; saved stages and Back/recalculate behavior retained.
- [x] Hide the continuing-rack preview/editor on initial Skip Starting Point →
  Next Bend. Show it only once a bend exists in the Hub. Manual check pending.
- [x] Revised to inline Next Bend editor: pipe circles above Change Continuing
  Rack; expand to tap pipes off/on, Apply/Cancel collapses. Black/red/gray controls
  and app keypad; size/spacing controls stay collapsed initially. Pull Box returns
  to Next Bend without a rack-change popup. No continuing-count sentence.
- [x] Removing outside pipes trims the width; removing an interior pipe retains
  its gap. Relative center positions persist into subsequent calculations and
  edge-to-edge width. Explicit spacing edits can re-space slots. One focused
  Next Bend integration test passed for middle removal; visual approval is manual.
- [x] Next Bend → Change Continuing Rack: choose existing pipes, add pipes,
  change sizes/spacing, and choose a strut length (blank uses the suggestion).
  Cancel leaves the rack unchanged.
- [x] Preserve earlier stages/snapshots and selected pipe identities/bender
  overrides. Material joins follow continuing identities; new pipes start new paths.
  Latest Results after a configuration change opens the frozen prior result;
  new calculations become the latest result. Bending formulas unchanged.
- [x] 27 focused tests passed, including selection/validation, material counts,
  preserved history, and the Next Bend editor → add straight → prior-results path.
- [ ] User Medium Phone walkthrough: reduce the continuing count, check spacing
  and strut fields, add the next stage, and confirm earlier stages are unchanged.
- [x] Named branches: Split Rack expands inline; select red pipes, name the new
  rack using the app keypad, then Create Branch. At least one pipe stays in each
  rack. Active Rack buttons in Next Bend and Hub preserve each rack's work.
  Shared upstream stages/supports are view-only; branch additions remain editable.
  Hub material totals include all racks and count shared stages once. Degree
  warnings and support planning follow the active rack's path. Clear Hub on a
  branch clears only additions after its split. Session-only, as before.
- [x] Nine focused branch/handoff checks passed: 9→5+4 split, nested splits,
  independent supports, material/coupling totals, invalid names/selections, and
  switching racks through the actual screen. Bending formulas unchanged.
- [ ] User walkthrough: split pipes, name branch, add a bend/straight on each
  rack, switch back and forth, and inspect Hub stages/supports/material totals.

### Current follow-up — Kick Hub direction (2026-09-24)

- [x] User confirms one Kick stage at Results (120 degrees). Next Bend/Back/
  Latest Results duplicate check remains open.
- [x] Map Kick leg to Hub Distance to Back of 90 (IN), and Kick stub to Distance
  from Back of 90 (OUT). Corner support creation/editing uses that same reference.
  Keep original inputs, MAX STUB, marks, formulas and authored support positions.
- [ ] Manually verify a fresh Kick: leg 65, stub after MAX STUB 40 11/16,
  rise 12, angle 30. Hub should show IN 65 and OUT 40 11/16. With default 24-inch
  corner offsets, fresh supports are at run stations 41 and 89. Existing supports
  are not automatically moved; do not clear an existing rack merely to test this.
- [x] Run focused support-planning regression tests: new cases cover Kick
  direction, support placement/editing, renaming and legacy leg recovery.
  Initially declined; subsequently authorized and passed on 2026-09-24.

Superseded 2026-09-24: MAX STUB and Parallel MAX PIPE now retain exact lengths;
only the editable display is fractional. Longest calculated cut reaches 120, with
manual edits returning to entered values. Existing overlength warnings remain.
38 focused tests passed, including six button/Continue/Calculate/saved-snapshot
checks across marking methods and spacing modes. User screen check remains pending.

### A1. Results and navigation (implemented; manual checks remaining)

- [x] 2026-09-24: Back from current Results, edit, and Calculate now replaces
  that Hub stage and its saved result instead of appending. Selecting a new bend
  starts a new stage identity. Stage names, identity and authored supports survive.
  27 focused tests passed, including Kick Back/recalculate and Next Bend → Latest
  Results → Back/recalculate across all three marking methods and both spacing modes.
  User emulator confirmation remains pending; existing duplicates are untouched.
- [ ] Complete Kick, Parallel 90, Standard Offset and Rolling Offset; for each,
  check Hub count at Results, Next Bend, Back and Latest Results. No duplicate
  stage; the intended previous result and input state return.
- [ ] Results → Back → change Kick Type → Continue opens measurements with values.
- [ ] Confirm the two latest transitions specifically: Rack Setup results →
  Continue → Bender keeps its heading visible; Skip Starting Point → Next Bend
  uses the accepted heading scroll. Source verified; no explicit user sign-off yet.

Done when these paths work on the user's test device without duplicate commits
or lost inputs. Generic scrolling acceptance alone does not close this chunk.

### A2. Starting Point and standalone handoff (implemented; manual checks remaining)

- [ ] Actual box-transition Starting Point: explicit spacing choice, overlength
  Go Back/Continue Anyway, Hub entry and support references; Next Bend adds no duplicate.
- [x] Standalone Kick → Parallel: user confirms the handoff worked and retained
  its results in Rack Builder (2026-09-24).
- [ ] Remaining handoff checks: blank count/spacing validation, Back to standalone,
  one Hub stage through Calculate/Next Bend, and saved View Results.
- [x] Standalone Full Standard Offset → Rack: user confirms preserved results,
  three selectable pipes and Mark C at 120 inches. Example: height 6, angle 30,
  obstruction distance 66, full stick, toward obstruction, Notch/Forward,
  three pipes at 3-inch C2C, direction right.
- [x] User confirms Rolling Offset handoff works, but reported Hub creation
  waited for Next Bend. Fixed 2026-09-25: imported Standard/Rolling results commit
  after input/bender initialization, when Results opens. Next Bend uses the same
  commit guard. No automated tests run per user request.
- [ ] User retry: Rolling Results already has one Hub stage; Next Bend adds none.
- [x] Offset measurement inputs now use green borders/active tint; mode-choice
  buttons retain their red styling. Manual visual check pending. Quick Offset
  behavior, overall-length result row and Parallel availability left unchanged
  at the user's request; revisit only when requested.

Done when source inputs/results survive navigation and imported bends save once.

### A3. Hub support editing (implemented; manual checks remaining)

- 2026-09-26 supersedes the shifting choices below: normal stage edits keep
  support locations; support edits move only the selected support; insertion
  keeps other supports fixed. Changed gaps over the current 120-inch planning
  interval prompt Add Support / Not Now. Add Support opens the existing input
  at that gap. Newly beyond-end supports get a short notice. Stage deletion
  retains a brief Remove / Cancel confirmation. Dark bordered Hub styling;
  manual walkthrough pending. Historical shifting checks below are history,
  not requirements to restore those choices.

- [x] User confirms Just this support moved one support and enlarged the next
  gap as expected. User also confirms Move downstream preserved the next
  120-inch gap (2026-09-25). Cancel remains to check.
- [x] Apply support change dialog restyled with Hub dark background, silver
  border, white text and existing red/gray beveled buttons. Visual check pending;
  behavior unchanged and no automated tests run.
- [x] Added support-row menu → Insert after this support, with entered distance
  from that support and Cancel / Add only / Move downstream choices. Moving
  downstream shifts later supports by the inserted distance, not conduit stages.
  Selecting an existing support preserves its value until the first typed key.
  Manual verification pending; no automated tests run per user preference.
- [ ] Support edit: Cancel, Just this support, Move downstream; verify affected
  distances. Remove a corner support: its numeric diagram measurement disappears.
- [ ] Resize/remove a stage: Cancel, Keep locations, Shift downstream; verify
  the dialog's effects, removed-portion supports and later support movement.
- 2026-09-25: User shortened a straight stage 240 → 200 → 150 inches.
  Observed removal of a support in the cut-away portion while a remaining
  support kept its 79-inch gap. Source confirms only supports beyond the old
  stage end shift; remaining in-stage supports are not redistributed. Other
  resize/remove choices remain pending. Clarified zero-movement wording and
  styled the stage dialog charcoal/silver with red/gray buttons; softened the
  support-move dialog too. Manual visual check pending; no automated tests run.
- [ ] Planned support beyond conduit remains visible/editable; suggested
  120-inch gap is editable. Inspect stage/reference labels and existing supports.
- [ ] Spot-check expanded/edit targets after nearby stage removal and append.
  Do not restore historical middle-insertion behavior; additions now append.

Done when each explicit choice has its stated effect and existing layouts survive.

### A4. Totals and overlength warnings (implemented; manual checks remaining)

- User confirms the corrected six-pipe mixed-bender measurements match the
  audit table below. That specific example is manually verified.
- Bender assignment now offers Choose Bender for the next unassigned size,
  selects that group and scrolls to the bender section. Continue appears once
  all sizes are assigned. Removed Continue Anyway / Apply to Entire Rack from
  this flow; unlisted benders use Custom. Focused analysis found no errors;
  user navigation walkthrough pending.

- 2026-09-26 six-pipe audit reproduced the user's reported results exactly:
  2-inch Greenlee 1818 x3, 1-inch Ideal x3, 1 13/16 gap, 60-inch IN, MAX.
  Root cause: assignment affected only the selected pipe; unassigned peers
  inherited the last global brand (P5/P6 used Greenlee's 1-inch data).
  Fixed assignments to cover the whole matching size/type group and restore
  saved group assignments after size changes. Bend formulas unchanged.
  Focused regression passes, including repeated size edits and selection.
  Correct MAX OUT = 29.242 inches (29 1/4 displayed); A/C by pipe:
  14 1/4 / 83 1/8; 18 1/4 / 91 1/8; 22 1/4 / 99 1/8;
  32 3/4 / 108 1/8; 35 3/4 / 114 1/16; 38 11/16 / 120.
  Uses stored gains 6.145 and 4.167, not rounded label values. Manual fresh-rack
  confirmation pending; this is not physical bender calibration or all-size signoff.
  Follow-up: mixed-size spacing range on the 90 measurement screen; global
  Rack Builder reset button requested for consideration.

- [ ] Mixed-size/mixed-bender calculation audit requested: check each pipe's
  take-up, gain, CLR, marks and MAX PIPE with different assigned benders, including
  1-inch, 2-inch and 3-inch conduit; compare against independent worked examples.
  Bender picker compatibility filtering is optional polish, not part of this audit.
- [ ] Check stock sticks/couplings against one hand-counted rack with different
  per-pipe cuts and a Pull Box. Separate stage pieces; no offcut reuse assumed.
- [ ] Recheck MAX STUB's former zero-overage report; warning identifies the
  longest pipe, and Continue Anyway preserves Stub Height and Leg Length.

### A5. Kick clearance advisory (implemented; visual/field checks remain)

- User selected a 2-inch advisory threshold: calculated hook position less
  than 2 inches past the 90 curve end. Not a physical fit guarantee or blocker.
- Replaced standalone collision claim and angle search with "Kick is close to
  the 90. Check bender fit before bending." Normalized marking references;
  Rack results name affected pipes and saved results retain the advisory.
  Existing bend marks/formulas unchanged. Unknown/invalid geometry advises
  checking fit rather than implying clearance.
- 14 focused checks passed: boundary below/at/above 2 inches, all six Kick
  styles with mixed benders across Notch/Centerline/Hook, saved warning capture,
  adequate separation, and six existing handoff/mark regressions.
- Manual visual acceptance and physical bender fit remain unverified. The old
  0.5/5-inch rules and angle recommendation below are superseded, not remaining
  implementation requirements.

- 2026-09-26: Ran five characterization tests in
  `test/kick_clearance_audit_test.dart` against Ideal 1-inch EMT and Greenlee
  1818 2-inch EMT. All reproduced existing shortcomings; passing these audit
  tests does NOT mean physical clearance is validated. Same bend can pass/fail
  solely on Notch/Centerline/Hook reference; trigger is 0.5 inches but angle
  search target is 5 inches; exhausted search can recommend a failing 1-degree
  angle. Kick uses Notch/Centerline/Hook (not a separate Arrow clearance mode).
  Source review confirms no per-pipe Rack clearance validation; standalone
  inherited warning is insufficient. No production formulas changed in audit.

- [x] Review standalone Kick's 0.5-inch trigger versus 5-inch suggested target,
  hook versus selected marking-method reference, and no-passing-angle fallback.
- [x] Agree on advisory rules, then implement focused warning tests
  and per-pipe Rack Builder checks with warnings retained in saved results.

Do not claim whole-rack clearance from the inherited standalone warning. Preserve
trusted bend-mark formulas. Detailed investigation is in the history file.

## B. Other screens — bounded work chunks

| Chunk | Current menu / source | Next deliverable |
|---|---|---|
| B1 Load Calculator | Calculators → Load Calculator; `lib/load_calculator2.dart` | Walk through the current screen, list concrete missing behavior, agree initial scope, then implement and verify one item. Do not confuse it with `lib/code_sections/Load_Calculator.dart`. |
| B2 Power Hub Solver | Tools & Reference → Power Hub Solver; `lib/power_equations_solver.dart` | Agree the intended workflow; review Ohm's-law and motor starting paths, then finish one complete path. |
| B3 Code content | Code → NEC Code Reference; `lib/code_screen.dart`, `lib/code_sections/` | Inventory linked pages and identify actual incomplete/generic content; verify sources and finish one page at a time. No blanket redesign or unverified code advice. |
| B4 Digital Reference Hub | Tools & Reference → Digital Reference Hub; `lib/reference_hub.dart` | Check charts/content and navigation; fix specific findings. No redesign currently requested. |
| B5 Remaining calculators/tools | Box Layout, Feet-Inch-Fraction, Segmented 90, Radius/Arc, Angle Finder; standalone bend screens | User walkthrough with a completed example and relevant keyboard states; record only concrete failures. Check Offset Hook Faces Toward/Past × Forward/Reverse. |

## C. Optional screen polish — low priority

- [ ] Pipe Dashboard circle slightly clips at left/right on Medium Phone.
  Inspect width constraints; small local correction only if pursued.
- [ ] Back-to-Back numeric and nickname keyboards: Android gesture bar overlaps
  the bottom key row in screenshots. Review bottom safe-area spacing.
- [ ] Truncated Rack Builder title, crowded Ambient Temp label and narrow outer
  margins: observations, not authorization for a broad redesign.
- [ ] Hub straight-adder's old 8.3-pixel widget overflow: reproduce manually
  before calling it a current on-device failure.

Broad collapsible-info-bar and Pipe/Box Fill layout rewrites are deferred; current
Medium Phone feedback does not justify them. Larger-text and real iOS checks remain
unverified. No orientation changes requested.

## D. Keep visible for later verification

- [ ] Physical Forward Kick progression, Rolling Offset centerline/reverse-radius
  behavior, and four-bend Saddle Notch centering when conduit is available.
- [ ] Reconcile Saddle bend-order decision with the central helper when Saddle
  work resumes; retain the original field example and do not change correction signs speculatively.
- [ ] Extend custom-bender/mixed-size handoff parity and retain trusted field
  examples where coverage is missing; do not rerun broad suites for screen polish.
- [ ] Real iOS setup/testing, wider release checks and store submission checklist
  after feature scope is settled. Check every retained feature before release.

## Deferred enhancements, not the active finish list

Historical bend editing; multiple bends per stock stick/offcut reuse; extra Hub
metrics; wholesale formula relocation; asset renaming; widget extraction; tuning
object refactors; duplicate-file cleanup. Preserve session-only Hub storage as a
known limitation; saved result snapshots currently do not survive app restarts.

## Suggested next session

Start A1 with one completed Kick and confirm its Hub stage count through Next Bend,
Back and Latest Results. Then choose A2/A3 or B1 according to the user's priority.
Do not attempt every chunk in one session.
