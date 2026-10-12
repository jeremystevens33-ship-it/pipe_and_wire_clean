# Job Board field feedback

Keep small changes organized here; the user opens and tests each installed build.

October 11 reconciliation: the active remaining checklist is now at the top of
[JOB_BOARD_PLAN.md](JOB_BOARD_PLAN.md). Older Show all/inner-scroll suggestions
below were superseded by five-task paging. Historical full-screen editor notes
were superseded by a wide content-height dialog. Do not treat these historical
notes as additional work required for closeout.

- Workers: preserve full names; recognize “and” / “number two” separators.
  Repeated microphone taps append names. Request a three-second pause allowance
  and a longer recording limit for Workers only. Phone verification pending:
  the speech service may choose its own end time.
- Supports → Unistrut → 7/8" or 1 5/8": size buttons appear inline before the
  quantity form. Default new Unistrut entries to feet; retain saved quantities.
- Quantity dictation: “60 feet” / “sixty feet” becomes 60 with feet selected
  when feet is a supported unit. Keep unsupported units visible for review.

Possible next improvements:

- A saved worker roster with tap-to-assign buttons, so spelling names is optional.
- A clear quantity label such as “Quantity (feet)” beside the unit selector.
- Offer stock-length choices later if the user wants ordering by sticks.

Daily note update:

- Add a note directly inside a task; its task link is automatic.
- Section 5 is the combined log of task notes and general notes.
- Repeated note dictation appends another paragraph rather than replacing text.
- Clear erases the unsaved draft and stays in the editor; it also cancels any
  recording so a late speech result cannot put the erased words back.
- Notes use the same longer pause request as workers; actual timing still
  depends on the phone's speech service.

## Next changes to consider — 2026-10-10

Tracked work: checked items are implemented; phone feedback may lead to adjustments.

### 1. Task list with many jobs

- [x] Press and hold a task to drag it to the top, bottom, or between other
  tasks. Save the chosen order so it remains after reopening the app.
- [x] Scroll the list while dragging near its top or bottom edge so tasks can
  be moved through a long list on smaller phones.
- [x] Offer Compact and Expanded views.
- [x] Compact rows show completion box, task title, and a short status/worker
  summary; selecting a row opens that task's existing cards.
- [ ] Explore showing about three or four compact rows initially, with Show all
  and a task count. Keep the visible amount responsive to the phone height.
- [ ] Consider a bounded task-list scrollbar if useful after testing. Avoid
  requiring two competing vertical scroll gestures to reach expanded task
  details; a Show all control can extend the existing page instead.
- [ ] Add task search when the list grows. Preserve unfinished/completed
  separation and the current due-today/blocked filters.

Suggestion: start with Compact/Expanded and Show all, then decide from phone
use whether an inner scrolling list helps. Expanded cards need more space than
closed task rows, so a fixed four-card viewport may feel cramped.

### 2. Material entry and keyboard

- [x] Show a small measurement/number keypad directly beneath the active field.
  Typed characters appear in that field, with no separate full-screen step.
- [x] Show the keypad only when typing is selected; choosing voice closes it.
- [x] Keep Clear, Done, fraction slash, and microphone reachable on small
  screens. Scroll the active field/keypad into view when needed.
- [x] For prefab bends, remove the always-visible Size (optional) input box.
  Keep conduit size buttons, label them Conduit size, and retain a Custom size
  action for dimensions outside the quick choices.
- [x] Keep angle, conduit diameter, and quantity separate in the saved item.

Suggestion: build the inline keypad for quantity first, then reuse it for sizes.
Its height should fit available space and leave Save/Add reachable.

### 3. Wire: gauge first, type optional

- [x] Wire opens without requiring a type selection first.
- [x] Offer gauge buttons from #14 through 1/0, plus direct custom entry.
- [x] Add a Standard / Large size-group toggle; the large group can include
  further /0 and kcmil sizes after agreeing the desired list.
- [x] Put wire type in an optional dropdown on the quantity/details screen.
  Default to Type not specified so the foreman can fill it in later.
- [x] Expand the type catalog beyond the current THHN / THWN-2 and XHHW-2
  choices, and include custom type entry.
- [x] Preserve the entered gauge and quantity when type is supplied later.

Suggestion: keep unspecified type visible in the saved material summary rather
than silently choosing a wire specification.

### 4. Fasteners

- [x] Screws: offer the requested 6-32, 8-32, 1/4-20, 3/8, and 1/2 quick sizes,
  with custom entry. Preserve a full thread designation when provided; a
  diameter-only request remains diameter-only rather than guessing its pitch.
- [x] Add optional screw style: regular / self-tapping, plus custom style.
- [x] Anchors: quick diameter choices 1/4, 3/8, 1/2, and 3/4 inch, plus custom.
- [x] Allow optional length and anchor type when the requester knows them.
- [x] Keep count separate from diameter, thread designation, and length.
- [x] Washers: flat, fender, and square, with 1/4" and 3/8" quick sizes plus
  custom entry. Size refers to the matching bolt/rod size; allow optional
  outside diameter for a specific washer footprint.
- [x] Nuts: 1/4" and 3/8" quick sizes plus custom entry. Allow an optional
  thread designation; do not infer pitch from diameter alone.
- [x] Threaded rod: 1/4", 3/8", and 1/2" quick diameters, quantity/length,
  and custom entry. Include threaded rod / all-thread voice aliases.

Suggested grouping: keep Washers, Nuts, and Threaded rod as separate buttons
inside Fasteners. Washers then expands Flat / Fender / Square. Separate entries
let the foreman order different quantities without assuming a nut/washer set.

Washer clarification: standard flat washers generally have a smaller outside
diameter than fender washers for the same bolt size. Fender washers are also
flat, but have a wider outside diameter. Square describes the washer shape.
Reference: https://shop.hillmangroup.com/product/black-zinc-fender-washers-18-thru-38-386-pc/01tTU000008Y2L6YAK

### 5. Lights and fixtures

- [x] Add a Name / type field for schedule identifiers such as Type 11 or Type 12.
- [x] Keep physical size/length optional, for descriptions such as 3 ft or 6 ft.
- [x] Store schedule type separately from dimensions and quantity.
- [x] Show the schedule type prominently in the material summary when entered.

Suggested order: inline quantity keypad; prefab size controls; wire gauge-first
flow; compact task list; fastener and fixture fields. The user can change this
order as field feedback arrives.

### Confirmed in this phone review

- Task-origin daily notes save, can be edited/deleted, and appear in section 5
  with their task reference. The user prefers this direction of entry.
- Clear and restart is usable when dictation is imperfect.
- Prefab bend entry successfully saved a conduit diameter, angle, and quantity
  independently (1 inch, 22.5 degrees, quantity 18 in the user's review).

### Material pass — October 10

Implemented fastener shortcuts (washers, nuts, threaded rod, anchors and screws), optional style/thread/length/outside diameter fields, wire gauge-first entry with optional type, fixture identifiers, inline measurement/quantity typing, and prefab conduit size controls. New fields persist with old-record defaults. Focused material checks passed; phone review follows installation. Task compact/expanded layout remains pending.

### Task list pass — October 11

Added Compact/Roomy closed rows, press-and-hold drag reordering with saved order, and native edge scrolling within one main scrolling page. Task details still expand inside the row, completed tasks stay in their folder, and filtered reordering preserves hidden task slots. Calendar keeps due-date ordering. Opening Task list scrolls its header into view. Phone verification is pending.

Workflow preference: user verifies appearance, dragging and scrolling on the phone. Keep automated checks minimal; avoid repeated UI test runs and unnecessary permission prompts. Build/install the update, retain saved data, and let the user open it.

### Phone feedback — October 11: task paging and one-line compact rows

User prefers five tasks at a time with Previous/Next arrows rather than relying on scrolling through a long list. Implemented paging for both Compact and Roomy views, a displayed range/total, and page reset on filter changes. Compact shows only a checkbox, single-line ellipsized title, and dropdown arrow; worker/status summaries and the front edit icon are hidden. Task actions inside expanded cards retain edit/delete/completion and now provide up/down/top/bottom moves across pages; drag rearranges the displayed page. New tasks select their page, reopening selects the reopened task page, and shortened lists clamp to a valid page. The page still scrolls as needed for expanded details. This supersedes the earlier long-list edge-scroll/Show all proposal. Build/install only; user verifies phone behavior.

### October 11 editor and button polish

Phone paging arrows work. Moved them beside Roomy with the range count below. Shared custom-keyboard editor now uses an editable, focusable text field with a visible cursor and phone-style selection gestures (tap cursor; double-tap or hold to select words). App keys replace the selection and retain text focus; inline fields no longer close the keypad when tapping to reposition the cursor. Dictation focuses the field at the result end and scrolls its text to the end. Typing dialogs retain the Board theme. Dialogs and action buttons use firm corners and silver borders, including Save/Add/Done/Cancel. Build/install only; phone verification pending.

### Approved October 11 layout and selection pass

Clear/Cancel/Save in the daily-note dialog now share one equal-width, equal-height row. Task-list controls use a two-row, three-column grid: All/Due today/Blocked above Compact/Roomy/paging arrows, with uniform heights and silver outlines. Task-name input starts at one line and grows without a line cap; compact list previews stay single-line. Shared input fields now default to inline app keyboards, retaining cursor/word selection while editing directly in the original field. Selection context menus are suppressed (including Android process-text actions such as Read aloud/Ask Gemini); app keys remove any leftover context menu before editing. Daily-note Clear uses a notifier to cancel speech safely and erase the draft without closing the editor. No behavior tests this pass; phone verification follows build/install.

### October 11 full-screen task editor

Add/Edit task now uses a full-screen editor with only 4px horizontal content padding, giving the inline keypad almost the full phone width. Text still edits directly in its original field. Cancel/Save stay pinned at the bottom; the form scrolls for remaining fields and respects status/navigation safe areas. Phone testing pending.

### October 11 silver button finish

Replaced the nested detail-button gradient with uniform matte silver (#B3BAC1). Red outlines and black lettering remain. This removes the darker center band seen in the phone screenshot. Phone comparison follows build/install.
