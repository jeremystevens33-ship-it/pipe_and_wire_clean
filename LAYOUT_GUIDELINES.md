# Phone layout direction

User direction, October 10, 2026: design new screens for a compact phone first,
then let the layout grow naturally on larger phones while preserving the app's
stacked-card style. Apply this to Job Board and future screens.

- Use the available viewport constraints, rather than a particular phone model
  or physical pixel count, to choose sizes and spacing.
- Keep vertical scaling bounded. Larger screens can gain modest spacing and
  roomier content; avoid scaling every row, icon and font by screen height.
- For expanding lists such as Job Board, let content determine card height and
  scroll the page as needed. Do not squeeze an expanded job into a fixed-height
  screen or clamp away its content.
- Preserve comfortable touch targets and readable type on small phones. Let
  long titles and larger system text wrap and increase row height when needed.
- Let buttons and choice chips wrap to additional rows when width is limited.
  Dialogs must fit the available width, scroll when needed, and remain usable
  with the keyboard open.
- Respect notches, system bars and bottom safe areas. Keep final list items
  reachable above the instruction bar and keyboard.
- On larger phones, use the extra width without oversized controls. For much
  wider views, constrain and center reading/form content when appropriate.
- Before calling a new screen broadly verified, check compact and large phone
  sizes, a short/landscape viewport, increased system text size, long content,
  and keyboard-open entry. Suggested logical-pixel viewports include 320×568,
  360×640 and 430×932; these are test cases, not supported-device guarantees.

Current Job Board uses a vertical ListView, wrapping material choices and
scrollable entry dialogs. Existing focused tests exercise workflows at 360×800.
That does not yet verify the full range above or physical iPhone behavior.
