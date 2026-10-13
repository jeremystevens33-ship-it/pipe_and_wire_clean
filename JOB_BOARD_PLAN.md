# Job Board project list

Updated October 12, 2026. This is the master feature and idea list for Job Board.
Implementation status and verification context: [JOB_BOARD_HANDOFF.md](JOB_BOARD_HANDOFF.md).
Unchecked entries are proposed or pending, not existing functionality.

Layout direction for this and future screens:
[LAYOUT_GUIDELINES.md](LAYOUT_GUIDELINES.md). Start with compact phones, bound
vertical scaling, and let expanding lists scroll naturally on every phone size.

## October 12 night closeout — user-confirmed acceptance

- [x] Repeated worker dictation retains names; user reports it now works.
- [x] Copy/Paste works on the phone.
- [x] Task accordion scrolling works.
- [x] Saved entries persist across restart/reopening.
- [x] Cursor-position dictation and saved-location selection confirmed earlier.
- [x] New catalog EMT/Rigid/IMC/PVC requests default to feet; sticks stays an
  option. Existing material entries/inventory counts keep their recorded units.
- [ ] Normal user review of the final pipe defaults/inventory category polish
  on the latest Mac/iPhone version; fix specific new reports only.

Earlier pending phone-check notes below are historical where these confirmations
supersede them. No claim is made about airplane-mode speech or every numerical
measurement phrase; investigate those only as specifically reported.

## Finish this version — current remaining work

Inventory category ordering refinement: populated categories first, alphabetized;
empty categories follow, also alphabetized. Items remain alphabetized inside each
category with five-entry paging. Every category has the same-width left bar:
red when it has entries, silver-gray when empty, with no inventory icon. Stable
category keys preserve expansion state as ordering changes. This ordering applies
to inventory categories only; the material-picker button order is unchanged.

Inventory polish — October 12: Add Inventory Item and existing inventory rows/
share summaries now display 4S/5S Shallow/Deep names while retaining stored
identities and balances. Catalog 4S/5S entries omit the redundant size field.
Categories with entries have a flat muted red-gray background, red left accent,
red inventory icon/arrow, and bolder stock count; empty categories stay quiet.
Use “1 stock entry” and plural “stock entries” otherwise. Stock-row Empty/Low
colors remain tied to balances/thresholds. User visual review pending.

Latest field-layout polish: Add/Edit Task inputs all start at one line, share
spacing, and expand vertically with entered text (including Details and Location).
Workers keeps “separate names with commas” in a smaller, always-floating label;
the extra worker coaching sentence is removed. Home-screen location icons and
arrows are white when empty and red when populated. Location actions use matching
full-width 48-high outlined buttons with 12-pixel spacing/padding.
User confirmed cursor-position dictation, comma-separated worker entry, saved
location selection, Roomy summaries, and the wire gauge groups look/work well.
This does not replace the repeated-recording or latest-layout phone checks.

Latest October 12 cursor/location update — implemented, user review pending:
- Dictation now inserts at a valid collapsed cursor, replaces selected text,
  and uses the existing append/replace fallback only when selection is invalid.
  Live previews rebuild from the starting draft/cursor so they do not duplicate.
- Populated home-screen location cards have red arrows and task counts; empty
  locations have silver arrows and zero tasks.
- ADD TASK HERE opens Add Task with that location prefilled. Assign existing
  tasks now offers only unfinished tasks without a location, and never clears
  or moves tasks already located elsewhere. Change assigned locations through
  task editing. This supersedes the earlier reassignment checkbox behavior.

### Tonight's short closeout — October 12

Implementation and phone acceptance are separate. Locations, new card order,
bulk location entry, two-way task/location assignment, material assignment labels,
accordion scrolling, expanded silver borders, clipboard keys, and box quantity
entry are implemented. All current changes are being committed/pushed at the user’s request; see
Git history for the final commit.

1. [ ] Material unit/prompt pass: Pipe catalog still defaults EMT/Rigid/IMC/PVC
   to sticks, while inventory uses feet. Decide on consistent new-entry defaults
   (feet for pipe/wire/Unistrut/threaded rod; pieces for counted items), keep
   optional bases accessible, and never silently reinterpret saved quantities.
   Check boxes, fasteners, bends, and custom items for redundant size/unit prompts.
2. [x] User check repeated worker dictation: a second recording must keep earlier
   names, wrapped text must remain visible, and saving must retain every name.
   Preview retention and live scrolling are implemented; the reported loss is
   not yet confirmed resolved.
3. [ ] Voice measurement follow-up if the user reports remaining issues;
   selection/clipboard phone check is confirmed. Previously proposed checks:
   Cut/Copy/Paste, selected-word voice correction, `1/2"`, and `2"`.
4. [ ] One short connected walkthrough: add locations, assign a task, assign a
   material to that task, complete/reopen it, and reopen the app to check saved
   data. Confirm accordion return scrolling, borders, and hidden collapsed Share.
5. [ ] When the user requests it, commit/push all current project changes so the
   Mac/iPhone receives the same version. User handles builds/hot restart.

Automatic crew sync, order-versus-stock reconciliation, richer inventory/order
tracking, and private web testing stay queued separately. They do not block this
working version. Return to Load Calculator after this closeout.

### October 12 field-use addition: By Location

- [x] Add an optional Location / room field to Add/Edit Task with the same app
  keyboard and microphone. Accept room numbers, named areas, and combined labels
  such as Electrical room / Room 201 or Transformer yard.
- [x] Reorder and renumber the main cards: 1. Task List, 2. Job Materials,
  3. By Location, 4. By Workers, 5. Calendar & Due Dates, 6. Daily Notes.
  Keep ADD TASK above the cards. Update guide text, section-specific info-bar
  guidance, active-section accents, and references to old card numbers together.
  Locations expand to the existing task cards, using the same task
  records so edits/completion are reflected in every view.
- [x] Offer already-used locations as quick choices to reduce repeated typing
  and inconsistent naming. Group case/extra-whitespace variants together without
  guessing a location from task descriptions. Provide No location for older or
  unassigned tasks; a missing stored location defaults to empty.
- [x] Show location on Roomy task summaries and in shared material summaries
  when supplied. Keep Compact titles single-line.
- [x] Start with one location per task; optional area/room hierarchy and multiple
  locations can be added later if actual field use needs them. Reuse local storage
  and existing filters/actions; no server or chatbot is required for grouping.

### October 12 iPhone feedback — next fixes

- [x] **Multiple worker names:** investigate why dictating several names saved
  only the final name, Rogowski. Preserve the complete worker list through live
  speech updates and final results; split names on “and,” commas, or numbered
  list markers while retaining first/last names. Check whether the loss occurs
  in dictation, name parsing, saving, or the Workers display before changing it.
- [ ] **Voice measurements on iPhone:** normalize spoken measurements in task
  and material inputs consistently, including “half-inch” to `1/2"` and
  “two-inch” to `2"`. Review actual recognition output; missing recognized
  numbers must not be guessed. Keep typed measurements and ordinary prose intact.
- [ ] **Selection and clipboard controls:** make word selection consistent in
  Add Task, Edit Task, Workers, and other app input fields. Support dragging
  selection handles and add Copy/Paste (and Cut where useful) to the app keyboard;
  replacement by typing or microphone should apply to the selected text.
  Here “drag” means adjusting text selection, separate from task reordering.
- [ ] **Focused user recheck:** after the fixes, have the user try multiple
  workers, a selected-name replacement, clipboard actions, and inch measurements
  on iPhone. User performs phone checks; no installation or extra broad UI tests.

Confirmed by the user's October 12 iPhone walkthrough: Add Task microphone
starts and shows live text; word highlighting works in Edit Task; entry text
wraps; bottom content/info-bar layout is not cut off; the wide app keyboard looks
usable. This is partial acceptance, not confirmation of offline speech, clipboard
support, measurement accuracy, or saving all worker names. Prior notes below
about iPhone verification being entirely pending are historical for these paths.

This is the active closeout list. The larger ideas below remain recorded for
later; they do not need to be implemented before returning to Load Calculator.

- [ ] **First: iPhone microphone closeout.** Native connection and permission
  descriptions are implemented in source. Build on the Mac and check permissions,
  live text, stop/cancel, continuation, selected-word correction, worker names,
  material fractions, and behavior without reception on the iPhone. This is part
  of current closeout. Windows cannot compile/install the iOS build, and physical
  iPhone behavior is not yet verified.

1. [x] **Required-field warnings:** use app red, rather than pink, for error
   outlines and validation text across Job Board entry forms.
2. [x] **Small-phone spacing:** retain wide editors with modest side padding,
   safe areas, reachable actions, and scrolling for long content/keypads.
   Apply to entry and guide dialogs; physical iPhone acceptance remains pending.
3. [x] **Guide width:** make Job Board guide wider and roomier, with readable
   padding and scrollable content on small/short screens.
4. [x] **Drag feedback:** give the held task a subtle glowing outline while
   dragging so the user can tell that reordering has engaged.
5. [x] **Guide copy:** use Workers; keep the simple hold-to-drag instruction;
   remove the extra movement instructions and the assignment-message sentence.
   Replace Android-specific speech prose with “If the microphone is unavailable,
   type your entry.” Remove obsolete keyboard/platform development guidance.
6. [x] **Bottom info bar:** match the app's usual bordered instruction bar,
   pinned above the bottom safe area without covering content. Replace the plain
   duplicate guide-opening strip. Allow section-specific guidance as the current
   section changes; keep the top guide button for the full guide.
7. [x] **Install worker-name cleanup:** included in the combined closeout build
   and successfully installed on Android October 11.
   Spoken list numbers and recognition variants such as “number for” become
   comma separators. User verifies names, continuation, and highlighted-word
   corrections on the phone during the closeout walkthrough.
8. [ ] **One user closeout walkthrough:** add/edit/complete/reopen a task;
   assign multiple workers; add/edit materials; add/edit/delete linked notes;
   page/reorder tasks; check entry/guide/info-bar appearance and smaller-screen
   fit. Investigate reported failures; no extra automated UI test rounds.

Checked closeout items are implemented, awaiting the user's combined phone
review. Do not interpret responsive layout changes as verified on a physical
iPhone. Current bottom-bar guidance follows the section most recently opened.

The muted red-gray accent now follows the main section being touched/opened,
instead of permanently coloring Task List. Other sections retain the neutral
background; nested silver headers keep their accepted styling.

Already implemented in recent passes: five-task paging; single-line Compact and
Roomy rows; saved drag order; task-origin notes in the combined daily log;
expanded materials (washers, nuts, threaded rod, anchors, screws, prefab bends,
wire gauge-first/optional type, fixture identifiers); inline cursor/selection
editing; live speech previews and selection replacement; repeated dictation
continuation; inch quote/slash keys; matte silver detail headers; wide,
content-height task editor with matching lightly rounded corners. Installed
features still depend on user phone acceptance; iOS speech is implemented in
source but awaits Mac build and physical iPhone verification.

## Later ideas — preserved, outside this closeout

- Material refinements: package quantities, dedicated quick-button rename/edit,
  favorites/recents, broader box-dimension dictation, multi-item voice capture,
  and further catalog aliases as actual recognition problems are reported.
- Task conveniences: search, saved worker roster, Mine/overdue views, local
  reminders, voice task/date/status commands, quick task types and suggested
  material checklists/templates.
- Ordering/logging: combined shopping totals without losing task attribution,
  partial purchases, photos/sketches, separate jobsite boards, backup/export.
- Broader voice refinements after iPhone closeout and actual offline device
  checks; supported recognition modes depend on the phone.
- Crew clipboard: share/import work packets (box layouts, bends, cut/thread
  lists), then crew boards, permissions, offline sync/conflicts, group ordering,
  and running stock/usage balances.
- Optional AI assistance remains deferred; the local board must work without it.

Crew sharing is an app-wide direction, not limited to Job Board. Consider one
Share action for tasks/material lists, conduit bends, box layouts, measurements,
and cut/thread lists. Preserve saved results and revisions. Start by considering
explicit export/import packets without accounts; automatic crew updates are a
separate later sync phase. Initial readable Job Materials sharing is now
implemented; structured packet import and automatic updates remain pending.

### Initial Share Job Materials — implemented, phone review pending

- [x] Share button in card 2, visible only while Job Materials is expanded,
  disabled when there are no materials to share.
- [x] Confirmation/preview of current unassigned and open-task material lists,
  grouped by task, with sizes, quantities/bases, optional details, and status.
- [x] Android and iOS native text share menus. Choose the messaging/email app
  and recipient there; no app worker phone-number directory or contact access
  is required. Opening the share menu does not imply that anything was sent.
- [ ] User Android walkthrough; iOS source still needs Mac build/phone review.
- [ ] Later: structured list import/update in another app installation and
  individual task/list selection. The initial share is readable text only.

After closeout, return to [LOAD_CALCULATOR_PLAN.md](LOAD_CALCULATOR_PLAN.md).
Then decide whether to keep, simplify, or remove Power Hub Solver before doing
more solver work; its numerical review remains in [TODO.md](TODO.md).

## Product direction

A working clipboard for someone doing field work while assigning and tracking
crew work. Keep the app's black, silver, and red stacked-card format. Make voice
the quickest entry path where supported, keep touch/typing available, and keep
the core usable without reception. A chatbot must not become a dependency.

Task list is the first card. Each work item expands into its own details, dates,
materials, workers, and daily notes. Other board cards expose calendar/due dates,
materials, assignments by worker, and daily notes without duplicating task data.
User examples: lighting on level one, exit signs on level two, and extending
conduits in level five columns. Support several work items at once.

## Already implemented

- [x] Menu entry, stacked task cards, nested foldouts, help and instruction bar.
- [x] Create/edit/delete tasks; details and optional blocked reason.
- [x] Not started, in progress, blocked, and completed states. Completing moves
  the task into a collapsed completed section; it can be reopened.
- [x] Start/due/completion dates and due-today/overdue indications.
- [x] Basic flat material choices and custom entries with quantity/unit and
  needed/on-hand/purchased states. These will be streamlined below.
- [x] Worker assignment and a By worker view. Assignments currently stay local.
- [x] Dated daily notes, optionally linked to a task; edit in place, preserve
  the original date/link, and delete with Keep note/Delete note confirmation.
- [x] Front task checkbox for completion/reopening and a pencil for editing;
  the arrow expands details. Task deletion stays in its confirmed action menu.
- [x] Store entries on the phone; Job Board fields use app keyboards and direct
  microphone dictation rather than requesting the system keyboard.
- [x] Correct light-theme inheritance in cards, forms, dropdowns, and calendar;
  white button text. Twenty-eight focused board/material/voice/input/action tests pass.
- [ ] Continue user walkthrough of nested cards, touch targets, and scroll behavior.
- [x] Reset category/type selection after a successful material addition; keep
  selection on cancel. Show added materials as compact expandable rows.
- [x] Reset inner sections to collapsed when reopening a task. Use Workers,
  Materials, Details & progress, Daily notes, then Dates & completion order.
- [x] Allow several workers on each task; show it under each assigned worker.
- [x] Lighter gray inner sections, uniform slim headers, and a rectangular,
  silver-bordered Add Task button with bold uppercase lettering.
- [x] Confirmed Clear Board; keep saved material buttons by default, with an
  explicit option to clear those as well. Nothing is cleared on opening the app.

## 1. Streamline the material picker — first pass implemented

- [x] Replace the flat chip list with short category buttons: **Pipe,
  Connectors, Couplings, Straps, Wire**, and other useful groups such as
  Boxes, Lights, and Fasteners.
- [x] Tapping a category reveals compact subtype buttons inside its card.
  Pipe choices can include EMT, rigid, IMC, PVC, and flex. Connectors/couplings
  reveal their applicable types so the user can narrow the item quickly.
- [x] After choosing a material, show **Size** and **Quantity** as the main
  inputs. The selected material name is already filled; no retyping it.
  Example: Connectors → EMT → size `1/2"` → quantity `12`.
- [x] Separate material type, size, and quantity in stored data so selections,
  edits, voice entry, and shopping totals share the same fields. Preserve
  existing saved material names/quantities/units during migration.
- [x] Remove the mandatory unit field for counted items. Default a connector,
  coupling, fixture, or box to a count without asking for “each.”
- [x] Keep a compact quantity basis where it matters: pipe by sticks or feet;
  wire by feet or roll. Use sensible presets rather than a required free-text
  unit field on every item.
- [ ] Optional package mode such as **Box of 50**. Distinguish one package
  containing 50 connectors from 50 packages. Keep packaging separate from
  an electrical box as a material.
- [x] Custom material: add it to the task and offer **Save as a quick button**.
  Save remembered entries in the reusable catalog, independently of the task.
  Let the user choose a category and remove saved buttons without deleting task items.
  New custom entries now default to remembered buttons; uncheck for task-only use.
- [ ] Add dedicated editing/renaming of saved quick buttons. Currently editing a
  task material and choosing to remember it updates the matching catalog entry.
- [x] Avoid duplicate quick buttons; reuse an existing matching entry.
- [ ] Consider recent/favorite materials to reduce repeated drilling into groups.

## 2. Consistent size display

- [x] Convert common typed or keyboard-dictated sizes in inch-size fields:
  “half inch” → `1/2"`; “three-quarter inch” → `3/4"`;
  “one and a quarter inch” → `1 1/4"`.
- [x] Recognize common hyphenation, numeric fractions, and decimal-inch forms.
  Preserve the recognized size as a separate field rather than baking it into
  the material name.
- [x] Apply conversion in size context. Do not turn a quantity, wire gauge,
  model number, or unrelated daily-note text into an inch measurement.
- [x] Connect the shared formatter to dedicated material voice entry and explicit
  inch measurements in note/details fields.
- [x] Provide common size buttons as well as a custom size input.

## 3. Dedicated voice entry and offline commands

Next input pass: [JOB_BOARD_INPUT_PLAN.md](JOB_BOARD_INPUT_PLAN.md). Reuse and
adapt the app keypads, add microphones beside scoped inputs, and suppress
automatic system-keyboard opening in migrated Job Board fields.

- [x] Dedicated microphone for task capture, materials, and daily notes on Android.
  iOS native speech is now implemented in source, awaiting Mac/iPhone verification.
- [x] Android material microphone with local English parsing and an
  editable review before saving. Daily note dictation is also implemented;
  task-title/worker/details microphones are now implemented. iOS source is added;
  its build and physical phone review remain pending.
- [x] Numeric box dimensions map to editable custom entries under Boxes;
  dimensions do not become quantities. Saved sized boxes become reusable buttons.
- [ ] Refine voice box entry: broader spoken dimension forms, reversed phrasing,
  and a clearer width/height/depth and quantity review.
- [x] Microphone and keyboard icons beside material sentence/name/size/quantity
  and Daily Note fields. App-styled typing panel suppresses the system keyboard
  in these migrated inputs. Tap the recording icon again to stop, or Cancel voice.
- [x] Format explicit inch measurements in dictated notes, including
  “inch-and-a-half” → `1 1/2"`; leave unrelated counts and dates alone.
- [ ] Use on-device recognition when available; detect support and keep typing
  available. Verify behavior without reception. Keyboard dictation currently
  has no offline guarantee from the app.
- [x] Android on-device availability check, typed fallback, microphone permission,
  stop/cancel/error handling, background cleanup and capture timeout.
- [x] On older Android phones, use their speech service directly without opening
  the keyboard, with offline preferred. Routine mode/connection prose was removed.
- [x] Large material microphone starts capture in one tap, with review before Add.
- [x] Add unassigned materials from card 3, then assign/reassign them to tasks.
  Preserve type, size, quantity and purchase state when moving an entry.
- [x] Completed folder entries show checkbox and title only; reopening clears
  filters that would hide the returned task. Opening task/section scrolls it up.
- [x] Keep a local material vocabulary with categories, names, sizes, and
  aliases. It can contain more items than are initially visible as buttons.
  Touch selection and transcript matching must resolve to the same catalog.
- [ ] Parse clear patterns without a chatbot: add a task, assign a worker,
  set/change a date, add a material, change quantity, mark complete, and reopen.
- [x] Example material command: “Add twelve half-inch EMT connectors” →
  EMT connector, size `1/2"`, quantity `12`, shown for review.
- [x] If quantity is omitted (“add half-inch EMT connectors”), leave quantity
  missing and ask for it. Do not invent quantities or silently substitute types.
- [ ] Support several materials in one utterance or consecutive commands;
  show an editable list before committing it.
- [ ] Voice-update examples: “Mark garage lights complete,” “Move it to Friday,”
  “Add two couplings,” and “Waiting on fixtures.” Resolve “it” to an explicitly
  selected task or ask which task when ambiguous.
- [x] Preserve unrecognized words as draft text. Make misheard sizes, materials,
  worker names, and dates easy to correct.
- [x] Preserve full material transcript in review; unmatched material sentences
  remain editable custom drafts. Broader task/worker/date parsing is pending.
- [ ] Expand the info bar with **Try saying…** examples matched to the currently
  supported parser and the open task/material screen.

## 4. Task types and suggested material checklists

- [ ] Add quick task-type buttons as well as custom task descriptions.
  Initial candidates: Conduit run, Lighting, Exit signs, Boxes, and Wire pull.
- [ ] Recognize those task types from voice descriptions too.
- [ ] Link each type to a saved, editable material checklist. A conduit run may
  suggest pipe, connectors, couplings, straps, and anchors. A lighting task may
  additionally suggest fixtures, boxes, and wire depending on selected details.
- [ ] Show suggestions for approval; do not add duplicate materials repeatedly
  when editing a description or changing a task type.
- [ ] Ask for missing sizes, quantities, fixture types, and other necessary
  details. These are suggested checklists, not automatic complete installation
  designs or guaranteed quantities.
- [ ] Save reusable tasks/material templates for recurring work. Let personal
  templates improve the suggestions over time without internet.
- [ ] Later, consider optional AI assistance for freer language or more detailed
  draft suggestions. Show what would be sent, use a secure service connection,
  and preserve the full offline workflow. This is deferred.

## 5. Follow-through and job tracking

- [ ] Optional local reminder notifications with editable times. Current overdue
  labels are implemented; notifications are not. Avoid repeated interruptions
  simply because a task remains unfinished.
- [ ] Quick views for All, Mine, Today, overdue, blocked, and By worker.
  All/Due today/Blocked and a separate By worker card currently exist;
  “Mine” needs an explicit local identity/worker selection.
- [ ] Combine materials across open tasks into a shopping list, preserving task
  attribution. Combine only compatible material types, sizes, and quantity bases.
- [ ] Keep needed/on-hand/purchased states; later distinguish required versus
  acquired quantities if partial purchases are needed.
- [ ] Attach before/after photos, sketches, and field notes to tasks.
- [x] Improve daily logging: dictate today's work, delays, and next steps; link
  notes to tasks and allow correction of saved notes.
- [ ] Consider grouping work by jobsite/project if several separate sites need
  their own boards; current “jobs” are individual tasks in one board.
- [ ] Consider backup/export for locally stored work. Worker syncing or messaging
  is a separate later phase, captured in the shared crew workflow below.

## 6. Shared crew boards and group ordering

### Field-to-fabrication workflow — October 11 clarification

One worker measures in the field; another stays at the bender and another at
the threader. Share the bend results directly from the results screen, either
as a readable image or as a packet the recipient opens in their app. A screenshot
is useful for reference; an app-readable packet also enters a work queue and
supports progress updates. Preserve the sender's saved results rather than
recalculating them with the recipient's current settings.

- [ ] Bender/threader queues receive requests from multiple field workers.
  Include requester, job/task/location, piece ID, quantity, saved bend results
  or cut/thread instructions, and notes. Let the sender choose a destination.
- [ ] Simple work states: Requested, In progress, Ready, and Collected/delivered.
  Return an update to the requesting worker; optional delivery can be recorded
  without building a separate delivery service.
- [ ] Screenshot sharing is the quick reference route. App-readable packets
  support saved work and revisions; neither route by itself provides automatic
  crew synchronization. Explicit sharing/import comes before a live crew queue.
- [ ] Material requests can also have a readable summary/image, but send
  structured entries for the foreman to combine quantities and update lists.
  Preserve who requested each item and the task it belongs to.
- [ ] Start inventory with one designated material custodian maintaining stock,
  rather than requiring every worker to maintain a shared balance. Allow custom
  catalog items and simple receive/issue/count adjustments. Display quantities
  such as five boxes, retaining the known count per box separately; do not guess
  how many individual items an unspecified box contains.
- [ ] Foreman compares requests with available stock and existing orders before
  deciding what to buy. Requests do not automatically consume inventory.

These are preserved sharing/inventory ideas, outside the current Job Board
closeout and the return to Load Calculator.

User proposal: foreman and workers each have the app and share project/task and
material lists. Workers update their progress in the field; the shared board
shows who is working, blocked, or finished. On order day, the foreman reviews
the crew's material requests together to make purchasing decisions.

- [ ] Shared project boards with crew invitations and identifiable members.
  Support a foreman/coordinator role and worker roles; decide permissions for
  assignments, task edits, completion, material requests, and order approval.
- [ ] Exchange/share lists between foreman and workers, then provide automatic
  task/status updates across connected crew devices. Preserve task identity
  rather than copying independent tasks on every exchange.
- [ ] Show task owner/assignee, last update time, and who changed the status.
  Workers can mark assigned work in progress, blocked, or completed.
- [ ] Keep local field entry working without reception. Queue outgoing changes
  and sync when connected. Show **Saved on phone / Pending sync / Synced** so
  local completion is not mistaken for an update the whole crew has received.
- [ ] Live updates while connected; eventual updates after reconnection. Do not
  promise immediate updates across disconnected phones.
- [ ] Define conflict handling for simultaneous edits, reassignment, completion,
  and deletion. Preserve changes or surface a conflict instead of silently
  discarding a worker's offline update.
- [ ] Group material requests by project and ordering round (for example,
  **Order day**). Let workers submit drafts or revise requests before cutoff.
- [ ] Foreman's combined view: material/type, size, quantity basis, requested
  quantity, task/location, requesting worker, availability, and order state.
  Keep access to the individual requests behind each combined total.
- [ ] Normalize matching catalog items, sizes, and packaging before grouping.
  Flag possible duplicates, including the same shared task requested by two
  workers, for foreman review.
- [ ] Distinguish **duplicate demand** from **separate demand**. Two requests
  for the same task may describe the same need; identical items for separate
  tasks may need to be added together. Do not remove one solely because the
  material names match.
- [ ] Let the foreman merge duplicate requests, keep separate needs, adjust
  approved quantities, and record the decision without erasing original requests.
- [ ] Track shared available stock, quantities allocated to tasks, and existing
  orders so the same inventory is not deducted independently for every worker.
- [ ] Show requested, approved-to-buy, ordered, and received quantities separately.
  Mark requests fulfilled or partially fulfilled when material is distributed.
- [ ] Prevent retries/resubmissions from creating duplicate requests or orders.
- [ ] Later consider optional **Submit your materials** reminders, order cutoff,
  and updates when requested materials are ordered or ready for pickup.
- [ ] Select the shared storage/authentication/sync approach only when this phase
  is ready. Shared boards require data exchange; chatbot/AI access is unrelated.

This is a larger follow-on phase. Design the local catalog, task identifiers,
and material records to support it, without making the first offline board
depend on accounts or a server.

## 7. Shared stock and running inventory

### Inventory inside Job Materials — October 11 direction

Place Inventory beside Share Job Materials. Start with a useful local inventory
on the designated custodian's phone; an inert placeholder button alone is not
the intended feature. Keep stock independent of task requests/purchase labels.

- [ ] Inventory view: item/type, size, quantity basis, on-hand balance, pending
  ordered quantity, and last update. Reuse the material picker and remembered
  custom buttons. Add custom inventory items as reusable category buttons.
- [ ] Custodian actions: Receive, Issue/use, Return, and Correct count. Require a
  positive movement quantity, preserve units, and record time/reason/history.
  Only receiving changes an order into stock; ordering does not add availability.
- [ ] Requests → compiled order-day list → ordered → received. Support one or
  two weekly ordering rounds without imposing a fixed schedule. Preserve each
  requesting worker/task; review repeated requests before combining demand.
- [ ] Show stock and pending orders alongside requests to help the coordinator
  decide what remains to buy. Do not automatically subtract stock for a request,
  an order, or task completion. Reservations/allocation remain a later refinement.
- [ ] Crew distribution first: share a readable inventory snapshot to a group
  conversation or selected recipients using the phone's sharing menu. It shows
  when it was prepared and who maintains it. Current text sharing does not
  update another app's inventory.
- [ ] Next: an app-readable inventory snapshot packet with project identity,
  custodian identity, revision, and timestamp. Recipient explicitly previews and
  imports it as a read-only stock view, replacing the previous accepted snapshot
  rather than adding balances together. Reject/flag older revisions; preserve
  recipient task requests separately. Clearly show the snapshot's update time.
- [ ] Later: connected team membership and automatic inventory updates, with
  offline cached snapshots and reconnect handling. A shared endpoint is needed
  for live team updates; sending a message alone cannot silently update each app.

Proposed implementation order: local Inventory and receive/issue/history first,
then share its summary, then structured snapshot import. Crew synchronization
and broader ordering workflows stay separate from the local first pass.

### Inventory button rows and ordering view — October 11 refinement

User clarified the alternative layout as five rows of three buttons (15 items),
not five individual buttons. Full-width rows are also acceptable for the initial
phone trial. Start with alphabetical full-width rows and five items per page;
retain the three-column grid as a possible later layout adjustment, without
building both layouts before the first phone review.

- [ ] Five compact material rows per page with Previous/Next arrows, a visible
  range/count, and search/category filtering as the catalog grows. Avoid nested
  scrolling. Each row has material/type/size, a large separate count area, and
  the quantity basis (pieces, boxes, feet, etc.).
- [ ] Long-press a row/count to open Add received / Subtract issued / Correct
  count; normal tap also opens the same controls so the gesture is discoverable.
  Show the resulting balance before confirmation and record the movement.
  Holding a button must not silently change its stock count.
- [ ] Red means none available; orange means below the custodian's configured
  low-stock threshold. Include text/quantity, not color alone. A zero stock count
  is not automatically an order request: quantities needed come from demand.
- [ ] Inventory and Needed/order views use the same item identities/units while
  retaining separate on-hand counts and requested quantities. The order view
  shows requested, on hand, confirmed incoming, and suggested additional buy
  quantity. Do not combine incompatible bases or count received orders again.
- [ ] For matching units, an initial planning preview can use max(0, requested
  minus available stock minus confirmed incoming not already received), subject
  to foreman review and timing. Preserve individual worker/task requests to
  identify duplicate reports versus separate demand.
- [ ] Make rows clean enough for reference screenshots, including update time.
  Share the complete inventory/order summary across pages; a screenshot of one
  page does not represent the whole stock/request list.

### Next inventory/share pass — concrete action plan

Latest integration clarification: preserve the existing Needed / On hand /
Purchased controls and task-to-main-materials projection. A task's requested
material already appears under that task in card 3; do not create a second
request system or duplicate those entries. Inventory is a separate stock view
directly beneath Share Job Materials. Changing a request's state must not
silently alter inventory counts; receipt/issue movements remain explicit.

Before inventory implementation, tidy the shared material picker used both
inside tasks and in card 3:

- [x] Use equal-size three-column category/type/custom choice buttons, up to
  five rows (15 buttons) per choice page, with paging arrows/range when needed.
  Preserve the regular/category order and append remembered choices; do not
  alphabetize the picker. Alphabetical order applies to inventory only. Retain
  numeric ordering for measurements. This grid request applies to the picker,
  not an automatic change of the proposed full-width inventory rows.
- [x] Integrate remembered custom choices into their chosen category's normal
  button grid. Do not append a separate unbounded saved-choice chip list.
  Continue saving reusable custom buttons by default and prevent duplicates.
- [x] Card 3 capture arrangement: Share Job Materials, then a clearly titled
  Add materials area with its microphone aligned alongside the heading, category
  buttons, and Add custom material below the picker. Use the same capture layout
  inside task materials; keep icons and actions in deliberate aligned rows.
  Inventory will be inserted directly beneath Share in the next pass.
- [x] Keep added/requested entries separate from reusable catalog buttons.
  Present task additions and unassigned entries in collapsed expandable lists,
  and preserve collapsed task groups in card 3,
  so adding a custom choice does not leave a long expanded list below the picker.
  Preserve task references, editing, status controls, and all existing data.
- [x] Boxes: add familiar 4S and 5S labels/voice aliases and Deep/Shallow choices.
  Preserve physical dimensions and legacy saved box names; depth remains distinct
  from quantity. Confirm any exact dimension/depth presets before assigning them.
  Picker now shows 4S/5S families with Deep, Shallow, and Depth not specified;
  depth is preserved in the chosen material name without inventing depth inches.

Picker/layout cleanup and local inventory are implemented, awaiting phone review.
Order/receipt reconciliation and structured crew updates remain later steps.

1. [x] Add Inventory inside Job Materials beneath Add Custom Material.
   Open a separate stock view so task requests and stock counts do not mix.
2. [x] Build alphabetical full-width item rows: material, size, prominent stock
   count/unit, and status. Five items per page, arrows/range, category filter and
   search for larger lists. User reviews the layout before adding a grid mode.
3. [x] Reuse catalog/custom material buttons for Add inventory item. Store stock
   separately from BoardTask materials; preserve all existing data. Keep size,
   type, and unit distinct; separate boxes from individual items unless a known
   package conversion is explicitly supplied.
4. [x] Tap or hold to adjust: Receive, Issue, Return, Correct count. Preview the
   new balance before saving, prevent issuing more than recorded stock, and keep
   a dated movement history. Add configurable low-stock thresholds and text
   indicators alongside red empty/orange low status.
5. [ ] Add Needed / Order view using task/general material requests with Needed
   state. Show matching stock beside demand, retain task attribution, and let
   the coordinator record orders/receipts. Receiving transfers pending quantity
   to stock once; do not subtract inventory merely because a request exists.
   Unmatched units/unknown quantities require review rather than a guessed total.
6. [ ] Extend the existing native sharing flow with Share Inventory and Share
   Order List. Preview complete summaries across all pages with last-update time;
   user chooses group/person in Messages/email. Current Share Job Materials is
   already implemented and installed, awaiting user phone review.
   Share Inventory is implemented; the dedicated Order List remains pending.
7. [ ] Combined user phone walkthrough, then refine reported issues. No broad
   UI-test rounds. Mac/iPhone build checks remain pending for native integration.

First-pass inventory is maintained locally by the material custodian. Structured
snapshot import and automatic team updates remain a separate later phase; text
sharing cannot update another installation's counts. This inventory pass is now
explicitly requested; it does not authorize the larger crew-sync implementation.

Latest capture/layout refinements: microphone centered beside a short + ADD
label; Share is a boxed icon in the Job Materials header; Inventory is a full-width
button beneath Add Custom Material. Bottom instruction icon removed. Voice offers
Add to material list or Save a material button; custom review supports Save button
only with no requested quantity created. Editors are wide with side padding and
content height. Custom inventory items become reusable catalog buttons. Existing
known choices (such as threaded rod under Fasteners) are reused without duplicate
buttons. Receiving is currently an explicit stock movement with optional order
reference; it does not yet reconcile an outstanding-order ledger automatically.

Inventory phone follow-up: saved stock now appears under full-width category
foldouts in the regular category order (Pipe, Connectors, etc.), with alphabetical
entries and up to five entries per page within each category. The former All
category dropdown/flat stock list is superseded. New pipe/wire, Unistrut, and
threaded-rod stock uses feet; connectors and other counted items retain counts.
Starting count is blank with a zero hint, avoiding appending typed text to a
prefilled zero. Adjustment labels and preview include units. Existing stock
units remain unchanged until explicitly corrected; length items offer Recount
in feet with a user-entered total and a recorded history entry, resetting their
old-unit low-stock threshold. No stick-length conversion is assumed.

User proposal: workers report material used each day so the crew and foreman
can see how much remains available. Connect inventory to task material requests
and order-day decisions.

- [ ] Shared inventory per project and stock location (jobsite storage, floor,
  truck, or other named location). Use the same material/type/size catalog as
  task requests so matching items share a balance.
- [ ] Quick buttons and voice entry for **Receive**, **Use**, **Return**,
  **Transfer**, and **Count / correct stock**. Example: “Used twelve half-inch
  EMT connectors on level one today.” Show the interpreted entry for review.
- [ ] Record each movement with quantity/basis, worker, time, location, and an
  optional linked task. Maintain an activity history rather than only replacing
  a total; mistakes can be corrected with a recorded reversal or adjustment.
- [ ] Distinguish material physically **On hand**, **Reserved** for tasks, and
  **Available to allocate**. Available = on hand minus outstanding reservations.
  Example: 100 on hand, 20 reserved → 80 available to allocate.
- [ ] Receiving increases on-hand stock; use decreases it; returning unused
  material increases it. Transfers move stock between locations without
  increasing the project total. Completed purchase orders affect stock only
  when material is actually received.
- [ ] Distinguish **issued to a worker** from **used/installed** if tracking both.
  Issuing is a location/custody transfer; later consumption must not deduct the
  same quantity a second time from the project inventory.
- [ ] When reserved material is consumed, reduce on hand and release the
  matching reservation together. Do not subtract a task allocation twice.
- [ ] Normalize package/count and length bases where a conversion is known.
  One box of 50 connectors received adds 50 connectors. Do not combine feet,
  sticks, rolls, or packages without a known conversion.
- [ ] Keep task required quantities, actual use, and remaining requirements
  distinct. Completing a task must not silently assume its planned materials
  were all consumed.
- [ ] Show balance, pending updates, and last sync time. Offline usage reports
  save locally and sync later; other devices cannot know unreported usage
  immediately. Treat unsynced balances as provisional.
- [ ] Give each movement a stable identity so reconnect/retry cannot deduct
  usage twice. Reconcile concurrent entries and flag insufficient/negative
  balances or conflicting stock counts for review rather than hiding them.
- [ ] Let the foreman review discrepancies, record physical counts, and adjust
  stock with a reason. Decide which stock actions workers can perform.
- [ ] Optional low-stock thresholds and replenishment suggestions in Order day.
  Show existing stock, reservations, and incoming orders alongside new requests.

Start with counted materials such as connectors, couplings, straps, and boxes.
Add pipe/wire lengths and packaging conversions after the count workflow works.
Inventory is proposed; the current task-level Needed/On hand/Purchased labels
do not yet maintain shared stock quantities.

## 8. Shareable work packets — the crew clipboard

User proposal: share more than Job Board tasks/materials. One person prepares
layouts or fabrication instructions, others collect measurements or execute
the work, and packets go to the appropriate worker (bender, threader, etc.).

- [ ] Define a reusable work-packet format for task instructions/materials,
  conduit bend results, box layouts, measurement records, and pipe cut/thread lists.
  Include a packet ID, project/task link, author, recipient/assignment, revision,
  time, units, relevant settings and enough captured inputs/results to understand
  the work. Preserve numerical precision rather than relying on display strings.
- [ ] Export/import a packet as a file both copies of the app understand, using
  supported phone sharing channels. Sharing work data does not require sending
  the app itself or its source files. Recipients need a compatible app version.
- [ ] Let recipients preview a packet before importing; explain unsupported
  packet versions, missing fields, and any recalculation needs clearly.
- [ ] Distinguish a shared snapshot from a live board. Files do not automatically
  update the sender when a recipient edits or completes them; return updates
  explicitly until a shared sync service exists.
- [ ] Provide a readable PDF/image alternative for instructions when useful,
  alongside editable app data. Those exports do not imply a live synced record.
- [ ] Measurement workflow: requested measurement/location → collected values
  with labels/units and optional photos → review → layout/fabrication packet.
- [ ] Box-layout packets: dimensions, reference edges/orientation, hole positions,
  labels, quantities, and captured layout results for assigned workers.
- [ ] Conduit-bend packets: conduit type/size, bender/settings, bend sequence,
  reference end/orientation, marks and captured results, quantity, and notes.
  Do not silently reinterpret saved results using different recipient settings.
- [ ] Cut/thread packets: pipe IDs, type/size, quantities, finished lengths,
  threading/end treatment, reference convention/allowances, and destination.
  Distinguish finished length from cut length where the workflow requires it.
- [ ] Crew status: received, needs clarification, in progress, fabricated,
  installed/complete, as applicable. Record who acknowledged and which revision
  they worked from. Do not equate sending with successful receipt.
- [ ] Handle packet revisions, duplicate imports, replacements, and withdrawn
  instructions. Make changed dimensions/marks visible for recipient review.
- [ ] Later integrate packets into shared crew boards: assigned work appears
  automatically, progress syncs, and measurements/results remain task-linked.

Architecture choices: manual file exchange can work without our own server;
the chosen delivery channel determines whether reception is needed. An automatic
shared board needs a shared sync endpoint (hosted backend or reachable local
server/device), membership/access control, and reconnect/conflict handling.
Nearby peer-to-peer exchange is an optional later path, not a guarantee that
remote/disconnected crews can keep identical live boards.

Consider snapshot export/import before full crew sync to prove the clipboard
workflow. Specific packet schemas and platform sharing support remain to be
designed. Readable material-list sharing is implemented; work-packet file
exchange/import is not yet implemented.

## Delivery order after this closeout

1. Finish the current closeout checklist and user phone review.
2. Return to Load Calculator; decide Power Hub Solver's future.
3. Revisit Job Board conveniences/material refinements only when selected.
4. Work-packet sharing, crew sync/ordering, and inventory are separate later phases.

Optional bridge before phase 6: work-packet export/import to test sharing actual
field instructions without requiring shared accounts or a sync backend.

For each pass, keep the existing saved entries, verify the relevant workflow,
and use the user's phone walkthrough to adjust the card format.

Latest walkthrough adjustments: five main cards start collapsed; compact task
section headers have a silver finish, black lettering and thin red borders.
Reusable fitting buttons show only the type inside their chosen category
(Couplings → Liquid-tight), with inch size kept separate on task entries.
Saved box dimensions and wire gauges are preserved.

## October 12 implementation update

- Locations and six-card order implemented in Dart. Missing stored locations
  remain empty; No location groups older tasks. Used locations are quick choices
  in Add/Edit Task, and case/whitespace variants group together.
- 4S/5S box quantity forms retain familiar box/depth headings, omit the optional
  size field, and omit Save button only for existing catalog choices. Junction
  boxes still allow a size because their dimensions are not fixed.
- Task-name voice input now uses the narrative measurement formatter, including
  spelled whole-number inches. Workers fields wrap to show the entire entry and
  worker separators are normalized again when saving. Lost-name dictation cause
  remains pending; these changes do not establish that the reported loss is fixed.
- User handles hot reload/restart and phone acceptance. No device installation.

## October 12 follow-up: expanded width and continuing worker dictation

Expanded task-detail borders now use the outer task's silver color; closing a
section restores its red border and silver header. App keyboards now include
Select all, Cut, Copy, and Paste controls, including numeric/inch keypads and
standalone typing dialogs. Copy/Cut use selected text; Paste replaces a selection
or inserts at the cursor. Existing native drag handles remain; consistent phone
selection behavior and repeated worker dictation still await user acceptance.

Task accordion follow-up: within each task, opening Location, Workers,
Materials, Details & progress, Daily Notes, or Dates & completion closes the
previously open detail section. Opening still scrolls that section to the top;
manually closing the active detail section returns to the task title after the
collapse settles. Switching sections does not trigger the return scroll. Each
task/view owns its controllers, and closing the task resets its detail sections.
Home-screen sections retain independent expansion. User phone review pending.

Bulk location entry supersedes the initial one-location Add flow: ADD LOCATION
opens a wrapping Locations input with comma coaching and Done. Typed commas,
spoken “comma,” semicolons, and line breaks separate locations; numbers within
room names are preserved, empty entries ignored, and case/whitespace duplicates
skipped. All locations save together; no assignment dialog interrupts this flow.
Assign tasks afterward from each home-screen location card or the task dropdown.

Home-screen section follow-up: Share Job Materials is visible only while that
section is expanded. Home-screen By Location has ADD LOCATION with voice/app
keyboard, stores locations independently of task assignments, and offers an
Assign tasks checklist per location. Task editors offer a saved-location dropdown
alongside typed/voiced location entry. Unchecking an assigned task in the location
checklist clears its location; selecting a task moves it to the chosen location.
Existing task locations seed the saved choices; Clear Board clears saved locations.
Distinguish home-screen By Location from the Location card inside a task.
Phone review pending; materials continue to inherit location through their task.

Material removal feedback: replaced the immediate X action with a trash icon
and Keep/Remove confirmation. Retain Undo for eight seconds and use readable
dark snackbar styling. Material row/removal labels use 4S/5S Shallow/Deep while
preserving existing stored identities. User confirmed 5S Deep selection goes
directly to quantity; removal screenshot showed the old unconfirmed action.

Material/location connection follow-up: task details now include a Location card
with Assign / change location opening Add/Edit Task. Expanded material entries
show their task and location, plus a labeled Assign to task / Move to another task
action. The task chooser includes the task's location and supports moving back to
Unassigned materials. Materials keep one task owner; location follows that task
rather than being separately duplicated on each material. User phone review pending.

- [x] Closed task-detail sections remain inset; expanding Workers, Materials,
  Details, Daily Notes, or Dates takes the task card's full internal width.
  Closing restores the inset width; safe outer page margins remain intact.
- [x] Follow live voice previews as wrapped input grows, rather than waiting
  for the final result to scroll. Worker inputs already wrap without a line cap.
- [x] Keep a received speech preview if recognition fails to finalize, instead
  of silently restoring the previous draft. Repeated recordings continue from
  the original field contents unless text is selected for replacement.
- [ ] User check: record a long worker list, stop, then record another name with
  no text highlighted. Verify earlier names stay present and the entry follows
  the text. Also check replacing a selected name. The precise cause of the
  reported loss is not yet proven; investigate any remaining phone failure.
