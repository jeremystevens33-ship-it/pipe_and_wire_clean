# Job Board — first layout pass, October 9, 2026

Entry: Menu → Tools & Reference → Job Board.

Master feature/idea list: [JOB_BOARD_PLAN.md](JOB_BOARD_PLAN.md). Use that list
for subsequent Job Board work; this file records the implementation handoff.

The user wants a working clipboard in the app's black/silver/red stacked-card
style. Task list is card 1; each task expands into Workers, Materials, Details &
progress, Daily notes, then Dates & completion. Other board cards show Calendar &
due dates, Job materials by task, By worker, and Daily notes.

Implemented: local persistence under shared_preferences key `job_board_v1`,
task creation/editing/deletion, status and completion date, editable start/due
dates, overdue/due-today flags, material catalog/custom entries with quantity,
unit and availability, worker assignment, daily notes linked to tasks, guide and
instruction bar. Completed tasks move into a collapsed section and can reopen.
Example tasks load only on explicit button tap on an empty board.

This pass is for trying the layout. Text fields can use keyboard dictation if
available. A first dedicated Android offline material microphone and English
material-command parser are now implemented; keyboard dictation's offline
availability still depends on the keyboard/device. No notification
reminders, photos, AI service, crew messaging/sync, material-template inference,
or combined quantity totals are implemented. The calendar is a dated list.

Material picker pass: category buttons fold out into subtype choices. Preselected
items need only size and quantity; counted items omit the unit field. Pipe/wire
offer sticks/feet/rolls as applicable. Custom entries can be saved as reusable
buttons, categorized, and removed without deleting task materials. Saved buttons
live in `materialButtons` beside tasks/daily notes under the existing storage key.
New material records store category, size, and sizeKind separately; legacy names,
quantities, states and arbitrary units are preserved without destructive parsing.
Common typed/dictated inch phrases and decimals normalize in inch-size fields;
wire gauges and free-text descriptors do not get inch marks. Packaging is pending.

Clutter/crew pass: successful material additions reset category/subtype choices;
cancelling keeps the selection. Added materials are compact foldout rows with
edit/remove and availability controls hidden until expanded. Closing/reopening a
task resets its inner sections to collapsed. Several workers can be entered with
commas/semicolons/newlines; existing singular worker storage remains compatible,
and each worker sees the task in By worker.

Latest phone feedback pass: inner task sections have lighter gray backgrounds,
neutral icons, and uniform 52-pixel single-line headers. Assignment names and
material details stay inside the sections. Add Task uses a silver-bordered,
12-pixel-corner rectangular button with bold uppercase text. Clear Board is an
app-bar action with explicit confirmation; it removes tasks/materials/daily notes,
keeps saved buttons by default, and optionally removes them too.

Custom materials now default to saving a reusable button in the selected category
(the user can uncheck this). Numeric box-dimension sentences such as “8 by 8 box,”
“12 x 12 box,” or “two 8 by 8 by 4 boxes” create editable custom drafts under Boxes,
without treating dimensions as quantity. These become reusable Boxes buttons on
Add. Existing custom entries are not retroactively added to the catalog; edit and
choose Save as a quick button to remember them.

Voice flow: Materials → large microphone (automatic capture) → Review → Add.
Android native channel `pipe_and_wire/offline_speech` prefers
createOnDeviceSpeechRecognizer on supported Android 12+ devices. Otherwise,
with the user's October 10 authorization, use the phone's recognition service
via createSpeechRecognizer and EXTRA_PREFER_OFFLINE. This can use a connection:
the preference is service-dependent, so the UI displays the mode explicitly.
Both paths request mic permission and handle stop, cancel, backgrounding,
errors and a 20-second timeout. Unsupported devices/platforms keep app typing;
iOS native integration remains pending. English language support/downloads must
already be available. No new plugin dependency was introduced.

First grammar: one material per sentence, explicit catalog type, common inch
sizes, numeric/English counts, and feet/rolls where applicable. Example: “Add
twelve half-inch EMT connectors.” Catalog/custom names are matched locally;
missing quantities stay blank, unrecognized/multiple materials retain the full
sentence for manual correction. Original transcript appears in the editable
material review. Task commands and multi-material sentences remain pending.

Next: user walkthrough of quieter foldouts, multiple workers, microphone
permission/stop/cancel, recognition accuracy and airplane-mode use. A full Android
rebuild/restart is needed for native microphone changes; hot reload is insufficient.
See the master feature list for remaining work.

Contrast fix: nested cards use the board theme rather than the root app's light
theme. Dialog routes and date picker explicitly receive the board theme; filled
buttons have white foreground text on red. Keep this isolation when adding forms.

Validation: focused Job Board/material picker/voice/polish/input/action tests pass (28 tests), including
catalog entry at 360×800, quantity validation, custom-button persistence/removal,
legacy material loading, size formatting, pipe quantity basis and wire gauge
preservation, picker reset, collapsed material controls and task reopening,
multiple-worker serialization, parser cases and mocked supported/unsupported
voice preview flows (no save before review confirmation). They also cover readable text on
buttons, cards, forms, dropdowns and calendar inside a light parent app; all nested
foldouts at 360×800, completion/reopening, reload persistence, and task/material
serialization. The current analyzer result is recorded below. User has reviewed the initial board and contrast fix; walkthrough of the
material picker led to the latest style/reset/custom-box fixes. New checks cover
matching header heights, reset cancellation/confirmation and optional catalog
removal, box-dimension parsing and reuse under Boxes. Android build succeeded in
the voice pass; the current pass changes only Flutter code.

Latest appearance pass: all five numbered board cards start closed. Nested task
headers use a silver gradient, black titles, red icons and thin red borders;
expanded forms retain dark Material surfaces so text and tap feedback remain
readable. Header heights remain consistent. Phone visual review is pending.

Couplings/Connectors/Straps/Pipe quick labels omit the repeated category noun
and leading inch size. For example, a saved “half-inch liquid-tight couplings”
button displays “Liquid-tight” under Couplings. New entries separate that size
into the task material's size field and save the reusable generic type; explicit
size-field input takes precedence. Existing saved buttons display clean labels
without deleting task data. Reusing a button starts with a fresh size choice.
Box dimensions and wire gauges remain part of their respective descriptions.

October 10 input pass: job_input_field.dart supplies field-scoped microphone and
keyboard icons. Material sentence, custom name, size, quantity and Daily Note
use it; task/edit-worker forms still use their previous input controls. Migrated
fields request TextInputType.none and app typing opens a responsive draft editor
with a keypad styled like the existing app keypads. Done applies text; Cancel
typing preserves the original. Supports selection replacement, cursor edits,
backspace, shift, punctuation, numbers and fractional size keys. Calculator
keypads are unchanged. Native recognition is reused; one field recording at a
time, second tap stops, Cancel voice/dispose discards late results. Review/Add
and Save note persist separately. No partial/live transcript or pause/resume
is implemented. Inch-and-a-half phrases normalize to fractions, including explicit
measurements in notes; unknown quantities stay editable rather than guessed.

New tests cover mocked stop/cancel, late results, fractional parsing, note
draft/save/task linking, typing selection/cancel at 320×568, and reachable typing
actions at 568×320 with 1.5× text. Real microphone and airplane-mode review remains
pending on supported Android hardware.

Final input-pass verification: all 22 focused tests pass; Dart analysis of the
updated input/screen/catalog/dialog code and voice/input tests reports no issues.
This pass changes Flutter code only and does not introduce new native APIs.

Latest action pass: task headers replace the decorative clipboard with an
accessible completion checkbox and add an editing pencil. The arrow/title still
expands details. Remove the duplicate inner Completed checkbox/label; retain
Edit task, Complete/Reopen task and confirmed Delete task in the expanded menu.
Daily notes have outlined pencil/trash actions in both task and board views.
Editing preserves original date and selected task link unless the user changes
the link; cancellation leaves the entry unchanged. Delete confirms Keep note /
Delete note and removes that exact entry, preserving duplicate-text notes.
ADD DAILY NOTE matches the rectangular dark, silver-bordered ADD TASK style.

All 22 existing focused tests and both new action tests pass. New compact-phone
checks cover direct title edit, completion/reopening without expansion, cancelled
note edit/delete, exact note removal, original date/link retention and persistence
after reload. Analysis of the updated screen and action/input tests is clean.

Latest phone review (2026-10-10): the Moto g stylus runs Android 11 and has
GoogleRecognitionService enabled. The app uses that service without opening the
Android keyboard. Permission succeeded, but the user reported a language error
from the offline English request. Native recognition now retries that error once
using the phone service's default language with offline preference disabled.
Callbacks from the discarded recognizer are ignored; cancellation also prevents
the delayed retry from starting. This fallback may need reception. Real speech
recognition remains a phone test, not a claim established by mocked Flutter tests.

ADD TASK is red with white bold lettering and a silver border; outer task cards
stay charcoal. Only inner section headers use the darker silver gradient and
black lettering. General Job Materials can be entered before choosing a task,
then assigned without copying; completed entries show their checkbox and title.
All 28 focused Flutter tests pass and analysis is clean for the five Job Board
source files.

Next field review: user confirmed app microphone dictation works on the Moto,
including inch fraction formatting. Keep the native service fallback unchanged.
Task creation/edit and other shared task forms now use JobInputField microphone
and app typing controls instead of requesting the Android keyboard. Task List
has a muted red accent/background to distinguish its expanded container from
individual tasks. Inner section headers retain their darker silver treatment.

Typing keys have a 56 logical-pixel minimum height, 20-point labels (scaled down
only to fit narrow keys), and a 22-point entry preview. Slash replaces comma in
the main punctuation row; comma remains alongside Space for worker names/notes.
Size-specific numeric/fraction typing remains available. Scrollable keyboard
content keeps Cancel/Done pinned and reachable on short screens.

Connector/coupling picker adds family then subtype selection: EMT set screw or
compression; rigid connectors Myers hub/three-piece; rigid couplings standard or
three-piece. Type not specified retains generic legacy EMT/rigid connector
entries. Liquid-tight is included in both categories. Strut clamp quick choice
is renamed Strut strap; existing saved material names remain untouched. Speech
matching shares these catalog entries and accepts hyphenated subtype names.
Validation: all 32 focused tests pass, including 320×568 fraction typing,
task-title voice entry, fitting subtype selection/reset, and spoken subtype
matching with size/count retained separately.

User preference going forward: keep routine visual changes streamlined; build
and install, then let the user open and test the phone app. Avoid broad test
reruns for simple styling/layout edits. Latest layout adjustment puts EMT and
Rigid in their own first fitting row, then PVC/Flex/Liquid-tight below; narrow
screens may wrap that second row. Material microphone gets 16 logical pixels
of extra space above it. Voice behavior stays unchanged.

Unistrut field feedback: material voice matching normalizes Unistretch,
unistrretch, uni strut, and unit strut to Unistrut. Catalog has Supports →
Unistrut (sticks/feet) separately from Straps → Unistrut. Bare spoken or typed
fractions such as three-quarter / 3/4 are extracted before quantities, so an
inch-sized strap retains its size even without the word inch. Whole numbers
remain counts. One focused voice test file passed (5 tests); user continues
hands-on phone testing. This corrects returned transcripts, not the recognizer's
acoustic model; unseen mishearings can still require review.

Strut strap refinement: Straps → Strut straps expands Thin wall (T.W.) for EMT
and Standard (STD.) for rigid, plus Type not specified. Voice accepts TW/T.W.,
STD/STD., thin wall/standard, and EMT/rigid strut strap phrases with the same
mapping. Generic Unistrut/strut straps remain unspecified rather than guessing
which type was requested. The focused voice file passes all six tests.
Final label correction: buttons say exactly T.W. and STD, with the thin-wall
EMT versus standard rigid mapping explained above them. Voice still accepts
either dotted or undotted abbreviations.

PVC/purchased bend pass: Connectors → PVC expands MA (male adapter), FA
(female adapter), and Type not specified. EMT/Rigid keep the first connector
row; PVC/Flex/Liquid-tight remain below. New Prefab bends category expands
EMT/Rigid/PVC then 10°, 15°, 22.5°, 30°, 45°, 90°, followed by the existing
inch size/quantity form. Other diameters can be typed. These are request-list
choices; supplier availability is not inferred. Saved older entries remain.

Voice accepts MA/FA and full adapter names, prefab 90s, bend/elbow/kick wording,
angle before or after conduit type, and supported spoken degree values. Angles
are separated before quantity/size parsing, and bend/adapter descriptions do
not fall back to straight pipe. Plain spoken two-/six-inch conduit sizes are
recognized. The focused voice file passes seven tests; no broad test rerun.

Worker/support field pass: worker microphones append rather than replace the
list, format spoken and/number-two separators, and send a worker-only 3000ms
pause request to Android. Native worker timeout is 45s; other fields remain
20s. Recognition services may ignore pause hints; restarting the worker mic
retains existing names. Hands-on verification of pause timing is pending.

Supports → Unistrut reveals 7/8" and 1 5/8" buttons inline, then opens quantity
with the chosen size displayed and feet as the new-entry default. Existing
materials keep their saved units. Quantity speech separates supported trailing
units (feet/foot/ft, sticks, rolls, each) from the number and updates the basis.
Two focused feedback tests pass. JOB_BOARD_FEEDBACK.md keeps the latest short
list and suggestions for a worker roster and clearer quantity-unit labels.

Daily-note direction: add a note from inside a task with automatic task linkage;
section 5 aggregates these with general notes. The editor appends another
dictation paragraph, offers Clear without closing, and requests the longer
worker pause allowance (with the same phone-service timing limitation). Clear
cancels the active recording before erasing its draft, and generation guards
discard any late result. Existing saved notes remain until Save/Edit/Delete.
Two targeted daily-note checks pass: append/clear/late-result handling and
task-origin note persistence plus appearance in section 5.

## October 10 material pass

Fasteners now include Flat/Fender/Square washers, nuts and threaded rod, with quick diameter/thread buttons and custom sizes. Optional materialType, length, and specification fields persist on JobMaterial and round-trip through editing. Washer specification is outside diameter; other fasteners use thread/specification. Threaded rod defaults to feet, with sticks available. Wire picker starts with gauge (Standard/Large); type is optional on the entry screen with custom type support. Fixtures have separate name/type and physical size/length. Prefab bends hide the free size field until Custom size. Material quantity and measurement fields reuse the app keypad inline, with a single active keypad. Voice grammar adds all-thread, washer/nut plurals, spoken eighths, explicit gauge notation, and screw threads. Native voice is unchanged. Four focused material tests and the existing seven voice tests passed. Build/install status is recorded in the chat; user opens the app manually.

## October 11 task list pass

Main page uses CustomScrollView with a SliverReorderableList in the Task list card, giving native edge auto-scrolling through one scroll surface. ReorderableDelayedDragStartListener supplies press-and-hold. Manual order is the saved tasks array; due-date sorting is isolated to calendar. Filtered moves rearrange only matching tasks in their existing slots. Compact/Roomy adjusts closed rows and persists compactTasks with a true default for older data. Details use existing ExpansionTiles, and completion retains the existing folder/reopen behavior. Opening Task list scrolls its keyed header into view. Initial focused checks found drag target assumptions and small-screen visibility issues; phone testing is pending after the header correction. User requested no repeated behavior tests; prioritize phone feedback, necessary build/install only, retain app data and do not launch.

## October 11 paging revision

User found whole-page scrolling unsuitable for task navigation. Task list now pages at five matching tasks using Previous/Next arrows and a range count. Compact headers use one line with ellipsis, checkbox and dropdown only (no subtitle/front edit icon); edit remains in expanded Task actions. Drag reorders within the current page. Up/down/top/bottom menu actions reorder matching tasks across pages and select the destination page. Filters reset paging; new and reopened tasks select their page; list shrink clamps page bounds. Roomy also pages. Expanded content retains the main page scrolling. No automated behavior reruns per user preference; earlier drag/edge-scroll tests need revision to reflect paging. Phone verification is pending after build/install.

## October 11 shared editor polish

JobInputField owns/disposes FocusNode and text ScrollController. Voice results focus the field, set end selection, and scroll to its text extent. Inline tap opens the app keypad only when closed, preserving taps for caret positioning. The modal preview is now editable with TextInputType.none, autofocus, visible cursor, and interactive word selection. Custom key InkWells cannot take focus; keys refocus the text and replace the selected range. Done transfers draft.value including selection. Typing routes explicitly retain the source theme. Board dialog/button themes use small corner radii and silver outlines. Paging arrows now sit beside Compact/Roomy, with a count beneath. User tests gestures/layout on the phone; no automated behavior runs this pass.

## Approved October 11 layout/selection pass

JobInputField.maxLines is nullable; Task name uses null for automatic vertical growth. inlineKeyboard defaults true across shared Job Board inputs; alphabetic inline keys now include comma/newline. Both inline fields and the optional modal editor override contextMenuBuilder with an empty widget, while retaining interactive selection; app key presses remove any existing ContextMenuController overlay. clearSignal optionally listens for safe clear requests and is detached on update/dispose. Daily-note footer uses clearSignal with three equal Expanded actions in a fixed-height row; Clear still cancels speech/generation before clearing. Task filters and view/page controls form a two-row, three-column grid of uniform-height outlined buttons. Earlier UI tests assume old modal/chip interfaces and need updating only when useful; user requested phone behavior verification and minimal automated checks. Build/install pending in chat.

## October 11 full-screen task entry

Shared task _form uses Dialog.fullscreen with SafeArea, title, Expanded scrollable Form, 4px horizontal padding, and pinned equal-width Cancel/Save actions. Inline keyboards gain the full usable width without moving edits into another field. Build/install only; user tests typing comfort.

## October 11 continued task dictation

Add/Edit Task microphones append to existing drafts: spaces for task names and details, commas for workers. Task names and Details / blocked reason both wrap and grow without a line limit. The full-width editor has a silver outer frame and silver input outlines. Build/install only; user verifies repeated microphone sessions on the phone.

## October 11 live speech and editor refinement

Native speech requests partial results and sends them to the active JobInputField. Each preview/final result uses the original draft and selection, preventing duplicate partial text and replacing highlighted words while preserving surrounding text. Unselected append fields continue their draft. The keyboard punctuation row includes period, slash, inch quote, dash. Voice-mode status prose is removed; workers hint is numbered 1, 2, 3 with wrapping. Task editor stays full width, uses content height constrained by the screen, and has a silver frame with rounder upper corners. Build/install only; user checks recognition and layout on the phone.

Worker dictation cleanup also removes standalone list numbers/ordinals and explicit labels misrecognized with homophones (such as “number for”), yielding comma-separated names on both partial and final results. Task editor top and bottom corners now share the same 8px radius.

## October 11 iPhone microphone source

AppDelegate.swift registers JobSpeechBridge using the existing pipe_and_wire/offline_speech MethodChannel. It uses SFSpeechRecognizer (en-US), AVAudioEngine, live partial callbacks, on-device requests when supported, speech/microphone permissions, session-token guards, silence/audio-activity timing, a 45-second cap, stop/final-result grace period, and cancel/background/interruption cleanup. Info.plist includes both usage descriptions. The shared Flutter fields retain material formatting, append behavior, selected-word replacement, and keyboards. No new package or Xcode file registration is needed; the bridge is in the existing compiled AppDelegate file. Windows cannot compile Swift against iOS or install an iPhone build: Mac build and physical phone verification are still required. No Android rebuild/install this pass; worker-name cleanup's previous Android install was declined.

Planner now puts iPhone verification first in current closeout. App-wide crew sharing (bends, layouts, cut/thread lists, tasks/materials) remains captured as a separate later phase; no sharing code was added.

The same pass subsequently includes the six UI closeout fixes: Job Board's color scheme uses app red for errors; the task editor has 6px horizontal dialog padding; guide uses a wide scrollable content box and simplified platform-neutral wording; dragged task proxies have a silver outline/glow; the pinned SafeArea bottom bar matches Load Calculator's silver-bordered instruction-card treatment and follows the most recently opened section. The former bottom shortcut to the guide is removed. Combined Android build/install supersedes the earlier no-rebuild note above; physical iPhone build/voice/layout acceptance remains pending on the Mac.

Combined Android debug build passed and adb install -r succeeded on ZY22D52PPM, including the worker-name cleanup. App was not launched; user performs the walkthrough. iOS permission plist parsed successfully; Swift/iOS compilation is not available on this Windows host.

## October 11 initial material sharing

lib/app_share.dart exposes a reusable pipe_and_wire/share MethodChannel. Android uses ACTION_SEND text/plain and the system chooser; iOS uses UIActivityViewController with an iPad popover anchor. Job Materials card adds a disabled-when-empty Share button, wide scrollable confirmation preview, and native sheet after confirmation. The snapshot includes unassigned materials and open-task materials grouped by task, preserving quantity basis, size, optional type/length/specification, and state; it does not aggregate compatible items or include completed-task material lists. The user chooses app and recipient in the native menu. No contact permission, automatic sending, accounts, structured import, synchronization, or delivery claim is added. Android build/install follows; iOS still needs Mac compilation and phone verification.

Share build passed after correcting FilledButton.icon's label argument, and adb install -r succeeded on ZY22D52PPM. App not launched and no list sent; user tests the preview/native share menu. iOS compilation remains pending on the Mac.

## Material picker integration — first inventory preparation step

User corrected ordering: picker keeps existing category/type order; only inventory should be alphabetical. New job_material_buttons.dart provides three equal-width columns, label-aware uniform page button heights, up to 15 choices/five rows per page, arrows/range above that count, small corners/silver outlines, and accessible text scaling. MaterialCategoryPicker reuses it for categories, families, variants, wire gauges, sizes, and remembered custom choices. Saved buttons join their category's normal grid; hold invokes the existing one-confirmation remove flow and preserves task entries. The shared task/general capture layout puts a microphone beside ADD MATERIALS and ADD CUSTOM MATERIAL below the picker. Task quantities and unassigned quantities now live in collapsed foldouts; card 3 preserves task-grouped requests. Needed/On hand/Purchased, saved data, custom catalog storage, and Share remain intact. Inventory and 4S/5S/depth additions remain pending; no placeholder Inventory button was added. Build/install and user review follow; no extra UI tests.

Final picker build passed and adb install -r succeeded on ZY22D52PPM. App not launched; user checks layout and paging on the phone. No iOS build performed on Windows.

## Local Inventory and clarified material capture

job_inventory.dart stores independent inventory under the existing board snapshot's optional inventory key. Old records default to an empty inventory. Alphabetical five-item pages, app-input search, category filter, shared material picker, starting counts (including zero), each/boxes/feet/sticks/rolls, Receive/Issue/Return/Correct count, low-stock threshold, red Empty/orange Low labels, history, and complete-list text sharing are implemented. Whole counts are required except feet, nonfinite/negative quantities are rejected, and Issue cannot exceed stock. Explicit receive/issue movements preserve task material labels; no automatic stock deduction, package conversion, pending-order ledger, reservations, or crew sync. Clear Board retains stock. Custom inventory items are remembered catalog choices. Header share icon and centered microphone replace the former top Share button/right microphone; Inventory appears beneath custom add. Bottom instruction icon removed. Voice draft carries buttonOnly; voice offers request or button creation, and MaterialEntryDialog can save a reusable button without creating an unassigned/task entry. It uses a wide padded editor and common fitting/support/fastener size choices. Known catalog identities are reused. Android build passed; installation/user walkthrough follows.

Final Android build and adb install -r succeeded on ZY22D52PPM. App not launched; saved lists retained. User checks inventory/voice/catalog/layout on phone; iOS build still requires the Mac.

## Inventory units/category follow-up

Starting count no longer preloads zero (blank can save zero). New Pipe/Wire, Supports Unistrut, and Fasteners threaded rod/all-thread default to feet; saved unit labels are preserved. Quantity labels and previews include the unit; selected size is labeled explicitly. Recount in feet is offered for existing length items with other units: the user enters the actual feet total, the old unit is retained in history, and old-unit low threshold resets. No automatic sticks-to-feet conversion. The saved inventory view now shows full-width regular-category foldouts, alphabetical stock rows within each category, separate five-item page controls, unit beside the count, and search that opens matching categories. The All dropdown and flat global pagination are superseded. Existing inventory/task data retained. Build/install follows; no extra UI test runs.

Final grouped-inventory build passed, but its adb installation was declined. This update is built and not yet installed; the phone retains the prior inventory version.

Workflow preference after this build: user handles hot reload/hot restart and phone installation. Do not run adb install or prompt for installation unless explicitly requested again. Keep checks focused and avoid rebuilding APKs for routine Dart-only tweaks when the user is running the app. Native Android/iOS changes need a platform rebuild; iOS speech/sharing still need Mac build and actual iPhone acceptance. Do not infer the current phone version from the declined install, since the user may reload/restart independently.

## Night closeout: boxes and full project GitHub transfer

Boxes now have 4S/5S picker families, each with Deep/Shallow/Depth not specified. Existing generic square-box names remain unchanged for saved-record compatibility; new depth variants carry depth in their material name. Voice recognizes 4S/5S (including spoken four/five S) with deep/shallow wording. No precise depth dimensions are guessed. User requested commit/push of all current project changes, not just Job Board. After pulling master on the Mac, do a full iOS rebuild for AppDelegate/Info.plist native speech/sharing changes, then verify iPhone permissions, microphone behavior, sharing, safe areas, and inventory. Android installation remains user-managed.

Late visual request: main-section red-gray accent now follows pointer interaction with section 2–5 cards or task cards, and Task List opening activates section 1. Only the active main section gets the muted red gradient/red outline; nested silver headers stay the same. Focused analysis of board/catalog/voice found no errors or warnings; nine existing/new style/deprecation informational notes remain (no UI test run or APK/install). GitHub fetch was declined; push can proceed normally without force and will reject if the remote has conflicting new commits.
