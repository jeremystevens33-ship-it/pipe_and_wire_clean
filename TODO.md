# Pipe & Wire — general to-do

Job Board feature work and captured ideas: [JOB_BOARD_PLAN.md](JOB_BOARD_PLAN.md).
Current implementation handoff: [JOB_BOARD_HANDOFF.md](JOB_BOARD_HANDOFF.md).

## Tomorrow — October 13, 2026

- Check today's GitHub version on the Mac/iPhone and report any differences;
  user confirmed repeated worker dictation, Copy/Paste, accordion scrolling,
  and saved entries surviving restart. Do not keep those as unresolved bugs.
- Spot-check the final pipe default (feet, with sticks optional) and inventory
  populated-first categories on the phone; preserve existing quantities/bases.
- Return to Load Calculator: review Repeating/Mixed Load progress and choose
  the next saved-circuit / room-lighting panel-schedule chunk.
- Review Power Hub's bubble layout and supported goals using
  [POWER_HUB_PLAN.md](POWER_HUB_PLAN.md); agree on a small first pass.
- Keep crew sync/order reconciliation and private Cloudflare web testing queued;
  they are separate future work, not tonight's Job Board closeout.

October 12 acceptance: user confirms repeated worker dictation, Copy/Paste,
accordion scrolling, and saving/reopening entries all work. Locations, section
order, box quantity entry, and cursor-position dictation were also reviewed
positively. New pipe defaults and final inventory polish remain available for
normal phone use/review; no additional broad UI test round is requested.

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

- [x] Identify the website domain and existing source: `pipeandwireapp.com`,
  registered with Cloudflare. Complete landing-page folder found at
  `C:\Users\jerem\OneDrive\Desktop\website` (`index.html`, `styles.css`,
  and `assets/images/pipe-wire-logo.png`).
- [ ] Obtain the exact YouTube channel/page URL from the user; confirm the
  website is ready before connecting the app's WEB button.
- [ ] Connect the existing YouTube icon and WEB button in the main menu footer
  (`lib/main_menu_screen.dart`). Both currently have empty onTap callbacks.
- [ ] Open the intended destinations through the platform's supported URL handler;
  handle launch failure with a readable message and preserve app state on return.
- [ ] Manually verify both buttons and return-to-app behavior on Android;
  include iOS verification when that build environment is available.

Done when both existing buttons open the user-supplied destinations successfully.
The adjacent UPLOAD button is also a placeholder, but its behavior is unspecified
and is not part of this link-wiring task. Do not invent an upload destination.

## Private website and app testing — captured October 12, 2026

Queued for a later session; no website upload, publication, or access-policy
change has been made. Domain registration is complete, but the signed-in
Cloudflare Workers & Pages dashboard showed no projects. The local HTML page
is a marketing website; it does not contain a playable Flutter app.

- [ ] Resume in Cloudflare **Workers & Pages** and set up the landing-page
  hosting from the complete Desktop `website` folder. Keep this private while
  the website and app are unfinished.
- [ ] Configure Cloudflare Zero Trust / Access for invite-only testing: begin
  with the owner's email, then explicitly allowed tester emails using emailed
  sign-in codes. Review any plan/billing prompts with the user.
- [ ] Protect every deployed address, including the custom domain, production
  `pages.dev` address, and preview addresses. Arrange protection before uploading
  actual draft content; a hidden link alone is not private access.
- [ ] Verify signed-out access is blocked and an allowed tester can sign in
  before distributing the testing link.
- [ ] Add Flutter web support to this project (no `web/` folder at the initial
  inspection), adapt native microphone/share features for browser use, and
  review browser support for sensor-dependent tools. Preserve phone builds.
- [ ] Build the browser app into `build/web` and host it behind the same private
  access setup, with a clear entry from the landing page. Website upload and
  Flutter app upload are separate steps.
- [ ] Establish a simple update/feedback workflow for invited testers while
  continuing the user's Android and iPhone checks. Browser testing does not
  automatically add crew sharing or sync locally saved Job Board data.

When resumed, walk through the actual Cloudflare screen one step at a time.
Useful setup references:
- [Cloudflare Pages direct upload](https://developers.cloudflare.com/pages/get-started/direct-upload/)
- [Access policies for specific emails](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/common-policies/)
- [Pages preview access protection](https://developers.cloudflare.com/pages/configuration/preview-deployments/)

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
