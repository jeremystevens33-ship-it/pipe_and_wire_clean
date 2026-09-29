# Offset Formula Audit

Status: read-only audit. No production formulas were changed.

## Scope

- Standalone Offset and Rolling Offset in `offset_starting_point_screen.dart`
- Rack Builder Offset, Parallel Offset, and Rolling Offset in `rack_state.dart`
- Existing shared bender-reference helpers in `bending_data.dart`

## Shared base geometry

Both implementations use the same fundamental equations:

- Rolling true offset = `sqrt(vertical^2 + horizontal^2)`
- Shrink = `effectiveOffset * tan(angle / 2)`
- Travel between bends = `effectiveOffset / sin(angle)`
- Far mark = `distanceToObstruction + shrink`
- Near mark = `farMark - travel`
- Cut length = `120` for Full Stick, otherwise `finishedLength + shrink`

Ordinary Offset produces matching Pipe 1 results in the standalone calculator
and Rack Builder for the tested 15, 22.5, 30, and 45 degree cases.

## Parallel Offset

The standalone screen calculates only the base offset. When the user requests
parallel results, it passes those inputs into Rack Builder. Rack Builder adds a
per-pipe shift for side-to-side offsets:

`pipeProgressionOffset * tan(angle / 2)`

Up and Down currently receive no per-pipe shift. Left and Right both receive a
positive shift; correctness therefore depends on how the conduit order is
interpreted for each direction and needs a direction-by-direction invariant
test.

## Confirmed Rolling Offset discrepancies

### 1. Mark A and Mark B are reversed

The standalone calculator assigns:

- Mark A = far mark
- Mark B = near mark

Rack Builder Rolling Offset assigns:

- Mark A = near mark
- Mark B = far mark

Example: vertical 6, horizontal 8, distance 66, angle 30:

| Result | Standalone | Rack Builder |
| --- | ---: | ---: |
| Effective offset | 10.0000 | 10.0000 |
| Shrink | 2.6795 | 2.6795 |
| Travel | 20.0000 | 20.0000 |
| Mark A | 68.6795 | 48.6795 |
| Mark B | 48.6795 | 68.6795 |

The physical points are the same, but the A/B labels are not.

Field convention confirmed: for the normal left-to-right layout, Mark A is the
farther mark and Mark B is the nearer mark. Reversing the bender changes the
physical bender-reference adjustment; it must not silently exchange the A/B
identities.

### 2. Centerline/radius handling differs

The standalone path subtracts the radius adjustment to establish its true
center mark before calling the shared reference converter for Centerline,
Notch, or Hook.

Rack Builder Rolling Offset bypasses that radius adjustment for Arrow and
Centerline. For Notch and Hook it calls the shared converter directly on the
swapped raw marks, without first applying the same radius adjustment used by
the standalone calculator and ordinary Rack Builder Offset.

### 3. Multi-pipe Rolling Offset progression implemented for Left/Right

`_calculateRollingOffsetRack()` now preserves Pipe 1 as the standalone result
and adds `pipeProgressionOffset * tan(angle / 2)` to both A and B for each
subsequent pipe. The cut length remains unchanged. Automated coverage verifies
the progression for Left and Right using both Arrow and Notch references.

The standalone Parallel setup intentionally offers only Left and Right for a
Rolling Offset. Up/Down projection remains outside this first implementation
until its physical 3D convention is defined and field-confirmed.

## Entry-path comparison

### Standalone Offset to Rack Builder

The standalone screen now transfers distance, offset dimensions, overall
length, angle, spacing, pipe count, pipe sizes, conduit type, Full Stick,
direction, Standard/Rolling mode, Toward/Past layout, selected bender data,
Arrow/Centerline/Notch/Hook method, and Forward/Reverse orientation.

### Rolling-mode initialization and direction preservation

Rack Builder explicitly enters Rolling Offset mode during preload. Its rolling
distance, vertical, horizontal, overall-length, and angle controllers are also
populated so returning from Results to Measurements does not reveal blank or
Standard Offset fields.

Rack-direction changes now use `setOffsetDirection()`, which updates direction
without changing calculation mode. This prevents a Rolling Offset from
silently falling back to Standard Offset when an arrow is selected.

### Rack Builder internal path

Starting an Offset from inside Rack Builder selects ordinary Offset mode;
standalone Rolling Offset handoff explicitly selects Rolling mode. Both paths
then use the same shared base layout and bender-reference helpers.

## Reverse-bender observation

Both standalone Offset and ordinary Rack Builder Offset always subtract the
radius adjustment before the shared reference conversion. The `reverse` flag
changes the sign/direction of the Notch or Hook conversion, but it does not
currently reverse the earlier radius-adjustment step.

Whether that earlier radius adjustment must also reverse is a field-rule
decision and should be confirmed with a known example before changing either
implementation.

## Obstruction relationship: Toward versus Past

Manufacturer instructions distinguish two separate layout intents. They must
not be represented by the existing Forward/Reverse bender control.

### Working toward an obstruction

The controlled location is the second/far bend near the obstruction. Shrink is
added to the measured distance. In the app's established A-far/B-near naming:

- Far raw mark A = `distanceToObstruction + shrink`
- Near raw mark B = `A - travelBetweenBends`

This is the intent currently implemented by the standalone Offset calculator.
Within the app's existing center-reference model, controlling the end of the
second bend requires the center to fall before that controlled end, so the
radius adjustment is subtracted before reference conversion.

### Working past an obstruction

The controlled location is the start of the first/near bend. Shrink is not
added to that start location; the second bend is found by adding the
center-to-center travel. Preserving the app's A-far/B-near naming:

- Near raw mark B = `distanceToStartOfFirstBend`
- Far raw mark A = `B + travelBetweenBends`

Within the app's existing center-reference model, the center of the first bend
falls after its controlled start, so the radius adjustment should be added for
that near bend before deriving/converting the paired marks. This sign must be
encoded by layout intent, not by bender orientation.

### Bender orientation remains independent

Forward/Reverse describes which way the physical bender reference faces after
the true center locations have been established. It changes the Notch/Hook
translation around the true center. It does not select Toward/Past and must not
change which physical bend is near or far.

### Sources

- [Greenlee Site-Rite Hand Bender Instructions](https://cdn.greenlee.com/resources/media?key=1adba548-f1d2-43d2-bf44-fe4b89a8b579&languageCode=en&type=document)
- [Greenlee 881/881CT Hydraulic Bender Instructions](https://cdn.greenlee.com/resources/media?key=3a828182-5ef7-4324-9981-144707da57e2&languageCode=en&type=document)
- [Klein Tools Conduit Bender Guide](https://data.kleintools.com/sites/all/product_assets/documents/instructions/klein/ConduitBenderGuide.pdf)

### Hand-bender manufacturer comparison

| Manufacturer | Toward/into obstruction | Past/away from obstruction | Reference used in instructions |
| --- | --- | --- | --- |
| Greenlee Site-Rite hand bender | Add shrink; locate far bend first, then measure back by center-to-center distance | Control start of first bend; add center-to-center distance for second bend | Arrow |
| IDEAL hand bender | Consider/add shrink when working into the obstruction | Explicitly says to ignore shrink when working away | Arrow; rotate conduit 180 degrees for second bend |
| Klein hand bender | Adds total shrink to distance to obstruction, then spaces the second mark by the multiplier | No separate past procedure in the reviewed guide | Arrow; hook faces away from second mark on first bend |

The three hand-bender guides agree on the Toward geometry. Greenlee and IDEAL
independently confirm that Past/Away is a distinct no-shrink layout intent.

Klein separately identifies its teardrop as the exact center of a 45-degree
bend. The application's use of that notch for other bend angles is therefore a
calculated reference conversion built on the true center, not the ordinary
manufacturer Arrow procedure.

### Recommended calculation pipeline

Keep these decisions independent and apply them in this order:

1. **Effective offset:** ordinary height, or rolling true offset from vertical
   and horizontal components.
2. **Layout intent:** Toward establishes the far bend from distance plus shrink;
   Past establishes the near bend from the controlled start without shrink.
3. **True bend centers:** apply the appropriate radius-adjustment direction to
   the controlled bend, then locate the paired center using center-to-center
   travel.
4. **Reference method:** output Arrow directly, true Centerline unchanged, or
   convert the true centers to Notch/Hook references.
5. **Bender orientation:** Standard/Reverse controls the sign of the physical
   Notch/Hook conversion only. It does not change Toward/Past geometry.
6. **Parallel layer:** apply the separately verified per-pipe progression after
   the single-pipe calculation is complete.

For Centerline, changing bender-facing direction does not move the mathematical
center mark. For Notch or Hook, the facing direction matters because the
physical reference is displaced from that center. This is why every workflow
must retain a Standard/Reverse choice even when Centerline itself produces the
same numeric mark.

## Rolling and parallel composition

A single rolling offset should first be reduced to an effective offset using
the vertical and horizontal components, then passed through the same Toward or
Past base-offset calculation.

Parallel progression is a second layer. For the supported Left/Right rack
progression, each later pipe adds `spacing * tan(angle / 2)` to both marks. For
a future general 3D Up/Down rolling rack, spacing may need to be projected onto
the roll/offset direction first; that option is therefore not exposed yet.

## Current authority assessment

| Calculation | Current authority/status |
| --- | --- |
| Effective/true offset | Duplicated but mathematically matching |
| Shrink | Duplicated but mathematically matching |
| Travel between bends | Duplicated but mathematically matching |
| Base A/B marks | Matching for ordinary Offset; reversed for Rolling Offset |
| Cut length | Matching |
| Radius adjustment | Shared helper, applied inconsistently in Rolling Offset |
| Notch/Hook conversion | Shared helper, but receives different Rolling inputs |
| Parallel graduation | Local to RackState |
| Parallel rolling graduation | Implemented and regression-tested for Left/Right |

## Recommended shared boundary

After the expected Rolling A/B convention and parallel-rolling field behavior
are confirmed, add pure shared helpers to `bending_data.dart`:

1. An Offset geometry result containing effective offset, shrink, travel, far
   mark, near mark, cut length, and finished length.
2. A single function that converts those base marks to Arrow, Centerline,
   Notch, or Hook references.
3. A separately tested parallel graduation helper that accepts pipe progression,
   bend angle, and direction/style.

Both the standalone screen and RackState should consume those results. UI code
should format and display values but should not recalculate the geometry.

## Required decisions before implementation

- Preserve the confirmed left-to-right convention: A is the far mark and B is
  the near mark.
- Confirm the expected centerline reference on a real rolling offset.
- Confirm whether reverse-bender orientation reverses only the final physical
  reference conversion or also the preceding radius adjustment.
- Add an explicit Toward/Past layout choice that is independent of bender
  Forward/Reverse orientation.
- Field-check the implemented Left/Right progression on a representative
  multi-pipe rolling rack.
- Define a projected-spacing rule before adding Up/Down Rolling progression.
- Define and transfer the complete calculation context when opening Rack Builder
  from standalone Offset, including bender data, method, and reverse flag.
