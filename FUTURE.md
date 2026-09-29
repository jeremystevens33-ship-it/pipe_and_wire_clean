# Pipe & Wire — future features

Recorded 2026-09-23. Ideas for later versions, not current release requirements.
Use TODO.md for current general tasks and RACK_BUILDER_TODO.md for the existing
finish checklist. No implementation or pricing decisions made here.

## 1. Lighting Layout / Reflected Ceiling Plan (working title)

- Enter room dimensions, initially a rectangle such as 20 ft × 15 ft.
- Plot lights, fire-alarm devices and other devices on an adjustable grid.
- Locate devices by measured X/Y distances from a defined origin and useful
  grid references. The user's A-15/C-10 example expresses the desired alternate
  addressing; decide the actual notation and conversion before implementation.
- Support separate room sections, each with its own device count: for example,
  six lights in the main rectangle and five in a smaller section.
- Automatically distribute a chosen number evenly in a selected section, then
  allow manual position adjustments.
- Clarify units (feet/inches), grid interval, wall margins, row/column choices,
  and equal spacing between devices versus equal margins before building.
- Placement aid only at this idea stage; no automatic lighting-performance or
  fire-alarm code-compliance claim has been specified.

## 2. Underground

- Choose conduit sizes and quantities, including mixed sizes such as three
  2-inch conduits and four 4-inch conduits.
- Arrange and stack conduits into a duct-bank cross-section.
- Enter run length and calculate concrete volume for the bank.
- Define conduit outside diameters, spacing, concrete cover and overall envelope;
  confirm whether the estimate subtracts conduit displacement and how any waste
  allowance is displayed. Report concrete (the user called it cement) quantities.
- Start with a straight, constant cross-section; agree scope for bends or changing
  sections later. Do not assume engineering/code spacing requirements.

## 3. Quick Regular 90

- A simple standalone single-90 screen for quick gain and pre-cut length work.
- Minimize entry and manual arithmetic; agree the input references and desired
  outputs using a real example before designing the screen.
- Reuse established bender data and trusted bending helpers; do not duplicate
  or speculatively change formulas.

## 4. Material

- Build everyday job material lists with as few taps and as little typing as
  possible. Working page title: Material.
- Quick selection flow: item/category (for example, connectors) → applicable
  type (EMT, Romex/NM cable, etc.) → size/details where needed → quantity → add.
  Use dependent choices so users do not have to search through irrelevant types.
- Let users quickly review the list and adjust quantities or add new items as
  material needs change throughout the job.
- Save named lists persistently, reopen them later and keep adding/editing;
  lists should survive closing the app.
- Convert a list quickly into readable plain text for copying or sharing in a
  text message, such as sending today's material needs to a supervisor.
- Also offer a legible image of the list for sharing through messaging apps;
  account for long lists so items are not clipped or reduced to unreadable text.
- User chooses the recipient and sends through the phone's sharing/messaging
  flow; creating a list does not automatically send it to anyone.
- Before implementation, agree the starter item catalog, units, list naming and
  fastest entry flow. Favorites, recent items and reusable lists are options to
  evaluate for speed, not finalized requirements.

## Later releases, paid add-ons and announcements

- Explore optional one-time feature unlocks for major new tools, possibly a
  Lighting Layout pack and an Underground pack. Names, grouping and prices TBD.
- Keep existing purchased functionality available; decide paid versus included
  features explicitly. No subscription or payment implementation authorized yet.
- Plan purchase restoration, entitlement validation, refunds, offline behavior
  and whether Apple/Google purchases should transfer across platforms.
- Build and test each update, increase its version/build number, submit it through
  the stores and supply release notes. Recheck store rules at implementation time.
- Consider an in-app What's New page, website announcements, YouTube demos and
  an optional email signup. Push announcements would need separate implementation
  and user consent. Do not assume stores supply a customer email mailing list.
- Website integration/history needs review once the exact URL or project is
  supplied. User recalls a previously built Pipe & Wire website; URL unconfirmed.
