# Load Calculator — proposed workflow and finish plan

2026-10-06. Direction accepted; first-release scope narrowed to circuits and a
room/lighting panel schedule. Panel and building workflows are not implemented.
The visible title now reads Load Calculator. Preserve existing work and bending
formulas. User performs cosmetic phone walkthroughs; use independent numerical
checks when changing calculation behavior.

## Current findings

Implemented foundation update: existing decimal keypad replaces the system
keyboard for watts, amps, quantity and power factor. The last entered watts/amps
basis drives conversion and totals at full precision. Changing voltage or power
factor updates the companion value. Repeating-load preview is preserved; mode
guidance is selection-specific and unfinished modes do not show circuit results.
Numerical checks passed; keypad placement and appearance await the user's phone
walkthrough. The broader schedule and theme work below remains planned.

Phone screenshot follow-up: the displayed 60W / 0.5A at 120V and PF 1 confirms
conversion. Labels now say watts/amps per unit, with total amps/watts in the live
preview. Load Calculator uses a taller version of the shared decimal keypad;
other callers retain its original height. Darker app-red gradients, smaller step
corners, green input borders, a brighter outlined bottom instruction card and a
shorter conversion note are implemented for manual appearance review. The home
icon now has an explicit white color. No calculation formulas changed in this pass.

Second phone follow-up: amps per unit and result unit current now display at most
two decimal places, suppressing unnecessary trailing zeros. Positive currents
below 0.01A display as <0.01A rather than zero. All calculations retain full
precision. Power factor is collapsed by default behind an optional control;
the current factor stays visible and collapsing never resets an entered factor.
Default PF remains 1 and the compact guidance identifies that assumption.

Visual reference correction: use the supplied Rack Builder/Kick 90 screenshots
as the style baseline. Step cards now have silver outlines and black backgrounds,
with inset, silver-edged headers instead of red enclosing frames. Choice buttons
remain gray with a small red check for the selected option; red fill is limited
to the active step header. Button/content corners are tightened to 8 pixels
(large results cards 10). Calculations and navigation are unchanged. Focused Dart
analysis passed; user checks appearance manually after hot reload.

Spacing follow-up: copied Kick 90's 6-pixel screen inset and group inset,
1.5-pixel silver group border, 2-pixel vertical group margin and 4-pixel gap
between groups. Removed the extra 14-pixel horizontal inset inside expanded
steps so controls align with their header edges. Mode rows use 12-pixel vertical
spacing; selection buttons have a 48-pixel minimum height and 17-pixel labels.
Red selection checks remain. Focused analysis passed; manual phone review pending.

End-of-evening polish: mode buttons now use 6-pixel horizontal/vertical gaps.
Bottom instructions use 18-pixel text and 18-pixel vertical padding. Manual phone
appearance review remains pending; no calculation behavior changed.

Mixed Load implementation: Basic Circuit now supports named saved-in-screen load
entries with per-entry quantity, input basis, PF and continuous status. Add appends;
Edit/Update replaces; Cancel preserves the saved entry; Remove recalculates totals.
Only added/updated entries count in the preview. Switching between styles retains
the mixed list and restores the repeating draft. Voltage changes recalculate all
saved entries from their original input basis. Results show actual amps/watts,
sizing amps (125% continuous + 100% noncontinuous), remaining sizing headroom and
the capacity meter. Empty lists show guidance instead of results. No device disk
save is implemented yet. Service Check remains deferred.

Validation: independent mixed examples, full-capacity and overload checks passed.
A focused Flutter workflow test passed for add, quantity edit without duplication,
remove/empty results and retaining the repeating draft; Dart analysis is clean.
The workflow test exposed a narrower-width results overflow; cards now allow
content height and scale long result values. Phone appearance acceptance is manual.
2023 rule reviewed: [Branch Circuits, 210.20(A)](https://www.mikeholt.com/newsletters.php?action=display&letterID=2881).

- The screen uses brighter red gradients (EF5350/E53935/D32F2F), 18-pixel step
  corners and several 14–16-pixel card corners. Its action buttons and instruction
  area do not consistently follow the familiar red/gray/silver app treatment.
- The bottom instruction area has a faint top border rather than a full outlined
  card. Generic mode instructions also appear inside the first step.
- Basic Circuit and Service Check currently calculate the same repeating load.
  Mixed Load does not yet provide a list of distinct loads.
- Original issue (now corrected): entered amps overrode watts for current, while
  entered watts independently determined the displayed watt total.

## Starting choices

1. **Quick Circuit** — one load or repeating units on a circuit. Keep the fast
   light-count check; allow a small mixed-load list when needed.
2. **Panel Schedule** — named circuits and loads for a room, store or other
   project. Show connected load and phase distribution in a usable schedule.
Later: **Building Load** — a guided feeder/service calculation for a selected
occupancy and calculation method, with applicable demand rules. Do not expose an
unfinished third choice on the first-release screen.

## First-release target agreed with the user

Build a circuit, then combine saved circuits into a room or lighting panel.
Use lighting as the first fully verified workflow, keeping quick checks available.

- Enter different fixture types, their quantities and nameplate load values.
- Combine those loads into named circuits; show actual current and the applicable
  sizing load, with a proposed standard breaker rating for supported circuit types.
- Add circuits to a named panel and assign phase/leg. Show side-by-side totals
  and an imbalance indicator. Offer an editable balance suggestion if it can be
  delivered without expanding the initial scope; manual assignment is sufficient
  for the first working schedule. Exact equality is not always possible.
- Preserve each circuit's identity and inputs when moving it between phases.
  Physical breaker-slot layouts and automatic slot placement are later work.
- Save/reopen the project so the schedule is useful beyond one calculation.
- Conductor recommendations require explicit material, insulation, temperature
  limits and applicable correction/adjustment inputs. Do not infer wire size from
  watts or breaker rating alone. Verify this as a separate calculation chunk.
- Equipment such as AC or elevator motors can be recorded in the schedule with
  supplied/nameplate circuit requirements. Specialized automatic motor, HVAC and
  elevator circuit sizing is outside the initial lighting calculation engine;
  equipment entries must not inherit ordinary lighting breaker-sizing formulas.

The elevator machine room illustrates the intended grouping of circuits, not a
promise that the first version designs every specialized system in that room.
Full dwelling, restaurant, store-service and apartment-building demand engines,
automatic feeder/neutral sizing and export remain later additions.

Panel scheduling and NEC feeder/service demand calculations are separate jobs.
A schedule can feed a building calculation, but a service demand factor must not
silently reduce a branch circuit's required rating.

## Shared visual treatment and instructions

- Reuse established app red headers, gray buttons, silver outlines and green
  input focus instead of creating another independent theme. Compare against
  accepted screens before choosing exact colors and corner sizes.
- Keep rounded corners and safe-area clearance suitable for iPhone. Match the
  app's visual language without changing the accepted Motorola layout globally.
- Use one prominent bottom instruction card with readable white text and a full
  visible outline. Its message should identify the next action or missing input.
  Remove duplicate general instructions inside Step 1; keep specific input help
  and warnings close to the controls that need them.
- Example instructions: “Choose Quick Circuit or Panel Schedule.”
  “Enter the current per light, then the number of lights.”
  “Add a circuit and assign its loads and phase.”
- Any hide/minimize behavior should follow the shared info-bar approach once
  agreed, rather than introducing a separate interaction for this screen.
- Use the same responsive Flutter screen on Android and iOS. Do not fork files
  by platform to solve available-height differences.

## Quick Circuit foundation

- Choose a clear input basis: amps, VA, or watts with the conversion inputs that
  are actually necessary. Do not accept contradictory independent amps/watts.
  Nameplate current is a useful direct path for lights and appliances.
- Enter supply, breaker, quantity and continuous/noncontinuous status. For a
  mixed list, classify each load rather than treating the entire circuit alike.
- Show connected current, sizing load, remaining capacity, overload status and
  maximum whole units where that result is meaningful.
- Distinguish actual current from required sizing current. Apply applicable
  continuous-load provisions and exceptions explicitly; do not present an 80%
  shortcut as a universal equipment rating rule.
- Invalid or missing inputs must produce an instruction, not a plausible fallback
  result. Keep unnecessary advanced fields hidden until relevant.

## Panel Schedule

- Project/panel name, supply voltage/system, panel rating and circuit positions.
- Add named loads: lighting, receptacles, equipment, appliances, motors, HVAC,
  heating and other loads. Record quantity, input basis and continuous status.
- Assign loads to circuits, poles and phases/legs. Start with explicit manual
  assignment; any automatic balancing can come later. Use the actual panel
  arrangement rather than assuming every panel has the same slot pattern.
- Display circuit totals, connected VA, phase/leg current and imbalance. Keep
  nameplate values, design allowances and calculated totals identifiable.
- Save, reopen and edit projects. Plan a readable export/share schedule after
  the calculation model is stable; do not make export block the first prototype.
- Example project: a store with lighting circuits, general receptacles, an HVAC
  unit and refrigeration. Build its circuit schedule first, then separately
  evaluate the feeder/service demand for the occupancy.

## Building Load

- Select occupancy and an eligible calculation method before entering loads.
  Support dwelling standard/optional methods separately; retail, restaurants and
  multifamily calculations require their own applicable rules and eligibility.
- Include floor area and required general-load allowances, applicable appliance
  groups, motors, HVAC/heating, permitted noncoincident loads and neutral sizing.
  Do not assume entered equipment alone captures every required load.
- Restaurants need commercial kitchen equipment rules where applicable, not a
  blanket assumption that every appliance runs continuously.
- Show connected VA, each applied allowance/demand factor, calculated demand and
  feeder/service current, with the relevant 2023 NEC section beside each rule.
- Keep actual load, demand load and circuit/conductor/protection selection distinct.
  A larger conduit does not solve conductor ampacity or service capacity.
- Phase calculations must distinguish balanced estimates from actual unbalanced
  schedules. Do not simply divide every project total evenly across phases.
- Verify rule inputs and eligibility directly against the 2023 NEC before coding
  an engine. Article 220 and Informative Annex D are the main calculation review
  path; also check applicable branch/feeder, motor and HVAC provisions.

## Delivery chunks

1. Bring Quick Circuit styling/instructions into
   the app's established treatment and fix its ambiguous input basis.
2. Add named mixed loads and a basic room/store panel schedule, with editable
   circuits and transparent totals. Verify one worked example independently.
3. Add phase assignment and project saving; review the schedule on both phones.
4. Later: implement one dwelling calculation method and benchmark against the exact
   2023 Annex D examples and applicable rules before adding more methods.
5. Add retail/commercial calculation rules, then restaurant kitchen demand.
6. Add multifamily/other methods and export only as separately reviewable chunks.

This is a substantial expansion. Do not label Building Load complete while it
still uses a basic circuit formula. Keep unfinished workflows clearly unavailable
until their required rules and independent examples pass.

## Reference reviewed for this plan

[Mike Holt's 2023 Article 220 introduction](https://www.mikeholt.com/files/PDF/23_CALC_220.70.pdf)
identifies the branch/feeder/service calculation scope and directs review of
Annex D examples. Exact examples and calculation factors have not been verified
for a new engine in this planning pass; that is a prerequisite for implementation.

## Entry flow cleanup — October 7, 2026

- New repeating and mixed loads start with blank watts/amps fields.
- Numeric and name keypads type into the original field; watts/amps conversion updates live. Selected fields scroll above the keypad, with no duplicate keypad display.
- The first mixed-load editor opens automatically on entry to Load Inputs when no loads are saved. Saving closes it; Add Additional Load has a green border and opens the next draft.
- Results scroll to their header; breaker ratings omit decimal places. Actual Current and Capacity Used distinguish load current from the 125% continuous allowance.
- Focused mixed-load workflow and existing full-precision numerical checks passed. Phone appearance remains for manual review.

- Mode, Circuit Inputs and Load Inputs now have Done actions that collapse the current section, open the next and scroll it into view. Calculate uses Open Results; Results has Done to close. Selected choices have a green border with the existing red check. Unsaved mixed entries must be saved or canceled before continuing.

- Load entry uses equal input cards: name/quantity above watts/amps. Mixed-load Continuous/Non-Continuous sits immediately below them; optional Power Factor stays collapsed and comes last before Done/Cancel. Done saves or updates the entry; the keypad check confirms individual fields.
- App-bar Reset beside Home clears saved loads, drafts, inputs and results and returns to Mode with the initial circuit settings.
- Updated the focused workflow test for first-load opening, input arrangement, Done and Reset. The focused Flutter test passed, including live conversion, save/edit/remove, results scrolling and reset defaults. Manual phone appearance review remains.
