# Power Hub — next direction

October 12, 2026 source review; no solver implementation changes in this pass.
Sources: `lib/power_equations_solver.dart` and `lib/power_formulas.dart`.

Keep the bubble concept as an interactive equation workbench: choose what to
solve, enter known values in labeled bubbles, then see the answer and how it
was obtained. Give it a practical use and an optional learning view.

## First small pass to discuss

- [ ] Space the bubbles according to available screen width/height, following
  LAYOUT_GUIDELINES.md. Current grids are fixed at 450 high, with 100–140 sized
  bubbles and hard-coded positions; the result overlays the same space.
  Reserve a predictable result area and keep inputs reachable on small phones.
- [ ] Clearly mark the target bubble and distinguish entered inputs from the
  calculated answer. Show only the inputs needed for the selected equation.
- [ ] Finish or visibly defer selectable goals that lack a solve path. Source
  currently offers VARs above and S/R/Phi below without corresponding branches
  in `_solve`; the fallback returns a generic 0.0. Do not imply a valid answer.
- [ ] Add a Show Work foldout: equation, entered values with units, substitution,
  and result. Keep explanatory detail optional for quick field use.
- [ ] Review required inputs, zero denominators, nonfinite results, unit handling,
  and the supported single/three-phase paths before changing calculation logic.
  Numerical changes get independent worked examples; the user checks layout.

## Later possibilities

- Guided examples for apprentices: enter known values and explore their effects.
- Optional bubble rearrangement / swapping the unknown, after supported paths
  and compact-phone spacing are stable. Current bubbles animate; this review
  does not establish existing drag-and-drop equation solving.
- Saved worked examples and shareable results using the app's sharing pattern.
- A power-triangle illustration for watts, apparent power, reactive power, and
  power factor, with explicit assumptions and reviewed formulas.

Motor Circuit Preview already exists with separate table-current/nameplate
checks. Keep its code-specific audit in TODO.md; do not infer correctness from
this interface review or expand automatic conductor/protection selection here.

Suggested priority: close Job Board, resume Load Calculator, then agree on the
first Power Hub layout/goal pass. No broad solver rebuild is authorized by this
planning document alone.
