# Shared formula engine plan

Reviewed October 7, 2026. This records the current code and proposed structure;
it does not certify the existing electrical tables or motor sizing rules.

Current scope: explain the formulas in their existing files. The broader
consolidation below is a future option, not an active refactoring task.

## Purpose

Each calculation should have one implementation used by every relevant screen.
Above that implementation, explain its purpose, equation, units, assumptions,
worked example, rounding behavior and source. Screens collect inputs and display
results; they should not maintain separate versions of the same calculation.

Keep one discoverable formula library with focused files, rather than combining
bending, wire tables, AC theory and circuit sizing in one large file.

## Current ownership and gaps

| File | Current role | Work needed |
| --- | --- | --- |
| lib/power_formulas.dart | Power conversion, AC equations and motor routine | Document standard equations; review motor estimates and AC labels separately |
| lib/power_equations_solver.dart | Calls PowerFormulas and formats results | Keep formulas out of UI; some selectable goals currently fall through to a zero result |
| lib/circuit_load_math.dart | Single-phase conversion, quantities and mixed circuit totals | Use shared power conversions and add plain-English worked examples |
| lib/load_calculator2.dart | Load UI plus repeating-load capacity allowance | Move the remaining circuit-policy arithmetic into circuit_load_math.dart |
| lib/wire_data.dart | Tables, constants and explanatory comments | Mark sources, editions and estimates clearly; distinguish data from executed formulas |
| lib/pipe_and_box_fill.dart | Executes much of fill, derating, voltage drop and box sizing | Extract calculations incrementally; local detail calculations also duplicate some main calculations |
| lib/bending_data.dart | Shared bending calculations and bender data | Preserve existing entry points; reuse them for matching reference calculations |
| lib/reference_hub.dart | Reference UI with offset arithmetic | Reuse existing shared bending routines where their assumptions match |

## Proposed responsibilities

- power_formulas.dart: watts, amps, volts, VA/kVA, power factor, horsepower
  conversion and supported AC equations. Pure calculation functions, no UI.
- circuit_load_math.dart: quantities, continuous/noncontinuous allowances,
  capacity used, remaining capacity and maximum units. Calls power_formulas.dart.
- wire_data.dart: conductor, conduit, box and correction-factor data, with sources.
- wire_calculations.dart (proposed): fill, adjusted ampacity, termination limits,
  voltage drop and applicable protection checks. Calls wire_data.dart.
- motor_circuit_math.dart (proposed): verified table lookup and motor sizing
  policy, separate from general power conversions.
- bending_data.dart: existing bending and bender-specific calculations.
- A short index document links these files and lists their callers. A future
  export file can provide a common import without duplicating implementations.

## Explanation format above each formula

1. What question it answers.
2. Equation in words and symbols.
3. Inputs and units, including voltage basis and phase configuration.
4. One worked example and expected result.
5. Assumptions, applicable limits and reference/edition when code-based.
6. Preserve full precision internally; round only for display unless a sizing
   rule explicitly requires a different operation.

Example for single-phase conversion:

    Question: What current does a load draw at the selected voltage?
    Amps = Watts / (Volts * Power Factor)
    277 watts / (277 volts * PF 1) = 1 amp.
    This uses the voltage across that load. A 277V line-to-neutral lighting
    circuit remains a single-phase load even when supplied by a three-phase panel.
    Balanced three-phase total-power calculations use a separate equation with
    line-to-line voltage and sqrt(3).

## Findings to resolve before broad reuse

- Motor estimate defect corrected October 7: solveFullMotorCircuit now uses a
  supported subset of Tables 430.248/430.250, rejects unavailable entries, and
  requires nameplate FLA for the separate overload calculation. Protection factors
  now distinguish efficient Design B and wound-rotor motors; displayed factors
  come from the engine. 45 numeric/rejection checks passed in
  test/motor_circuit_check.dart. The UI provides nameplate entry and marked
  temperature-rise selection. This is a continuous-duty induction-motor preview,
  not a complete motor installation design. Table source: NFPA's published
  2023-cycle revision report; final NFPA reader remained at its access agreement.
- solveResonantFrequency currently takes reactance and inductance and computes
  X / (2*pi*L). Review its inputs and intended label before calling it a resonance
  solver; capacitance is not used by that routine.
- wire_data.dart includes explicitly estimated large-conductor box-volume values.
  Keep estimates distinguishable from verified code table data.
- Comments, actual implementation and examples must agree. NEC-specific changes
  require checking the selected 2023 source and relevant exceptions first.

## Delivery order

1. Document the load formulas and consolidate their power conversion calls.
   Verify existing 120V/277V examples and full-precision capacity boundaries.
2. Review the Power Solver's implemented and incomplete goals, motor estimates
   and AC labels before connecting more screens to those routines.
3. Extract wire/fill calculations one function at a time, comparing old and new
   results on meaningful examples. Keep reference tables and calculations separate.
4. Connect Digital Reference Hub items to the same verified engines.

Avoid a broad file move or whole-app rewrite during these changes. Preserve
current callers until each replacement is checked. Screen sizing remains a
separate concern from formula ownership.
