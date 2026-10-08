# Code reference: first-release content review

Keep the existing eight categories and question-and-answer cards. Add specific
topics within those categories, not more top-level categories. Review one page
at a time with the user: concrete question, direct answer, useful exceptions,
and accurate section references. Do not merely rename generic text as questions.

## Completed content edits — 2026-10-03

2026-10-04 follow-up:
- [x] Rigid: add a collapsed concrete-to-soil corrosion field tip. Use generic
  PVC/vinyl corrosion-protection wrapping tape, 10 mil thick, without a brand;
  retain suitability and product preparation/primer/wrapping instructions.
  Distinguish the industry 4 in. recommendation from NEC requirements. Sources:
  Steel Tube Institute corrosion guidance and 3M Scotchrap 50/51 technical data
  reviewed in conversation; example thickness is not a universal specification.
- [x] Rigid: combine bushing/material/hub/EMT comparison into one question.
  Verify ordinary support distances, the structural 5 ft allowance (no EMT-style
  unbroken-length condition), and longer straight-run spans with threaded
  couplings and supports that prevent deflection stresses at terminations.
  Checked official 2023 NEC 344.30(A)(1–2), (B)(1–2), Table 344.30(B), and 344.46,
  printed pages 70–233/234. No support-planning calculations changed.

- [x] EMT: add concise direct-burial and concrete questions. Distinguish fittings
  identified for direct burial, concrete-tight fittings (including instructions
  for taping), and wet-location suitability. Retain short steel-EMT corrosion
  conditions; fittings alone do not make the installation suitable. Corrosion
  guidance checked against Steel Tube Institute's “Steel Conduit Tech Talk:
  Corrosion Protection” and official 2023 NEC 358.10/42 and 300.6 references.

- [x] Shared Code topic layout: make the opening question a collapsed card with
  the same text size and styling as the other questions. Keep its answer and
  core rules inside that card. Remove the non-interactive Details / Tap to expand
  heading. This applies to all pages using CodeTopicScreen; manual review pending.

- [x] Raceways → Strapping & Support: replace vague distances and internal app
  filler with ordinary support distances, EMT coupling clarification, the
  unbroken-length 5 ft exception, selected FMC/LFMC exceptions, and a run example.
- [x] Raceways → EMT: add bushing/conductor-size questions, 2023 entry-protection
  alternatives, compression versus wet-location suitability, and support FAQs.
- [x] Raceways → Rigid Metal Conduit: add bushing/equivalent protection,
  metal versus insulating protection, hub, and ordinary support questions.
- [ ] User walkthrough of these three pages on Android/iPhone: opening questions,
  expandable answers, readable references, scrolling, and back navigation.

Sources checked: official NFPA 70 (2023), 300.4(G), 314.15, 342.30/46,
344.30/46, 348.30, 350.30, 358.30/42. McGraw-Hill's NEC 2020 Handbook,
pages 705–708, explains the older coupling wording and fitting/bushing confusion.
Use the handbook as commentary; do not blend its edition with 2023 requirements.
Wet-location fitting markings/instructions also checked against Steel Tube
Institute's “Fittings for Use with RMC, IMC and EMT.” No handbook diagrams copied.

- https://link.nfpa.org/free-access/publications/70/2023
- https://steeltubeinstitute.org/resources/fittings-for-use-with-rmc-imc-and-emt/

## Review queue (existing live pages; not yet source-audited)

2026-10-05: Burial Depth replaced with an always-visible, horizontally scrollable
portrait table for ordinary ground, qualifying dwelling driveways, and other
driveways/parking. Concrete and emerging-from-grade answers stay collapsed below.
Verified against official 2023 Table 300.5(A), including note 4 for qualifying
circuits using RMC/IMC. Clear cover measurement and residential GFCI conditions.
User phone walkthrough pending; adjust table styling based on feedback.

Follow-up: the cover table now starts collapsed in the same question-card
style as the other answers. Tap its heading to expand/collapse; horizontal
scrolling and all table notes remain available inside.

Added a collapsed Common practice transition-protection card after reading
McGraw-Hill NEC 2020 Handbook pp. 673–675, Fig. 344-1: concrete-to-soil,
concrete-to-air, and soil-to-air junctions. Protective coating/wrap where needed;
the book does not mandate generic 10 mil tape. Keep the generic tape example
and product instructions already approved by the user. The 4 in. each-side
recommendation is industry guidance for concrete-to-soil, not all transitions.

2026-10-05: Conduit & Tubing Fill retained at the user's request, with a brief
Fill vs derating note explaining larger conductors increase fill, splitting
circuits can reduce CCC per raceway, and larger conduit alone generally does
not remove derating. Both existing calculator/derating links retained.

Next: Grounding & Bonding — Neutral-Ground Bond.

User simplification: replaced the NM stud-hole/bundling card with a short
24 in. or less nipple question. Explain no conductor-count adjustment and
60% fill between enclosures, excluding connectors from nipple length;
retain temperature/terminal limits and longer-run checks. Removed the opening
nipple bullet to avoid repetition. NM sealed-hole topic deferred from release.
Added Chapter 9 Table 1 Note 4 reference; other content/links unchanged.

Conduit Fill wording follow-up: replaced the generic Fill vs derating bullets
with the approved #10 copper THHN/THWN-2 example at 78–86°F: 40A starting,
4–6 CCC = 32A, 7–9 = 28A, 10–20 = 20A. Explain splitting circuits or upsizing
and rechecking fill; use “A larger conduit alone does not change the derating
factor.” Added Table 310.16 reference. Calculator logic and both links unchanged.

Conduit Fill follow-up: consolidated into three collapsed cards (percentages,
EMT/rigid conductor-count chart, fill vs derating). Added a horizontally
scrollable chart for 1/2–2 in. conduit and #12/#10/#8 standard copper
THHN/THWN-2, with total-conductor and ampacity reminders. Retained both links.
EMT counts checked directly against 2023 Table C.1, printed p. 70–775.
Rigid counts cross-checked with Spike Electric Controls' published fill chart;
2023 Table C.9 THHN row direct comparison pending (viewer stopped loading
after the first C.9 page). Manual phone appearance review pending.
Source: https://spikeelectric.com/wp-content/uploads/2020/04/Conduit-Fill-Table.pdf

- [x] Raceways: Burial Depth content/table implemented; manual appearance review pending.
- [x] Raceways: Conduit & Tubing Fill brief derating note approved and added;
  existing content and both links retained.
- [x] Conductors & Ampacity: Derating; Neutral as CCC content revised.
  Derating now has five collapsed cards: triggers, adjustment-factor table with
  the approved #10 example, temperature correction, 90°C/terminal limits, and
  NM cable sealed-opening/thermal-insulation exceptions. Neutral page now has
  four distinct circuit cases; removed blanket nonlinear/MWBC claims and the
  requirement for perfectly balanced loads. Added missing two-phase wye case.
  125% remains under Loads, with a link from Derating; category subtitle updated.
  Manual phone review pending. Calculator/bending formulas unchanged.
  Sources compared: Mike Holt's “Conductors, based on the 2023 NEC”; Southwire
  ampacity/temperature tables and NM example; NFPA CMP-6 334.80 baseline text
  in the 2024 meeting materials (not proposed new subdivisions). Direct 2023
  viewer recheck pending acceptance of its access terms.
  https://www.mikeholt.com/newsletters.php?action=reply&inResponseTo=24701&letterID=2918
  https://docinfofiles.nfpa.org/files/AboutTheCodes/70/70_A2025_NEC_P06_FD_MeetingAgenda_0124.pdf
- [x] Boxes & Enclosures: Box Fill content revised into five question cards.
  Per-wire sizes, pigtails/pass-through/long loops, device-yoke size basis,
  collective internal-clamp allowance, studs/hickeys, terminal block assemblies,
  entering-ground counts, wire-volume table, and an 18 cu in. worked example.
  Retained calculator link; focused Dart analysis passed. Manual review pending.
- [x] Boxes & Enclosures: Junction/Pull Box Sizing targeted edits approved.
  Added 3 in. + 2 in. angle-pull row example (20 in.), row-by-row checks,
  and separate 6× nearest-edge entry spacing for angle/U-pulls. Replaced the
  generic rationale card; tightened #4 insulated-conductor entry protection
  and linked EMT/rigid answers. Existing calculator link retained.
  Source compared: Mike Holt Box Sizing newsletter, letterID=1478.
  Manual phone review pending; no calculator formulas changed.
- [x] Boxes & Enclosures: Box Support revised into five collapsed questions: basic mounting, conduit-supported junction boxes, boxes with devices/supported equipment, conduit-body exceptions, and suspended-ceiling mounting. Removed repeated reminders; retained 100 cu in., 3 ft / 18 in. limits and specific 2023 exceptions. Source: Seattle SDCI 2023 Electrical Code Quick Reference, Article 314.23 (ordinary NEC support provisions). Manual phone review pending; calculator formulas unchanged.
- [x] Equipment & Installation: Working Clearances content/chart implemented; manual phone review pending.
- [x] Equipment & Installation: Disconnects revised into seven collapsed equipment-specific questions; manual phone review pending.
- [x] Equipment & Installation: Panelboards revised into six concise Q&A cards; manual phone review pending.
- [x] Grounding & Bonding: Quick Reference; Neutral-Ground Bond; GEC; Equipment Bonding; Sizing content revised. Manual review and direct viewer rechecks pending.
- [x] Loads: Continuous Load; Branch Circuit Load Basics content revised; manual review pending.
- [x] Voltage Drop Basics content revised; calculator link retained; manual review pending.
- [x] Motor Calculations content revised into shared Q&A cards; manual review pending.

Inventory follows routes in `lib/code_screen.dart`. Duplicate “(1)” files and
unlinked quick sheets are not additional main-menu topics; do not delete them
as part of this content review. Bending formulas unchanged.


2026-10-05: Working Clearances revised into five collapsed questions with a compact horizontally scrollable 2023 depth chart (0–150, 151–600, 601–1000 volts to ground). Corrected Condition 2, greater-of width/headroom, dedicated footprint/lower-of height, and foreign-system leak protection above the zone. Added 120/240V and 480Y/277V examples. Source checks: NFPA Table 110.26(A)(1) baseline; Mike Holt 2023 Article 110 sample pp. 38–47; Seattle SDCI 2023 Article 110.26. Manual phone review pending. Next: Disconnects and Panelboards.

2026-10-06: Disconnects: within-sight definition with distance/visibility examples; motor/controller locations and limited remote exceptions; A/C accessibility, nameplate/access-panel restrictions and working-space link; transformer remote locking/marking; appliance breaker and plug options; feeder-panel protection versus building/emergency disconnects; installed locking provision and identification. References listed by equipment type. Sources: Mike Holt 2023 A/C, Panelboards, Services and 225.41 material; NFPA 430.102/422.31 baseline text in cycle reports (not proposed additions); transformer 450.14 guidance and 2020 lockable-open clarification. No calculator/bending changes. User content/appearance review pending.

2026-10-06 Disconnect follow-up: replaced the vague panel closing sentence with specific 225.41/230.85 routing. Added a collapsed overhead-house-service flow diagram: pole/drop -> weatherhead/service entrance -> meter -> outdoor main serving as emergency + service disconnect -> feeder -> indoor panel/branch circuits. Explain typical meter-first layout versus utility/listed arrangements, 230.85(B) alternatives and NOT SERVICE EQUIPMENT distinction. Source: Eaton 2023 Emergency Disconnect guide and Mike Holt 2023 Services. Focused Dart analysis passed; user phone diagram walkthrough pending.

2026-10-06: Panelboards retained practical identification, protection, and neutral/ground topics; removed repeated filler. Added 100A protection example, 6 ft 7 in. handle height, specific prohibited locations versus weatherproof damp/wet installations, source labeling, breaker compatibility/double-tap rules, backfed retention and opening closures. Specific references and Working Clearances/Disconnects links included. Sources: Mike Holt 2023 Panelboards and Overcurrent Protection; UL circuit-breaker/panelboard application guides. Focused Dart analysis passed. No calculation changes.

2026-10-06 Panelboards scope follow-up: user removed breaker compatibility/double-tapping and backfed/empty-opening cards. Page now has four questions. Replaced terminal-sharing discussion with service versus feeder-panel neutral/ground separation, main bonding jumper definition/purpose, outdoor-main example, and emergency-only/SDS distinctions. Corrected references to 2023 250.24(B) load-side prohibition and 250.24(C) main bonding jumper (older editions used different numbering). Source: NFPA CMP-5 edition-numbering explanation and Mike Holt Grounding of Services (2023).

2026-10-06: Neutral-Ground Bond revised into four collapsed questions: actual
service disconnect versus emergency-only disconnect; feeder-panel isolation;
main versus system bonding jumpers; EGC versus GEC. Removed blanket first-switch
and once-per-system claims. Qualified the indoor-transformer example and retained
the outdoor-transformer exception without expanding into a full SDS guide.
2023 references: 250.24(B)/(C), 250.28, 230.85(B), 250.30(A)(1)/(5),
250.4(A), 250.6(A), 250.50, 250.118. Sources compared: Mike Holt original
2023 Grounding of Services and Grounding of Separately Derived Systems articles;
NFPA CMP-5 edition-numbering explanation. Direct NFPA viewer recheck remains pending.
Replaced the old quick-sheet link with the existing GEC and EGC topic links;
preserved the quick-sheet file, which still needs an audit before relinking.
Manual phone review pending. No calculator/bending formulas changed.
Next: Grounding Electrode Conductor (GEC).
https://www.mikeholt.com/newsletters.php?action=display&letterID=2959
https://www.mikeholt.com/newsletters.php?action=display&letterID=2969

2026-10-06: GEC revised into five collapsed questions: permitted service/SDS
connection points, electrodes present versus rods alone, conductor-based sizing,
#6/#4/ring allowances, and new separate-building feeders. Corrected maximum-size
language to not-required-to-exceed allowances with sole-connection conditions;
retained Table 250.66 basis for smaller sizes and water-pipe electrodes. Added
specific references and bond-location link. Sources: Mike Holt 2023 Services/SDS;
NFPA CMP-5 reports for 250.50 and 250.66 baseline text (not proposed additions).
Direct NFPA viewer recheck and manual phone appearance review pending.
No calculation changes. Next: Equipment Bonding & EGC.

2026-10-06: Promoted Grounding & Bonding Quick Reference to the first main
subtopic, followed by the four existing topics. Replaced its duplicate tables,
five-question presentation, blanket one-bond claims, and branch links with five
always-visible conductor/jumper summaries. Removed Sizing -> Quick Sheet link,
so the former Sizing/Quick Sheet navigation loop is gone.
Corrected Sizing: 20A copper EGC is #12, not #14; copper service #1/1/0 requires
#6 GEC, 2/0/3/0 requires #4. Restored exact table range boundaries and the
largest row; marked both charts copper-only. Added next-row example and voltage-
drop upsizing qualification, electrode-only allowances, and metal-raceway limits.
Sources: 2023 NFPA Table 250.66 baseline in CMP-5 PI responses; 2023 service/SDS
Mike Holt articles; Electrical Association authored 2023 grounding training,
Table 250.122 and 250.122(B) examples; NFPA 250.122(B) baseline (exclude proposed
voltage-drop wording). Direct viewer recheck/manual phone review pending.
Next: Equipment Bonding & EGC. No calculation formulas changed.

2026-10-06: Equipment Bonding & EGC revised into five collapsed practical
questions: fault path, EMT/IMC/RMC, conditional FMC/LFMC permission, service
versus >250V-to-ground entry bonding, and box grounding continuity. Removed
vague large-feeder trigger and wire-only EGC definition. Sources: Mike Holt
2023 250.118 PDF, UL knockout bonding guidance, NFPA 250.148 baseline, and
Electrical Association authored 2023 250.92 training. No calculator changes.
Quick Reference follow-up: user requested replacing the emergency-disconnect
reminder with a short explanation of bonding fault paths versus earth grounding.
Manual phone review/direct NFPA viewer recheck pending. Next: Loads — Continuous
Load (125% Rule); grounding sizing already corrected in preceding task.

2026-10-06: User authorized an autonomous sweep of the four remaining pages.
- Continuous Load: maximum-current 3-hour definition, mixed-load arithmetic,
  compact 80% limits, separate pre/post correction conductor checks, and listed
  100%-rated assembly exception. Removed repeated blanket continuous-load claims.
- Branch Circuit Load Basics: VA/nameplate current, shared 15A/20A portable and
  fixed-load limits, duplex versus individual receptacle ratings, ordinary copper
  small-conductor protection limits. Direct link to Continuous Load; no link loop.
- Voltage Drop: general informational recommendations versus mandatory rules,
  3.6V example, combined 5% budget, one-way length, actual current versus Auto
  breaker-size estimate, starting-current caution and wire EGC upsizing.
  Inspected existing calculator formula: phase multiplier 2 or 1.732; Auto uses
  finalBreakerSize. No calculator changes.
- Motor Calculations: replaced standalone layout with five shared question cards.
  Scoped ordinary induction motor >1 hp, table versus nameplate with exceptions,
  conductor and overload examples, inverse-time breaker/time-delay fuse maximums,
  motor-only protection coordination. Corrected 2023 Table 430.52(C)(1) and
  430.52(C)(1)(a)/(b) references; old Exception No. 1 wording removed.

Sources compared: Mike Holt authored Branch Circuits based on the 2023 NEC;
Eaton/Bussmann 2023 NEC code-change guide p. 40 (Table 430.52(C)(1), revised
standard-rating/starting rules); Electrical Association authored 2023 Code
Highlights (motor overloads); NFPA CMP baseline text and explanations for
210.19/20, 210.21/23, 215.2/3, Continuous Load, and motor requirements. Proposed
future additions are not treated as 2023 rules. Direct NFPA viewer rechecks remain
pending, as recorded for preceding pages. No copyrighted diagrams reproduced.
https://www.mikeholt.com/newsletters.php?action=display&letterID=2881
https://www.eaton.com/content/dam/eaton/products/electrical-circuit-protection/fuses/code-updates/bus-ele-br-11318-2023-NEC-code-changes.pdf
https://www.electricalassociation.com/common/Uploaded%20files/PowerPoints/Powerpoint%20-%202023%20NEC%20Code%20Highlights%20Part%201%20-%20Final.pdf

Validation: focused Dart analysis of all four revised pages passed. User will
perform manual phone walkthroughs; no full build or visual acceptance claimed.
First-release content sweep is implemented. Remaining review work: manual phone
readability/navigation, direct 2023 viewer rechecks, and earlier Table C.9 count
comparison. Broader app work can now resume from TODO.md / COMPATIBILITY_TODO.md.