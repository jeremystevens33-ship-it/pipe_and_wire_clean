# Pipe & Wire — active compatibility checklist

Updated 2026-09-29. User-led Android/iPhone walkthroughs; fix one observed issue
at a time. Preserve calculations, accepted photography and the app's visual style.
Historical screen notes: [SCREEN_VIEWABILITY_HANDOFF.md](SCREEN_VIEWABILITY_HANDOFF.md).

## Baseline

## Priority and responsibility — 2026-09-29

Goal: fit smaller phones without making larger-phone layouts look undersized.

| Order | Deliverable | Responsibility |
|---|---|---|
| 1 | Triangle Calculator pilot: inspect usable height, diagram/keypad/results sizing, bottom reachability and text scaling together | Codex reviews/implements; user accepts on iPhone and Motorola |
| 2 | One info-bar/keypad prototype: expanded instructions above keypad, minimize/show always reachable; respect minimized state when keypad opens | Codex implements; user checks on both phones |
| 3 | Apply accepted patterns to reported problem screens, one at a time; repair safe-area/bottom-edge issues | Codex makes shared Flutter changes; user runs physical-phone walkthroughs |
| 4 | Remaining screen acceptance at normal/larger text, keyboard open/closed | User reports concrete failures; Codex fixes and maintains this checklist |

- Mac/Gemini: Xcode signing, iPhone install/build and explicitly scoped iOS tasks.
  User operates the Mac; Codex can prepare handoff prompts. No independent agents
  have been contacted or assigned work. Avoid concurrent edits to the same files.
- GitHub transfers: user commits/pushes/pulls unless explicitly asking Codex to
  do so. Preserve local edits and agree which machine owns each active change.
- Existing home-screen source review: pipes and title share an image-relative
  coordinate stack; text sizes scale with screen width within bounds. This
  explains alignment stability, but is not a universal calculator layout recipe.
- Triangle source already uses SafeArea + SingleChildScrollView. Fixed-height
  controls and diagram spacing still need review against usable screen height.
  Source alone does not establish the cause of the reported bottom loss.
- Pilot approach: size from available content bounds; reduce excess spacing and
  diagram height first on compact screens; let larger screens use more room.
  Preserve readable text/tap targets and scrolling when content cannot safely fit.
  Do not shrink the whole calculator to force everything onto one screen.
- Text enlargement cap remains a proposal (1.2x), not an approved value.

## Baseline observations

- User reports Sequoia via OpenCore, Xcode and Android Studio working on the Mac,
  and the app running on a physical iPhone. iOS testing is no longer deferred.
- Mac changes were pushed to GitHub and pulled on the PC. User reports the home
  screen now matches on iPhone and the larger Motorola after layout adjustments.
  This is home-screen acceptance only; code changes have not yet been audited here.
- Larger iPhone system text exposed layout issues. Exact device model, text/display
  settings and Flutter viewport/insets should be recorded with future reports.

## 1. Controlled text scaling

- [ ] Review existing scaling across the app. `lib/main.dart` currently has no
  app-level text-scaling override.
- [ ] Implement a bounded enlargement policy requested by the user. Proposed
  starting maximum: 1.2x; not yet an approved numeric limit. Prefer some enlargement
  over disabling it entirely so users who need larger text retain an option.
- [ ] Check normal and larger system text on both phones: headings, numeric
  results, input labels, dialogs and custom keypads. Text must remain readable
  and controls reachable. No bend-formula changes.

## 2. Hide/show informational bars

- [ ] Inventory existing info bars and their current expand/collapse controls.
- [ ] Add a consistent compact Hide / Show info control that actually releases
  layout space when hidden and always leaves an obvious way to restore the info.
- Expanded instructions float above content and sit above an open keypad without
  covering keys. Minimized mode leaves a small Show info control; keypad opening
  respects that state. Reserve enough scroll clearance to reach underlying content.
- [ ] Keep validation errors and calculation/clearance advisories visible separately
  from optional instructional text. Decide persistence after the first prototype.
- [ ] User checks one representative screen before applying the pattern elsewhere.

## 3. iPhone edges and bottom controls

- [ ] Inspect safe-area padding, home-indicator clearance, keyboard insets and
  bottom-card margins on the actual iPhone. Reported issue is iPhone clipping,
  not a Mac desktop corner style.
- [ ] Keep content inside safe areas; adjust card corner radius where useful.
  Rounded cards alone do not resolve content clipped by the physical screen.
- [ ] Compare each correction on Motorola to preserve its accepted appearance.

## 4. Bounded screen walkthrough

- 2026-09-29 Triangle pilot implemented from IMG_6036/6037/6038: reserve height
  for the expanded results including Shrink; adapt diagram height from available
  safe-area body height (120–200 logical pixels). Diagram drawing and tap regions
  share the same geometry. Width, key heights and calculation formulas unchanged;
  scrolling remains for viewports too short to fit the minimum layout. The same
  diagram budget is used before/after solving to avoid a result-time jump.
  Motorola and iPhone visual checks pending. No Git push performed.

- [ ] Review the synced home-screen layout changes before reusing their approach.
- [ ] Walk through main menu, Rack Builder, standalone bends, Pipe/Box Fill,
  calculators, reference screens and dialogs as the user visits them.
- [ ] For each issue, record screen, device, text setting, keyboard state and
  before/after acceptance. Do not infer app-wide acceptance from the home screen.

No broad redesign, automatic emulator tour, publishing or Git synchronization
is part of creating this list. Current app-completion work remains in
[RACK_BUILDER_TODO.md](RACK_BUILDER_TODO.md) and [TODO.md](TODO.md).
