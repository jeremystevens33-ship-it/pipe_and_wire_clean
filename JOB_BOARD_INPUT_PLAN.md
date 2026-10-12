# Job Board input and microphone plan

Requested October 10, 2026; status reconciled October 11. Material entry, Daily
Notes, task titles, workers, and details now use field microphones and inline
app keyboards on Android, with cursor/selection editing and live speech previews.
The numbered delivery sequence below records the implementation approach, not
a fresh pending checklist. Current closeout and deferred work are tracked in
[JOB_BOARD_PLAN.md](JOB_BOARD_PLAN.md). iOS speech source is now implemented;
Mac build and physical iPhone verification remain pending.
Follow [LAYOUT_GUIDELINES.md](LAYOUT_GUIDELINES.md).

## Entry experience

Give each input two routes: tap the field for an app keypad, or tap its microphone
to speak without opening a keyboard. Use the existing black/red/silver visual
style and keep the selected task and destination field visible.

- ADD TASK opens an empty draft with a title microphone and a typing control.
- Materials has an Add by voice action scoped to that task. Existing material
  parsing produces a review of type, size and quantity before Add.
- Task title, custom material name, worker names and daily notes have nearby
  microphones. First support plain dictation into the selected field; broader
  commands such as assignment and completion come later.
- Size and quantity have number/fraction entry controls and microphones. A
  quantity-only input must not treat its number as an inch size.
- Dates keep their calendar picker for the first pass.

Only one input method or recording session is active at a time. Starting voice
hides the app keypad. A compact listening strip names the destination, shows
Listening, and provides Stop and Cancel. Stop ends capture and prepares a draft;
Cancel discards that capture and leaves the previous entry intact. Review allows
Apply/Add, Retry and typing corrections. Speech never silently commits a task or
material, and failed recognition never erases an existing value.

## Reuse and adaptation

The app has AlphaInputKeypad in lib/keypad_6.dart and NumericInputKeypad in
lib/keypad_5.dart. Reuse their appearance and useful keys through a shared input
panel or configurable variant. Keep existing calculator behavior intact.

The letter keypad currently has a fixed 270 logical-pixel key area plus its
bottom bar; the numeric keypad uses 250 plus its bar. Adapt panel sizing to
available space before using them in short Job Board dialogs. Avoid shrinking
keys to unreadable sizes; allow the editor above to scroll and provide a compact
editing view where needed.

Letter entry needs spaces, lowercase/shift, useful punctuation, cursor-aware
insertion, selected-text replacement, backspace, clear and Done. Preserve text
selection and accessible control labels. Fraction/size entry uses the existing
fraction vocabulary and inch formatter; counted quantity entry uses ordinary
numbers. Done closes the keypad and keeps the draft; Save/Add commits separately.

Job Board fields should suppress automatic system-keyboard opening while app
entry is active. This changes input behavior inside the app; it does not remove
Android's keyboard from the phone. Prefer field-level suppression, with explicit
focus and input-panel handling, rather than relying only on hiding the keyboard
after it has already appeared. Verify selection and accessibility behavior.

Reuse the existing Android on-device speech channel independently of either
keyboard. Keep support detection, permission, timeout, stop/cancel and cleanup.
If voice is unavailable, app typing remains usable. Offline speech on actual
devices still needs verification. The iOS bridge now uses Apple's Speech and
AVAudioEngine with on-device recognition when supported, partial results,
permission handling, silence/timeout limits, and stop/cancel/background cleanup.
Build on the Mac and verify on the iPhone. Add field-context help examples only
for supported entry patterns.

## Delivery sequence

1. Build the shared responsive input panel and migrate one material entry flow:
   name, size and quantity, with a microphone accessible without opening it.
2. Separate reusable speech capture from the material-specific review dialog.
   Add scoped listening/draft controls; preserve material parser behavior.
3. Migrate task title, workers, details and daily notes to the same entry system.
4. Complete the remaining Job Board text inputs, including voice-draft correction,
   so they do not accidentally summon the system keyboard.
5. Verify and refine on the user's phone before expanding command grammar or
   migrating unrelated app screens.

## Acceptance checks

- Opening and editing migrated fields does not request Android's keyboard.
- A microphone works with the app keypad closed and targets the selected task
  and field. Duplicate taps cannot create competing recognition sessions.
- Stop, cancel, retry, denial, unsupported devices, errors and leaving the screen
  preserve unsaved input and release the microphone correctly.
- App typing supports edits in the middle of text and replacement of selections.
- Sizes retain fraction/inch formatting; quantities and notes are not rewritten
  as measurements. Review precedes persistence.
- Compact and large phone sizes, short viewports and enlarged text keep the
  active input, Done and recording controls reachable. Confirm actual offline
  speech behavior in airplane mode on supported hardware.
