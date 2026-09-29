# Pipe & Wire — general to-do

Active Android/iPhone layout work: [COMPATIBILITY_TODO.md](COMPATIBILITY_TODO.md).
As of 2026-09-29, the user has the app running on a physical iPhone from the Mac;
older Mac/iOS deferral notes below are historical.

Updated 2026-09-23. General app tasks belong here; future feature ideas belong in
[FUTURE.md](FUTURE.md). Existing Rack Builder checks and other-screen finish chunks
remain in [RACK_BUILDER_TODO.md](RACK_BUILDER_TODO.md); do not duplicate their status.

## Current: activate website and YouTube buttons

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
