# Construction Hub Handoff

## Active status — 2026-09-23

Use the short RACK_BUILDER_TODO.md as the master work list; the previous complete
checklist is preserved in RACK_BUILDER_HISTORY.md. Older sections below describe
past states, not a second active backlog.

Reconciliation: additions append (no middle insertion); per-pipe material counts
and Pull Box resets are implemented/tested; stage resize/removal support choices
are implemented/tested with manual checks pending. General saved-history review
was accepted on 2026-09-21. Pictures/dots, including standalone Saddle photos,
are accepted. Do not reopen these because older notes describe them as unfinished.

Remaining Hub work is targeted navigation/commit-once and imported/Starting Point
round trips, support-choice/removal checks, and a hand-counted materials example.
Reviewed per-pipe bender clearance remains substantive unfinished work. Historical
editing and multiple bends per stick remain deferred. User drives manual tests;
Medium Phone results are generally acceptable. Mac/iOS setup is deferred.


## Current handoff — 2026-09-22

Continue with SCREEN_VIEWABILITY_HANDOFF.md and RACK_BUILDER_TODO.md.
Hub additions append; Kick 90 saves at results; Standard/Rolling selection starts
fresh; saved full-stick offset results show finished length after shrink.
Material counts use saved per-pipe cuts and separate-stage joins, with all paths
reset at one Pull Box. Two focused material tests passed; no offcut reuse assumed.
Starting Point remains card 3 and reopens its original input form, not a separate
summary. Existing stages are preserved and reopening cannot append another initial
stage. User accepted navigation, info text/arrows, custom straight lengths and
the final slow-scroll position. Do not retune these without a reported problem.
Starting Point overlength warning, spacing-choice gate, immediate Hub save and
picture removal are implemented; retain remaining end-to-end checks in the TODO.
Use the user's phone walkthrough for cosmetic edits; avoid repeated broad tests.
Stage resize/removal support policy, handoff/duplicate checks and physical bend
verification are not all closed. Earlier notes below are historical context.

## Latest walkthrough acceptance — 2026-09-15

User is satisfied with the current Hub and is pausing further Hub work unless
another issue appears. Confirmed skipped-start support references, manual support
entry/remaining distances, Add Support scrolling, compact View Results styling,
white Back to Hub text, and before/after-90 measurement placement. Older Kick
stages now recover their missing after-90 distance from saved stage data.
Kick corners use the existing support/arrow logic despite total bend degrees
exceeding 90. Existing authored supports remain preserved.

This closes those walkthrough fixes, not the separate open commit-timing audit,
stage resize/removal policy, material totals, or physical clearance validation.
See RACK_BUILDER_TODO.md for those remaining items.

## Purpose

This file is the durable starting point for a dedicated Construction Hub task
inside the Pipe and Wire Clean project. The master project checklist remains
`RACK_BUILDER_TODO.md`; update its **Construction Hub** section as work is
verified.

The current goal is to make the Hub a dependable sequence and review tool while
protecting the field-tested bend calculations. Do not treat every audit note as
a mandatory first-release feature. Work in small, tested stages.

## Safety boundaries

- Do not change formulas in `bending_data.dart` as part of Hub cleanup.
- Do not change Rack Builder Kick, Offset, Rolling Offset, or Parallel 90 marks
  merely to reorganize Hub data.
- Preserve the user's existing dirty worktree and unrelated edits.
- Add focused tests before changing sequence identity, insertion, removal, or
  support movement.
- Prefer a read-only saved-result view before attempting editable historical
  bends.

## User intent and confirmed terminology

- Users should be able to add bends and other stages, return to the Hub, expand
  any stage, and understand what that stage contained.
- `View Results` now reopens a saved bend's actual results for
  review. Editing is desirable later, but only with clear Save/Cancel and
  downstream recalculation behavior.
- Bend degrees are an ongoing total, not merely a warning. The dashboard totals
  degrees since the latest Pull Point. Exactly 360 degrees is allowed; the red
  exceeded warning begins above 360 degrees.
- `Stock Footage` means purchased footage represented by the number of 10-foot
  sticks. `Run Dist` is the length of the planned path. Installed footage and
  per-pipe cut totals are separate concepts and are not finalized yet.
- Planning multiple bends on one physical conduit stick is a background design
  item, not part of the current Hub safety pass.

## Current Hub behavior that is useful

- The Hub presents ordered Straight, Bend, and Pull Point stages.
- Stage cards expand and collapse and use distinct type colors/icons.
- Straight length editing exists.
- Supports are grouped into the stage containing their absolute position.
- The Hub displays sticks, couplings, stock footage, run distance, and the
  continuously updated degree total.
- A Pull Point resets the degree total for the following run section.
- Clear Hub has a confirmation dialog.

## Completed safety slice

The first small integrity slice is implemented:

- `RunSegment.copyWith` preserves degrees, stub/leg, direction, support offsets,
  transition state, multiplier, and legacy material metadata when the editable
  length or label changes.
- Moving a support without supplying a replacement label preserves its current
  label.
- Clear Hub clears the run, support positions, and the support-label map.
- The degree warning threshold changed from `>= 360` to `> 360`.
- The dashboard label changed from `Pipe Footage` to `Stock Footage`.

Verification completed:

- `test/rack_state_sequence_test.dart` covers edit metadata, moved support
  labels, full clearing, and the 360/greater-than-360 boundary.
- The focused Hub tests plus the existing Kick, Offset parity, and Offset formula
  suites passed: 58 tests total.
- Static analysis reported no errors in the touched files; existing project
  warnings remain.

## Audit findings that remain open

### Sequence integrity

- Resolved in the sequence safety pass: stage references use stable identities,
  repeated commits use explicit result identity, and bends honor Hub selection.
- Segment removal currently has no individual confirmation. This is optional and
  should be decided based on the desired workflow rather than assumed necessary.

### Supports

- Updating or removing an earlier stage can leave downstream absolute support
  positions inconsistent with the revised sequence.
- Do not automatically change this until the product rule is decided: are manual
  supports fixed real-world locations, or should they move relative to the stage
  that created them? Add tests for the chosen rule.

### Saved bend review

- Implemented: new Hub bend stages retain immutable inputs, settings, pictures,
  per-pipe marks and cuts. View Results opens an isolated read-only result screen.
- Saved review displays the original inputs and settings; older stages without
  snapshots explicitly report unavailable results. Storage is session-only.
- Remaining: verify the historical-stage/pipe-selection/Back to Hub round trip
  on device. Design Save/Cancel and downstream rules before historical editing.

### Material totals

- `RunSegment` currently provides one effective length for every conduit in the
  stage. Graduated rack bends can have different physical cut lengths per pipe.
- Exact per-pipe cuts are now stored in bend snapshots, but the material
  simulation still uses the stage's shared effective length. It remains an
  estimate near 120-inch stick boundaries until it consumes those per-pipe cuts.
- Pull Point material handling currently operates through a fitting stage with a
  multiplier of one. Its reset/counting behavior must be defined for every active
  conduit in a rack.
- The summary calculates fittings internally but does not display them.

## Multiple bends on one stick: future model

The desired example is an Offset or Saddle followed by a 90 on the same conduit
stick. This should eventually be modeled per physical conduit, not by adding
unrelated stage lengths:

- Track a 120-inch stock stick for each pipe path.
- Carry the current measuring origin and all bend-mark locations forward.
- Accumulate the physical cut/consumed length from each operation.
- Verify that the next bend and its required straight/end clearance fit on the
  remaining stick.
- Add a coupling only when the next operation cannot fit.
- Preserve each trusted bend formula; this layer coordinates completed bend
  results rather than recalculating their geometry independently.

No minimum end-clearance rule has been approved yet. Research and field input
are required before implementing that warning.

## Next recommended implementation stage

Implemented the sequence identity and UI-state safety pass (2026-09-06).
All 60 selected Hub, Kick, Offset parity, and Offset formula tests passed.
Static analysis found no errors; existing warnings and lint findings remain.
Stable in-memory stage IDs now preserve expansion, selection, and edit targets.
Explicit result commit IDs replace geometry rejection; all bend commit paths
honor the selected Hub location. A removed selection falls back to appending.
Support movement and bending formulas were not changed.

Remaining sequence verification: perform the emulator/phone walkthrough below.
Check expanded/selected stages while inserting/removing nearby stages, deleting
an edit target, identical consecutive bends, Calculate then Next Bend, and middle
insertion for Parallel 90, Kick, Standard Offset, and Rolling Offset.

Implementation checklist (steps 1–6 complete; step 7 pending):

1. Add tests for removing and inserting before/after expanded or selected stages.
2. Give saved stages stable identities rather than using list index as identity.
3. Remap or store expansion/edit selection by stable identity.
4. Replace geometry-based duplicate rejection with explicit commit identity.
5. Make bend insertion honor the selected Hub location.
6. Rerun Hub, Kick, Offset parity, and Offset formula tests.
7. Complete the targeted emulator/phone sequence walkthrough. Saved snapshots
   have since been implemented; material-model changes remain open.

## Starting files

- `RACK_BUILDER_TODO.md` — master project and Hub checklist.
- `lib/rack_state.dart` — `RunSegment`, sequence mutation, supports, materials,
  and degree totals.
- `lib/rack_builder_11.dart` — Hub overlay, stage accordion, insertion/removal,
  and result commit/navigation behavior.
- `test/rack_state_sequence_test.dart` — focused Hub state coverage.
- `test/rack_builder_kick_test.dart` — trusted Rack Builder Kick regression tests.
- `test/rack_builder_offset_parity_test.dart` — standalone/Rack Offset parity and
  rolling progression coverage.
- `test/offset_formula_test.dart` — authoritative Offset behavior examples.

## Walkthrough follow-up: Parallel 90 MAX PIPE and supports

The walkthrough found MAX PIPE using the raw spacing field while Results uses
actual center progression (including conduit OD for clear-gap input). Reproduced
all reported A/C marks for a 66-inch stub and 2 5/16-inch centers. MAX PIPE now
uses the longest actual calculated cut, preserving the bend formulas and stub.
The warning uses that same result basis. The editable leg rounds down to a
sixteenth to avoid exceeding stock through display rounding; where exact lengths
fall between sixteenths, the longest cut can be slightly under 120 inches.
All 69 selected regression tests pass, including nine new Parallel 90 tests.

The corner diagram was still present but excluded Stage 1 by an index > 0
condition also found in HEAD before the safety pass. That condition is removed;
IN/OUT support rows now have distinct titles and arrow-based reference text.
Support positions and movement rules are unchanged. Rebuild and repeat both
walkthrough checks before marking device verification complete.

## Support edit choices and first-bend return (2026-09-07)

User confirmed MAX PIPE and first-stage arrows/IN/OUT work on-device.
Support edits now ask Cancel, Just this support, or Move downstream before
applying. The latter shifts later supports by the same signed run-distance delta,
with no bend or conduit-length changes. Edited layouts survive later automatic
support population; existing authored stages are retained and new stages can
receive defaults. Overlap/crossing fixed neighbors is rejected. Stage length or
removal policies remain a separate open decision.

Hub labels retain last coupling, replace from last with from previous support,
and use Pipe beyond last support. Stub/leg values retain their saved roles and
missing values are omitted. Latest starting-point 90 results can return to their
input panel even with Hub content. This is not historical snapshot editing.
Skipping Starting Point can be undone with Back before saving any stage.

72 selected tests passed; analysis has no errors and existing warnings remain.
Device verification of the new dialog, return paths, and labels is still needed.

## Removed-support diagram follow-up

User verified stub roles, Results/measurements/Latest Results/Next Bend navigation,
and the edit warning. Removing an IN/OUT support now hides its numeric diagram
measurement while leaving arrows and IN/OUT labels. Deletions mark the existing
support layout as authored, so subsequent bend additions do not recreate them.
All 73 selected regression tests pass. Device verification of this last display
change remains pending. Saved-result snapshots and read-only review were
subsequently implemented as described below.

## Read-only saved bend results implemented

New bend commits now attach immutable SavedBendResult data to RunSegment.
The View Results action opens a separate route with isolated RackState data,
without formulas, bender lookups, commits, or live-input setters during review.
It reuses the active picture/mark renderer and offers pipe selection, saved inputs,
bender/method/direction details and Back to Hub. Earlier stages without snapshots
show an unavailable message. Snapshots survive segment copies and source changes.
They remain in memory with the Hub; no app-restart persistence is added here.

78 selected tests passed, plus phone-width verification for all four result modes.
The shared measurement-direction caption now scales to fit narrow cards.
Next: verify the saved-result round trip on-device before historical editing or
material-model changes. The standalone Saddle results wrong/missing photograph
was added to the master checklist as requested; that picture work is not done.

## Standalone Kick Parallel handoff (2026-09-11)

Parallel now offers pipe count and spacing mode on standalone Kick results.
A completed-input KickRackHandoff carries the actual bender numbers used by
standalone into Rack Builder Step 4 (Kick type/direction), then prefilled inputs.
It bypasses Starting Point and does not commit a Hub stage just by opening.
Pipe 1 parity is verified for Notch/Centerline/Hook and both spacing modes with
Ideal 1 1/4 EMT effective rounded gain. All 84 selected regression tests passed.
Original standalone clearance warnings are labeled as source warnings and saved
with the result; no whole-rack clearance guarantee is introduced.
The next verification is the full handoff round trip on-device, including bender,
measurements, source return, Next Bend, single Hub commit and saved-result review.

## Checklist reconciliation (2026-09-12)

Picture closeout update, 2026-09-13: user confirms all Rack Builder bend picture
cards and selector-dot configurations are finished, including all 24 Kick
style/direction combinations. Image alignment and dot placement are no longer
pending work; preserve final user-tuned values. Hub behavior and safety checks
remain tracked separately in the master checklist.

Tomorrow's new user-reported investigations are recorded near the top of the
master checklist: Kick-first support references after skipping Starting Point
("Vertical from box" and a suspicious 42-inch "Pipe beyond last support"),
the purple/outlined View Results button styling, and inconsistent apparent Hub
commit timing at Results versus Next Bend. Reproduce and trace these before
changing behavior; keep commit-once protection and all bending formulas intact.

User confirmed the Kick handoff carries measurements into Rack Builder and the
new Parallel stage works; final blank-field and full round-trip checks remain.
All 24 Rack Builder Kick photographs are installed and user-confirmed. Next
visual work is image alignment and selector-dot placement. Standalone Kick's new
photo and final spacing/left shift are approved.

Hub sequence identity, duplicate-commit protection, insertion, support edit
choices, clearer references, and saved results are implemented. User walkthroughs
confirmed live supports/overhang, first-stage arrows, stub roles, ordinary result
navigation, and the edit warning. Do not mark the detailed insertion/removal,
support-choice, removed-support diagram, or saved-history walkthroughs complete
without those specific checks.

Remaining substantive decisions: supports after stage resize/removal, per-pipe
material simulation and Pull Point handling across all pipes, and reviewed
Rack Builder bender-clearance validation. Historical editing and multiple bends
per stock stick remain future features, not assumed release requirements.

